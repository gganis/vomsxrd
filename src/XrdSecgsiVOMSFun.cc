/******************************************************************************/
/*                                                                            */
/*                X r d S e c g s i V O M S F u n . c c                       */
/*                                                                            */
/* (c) 2012, G. Ganis / CERN                                                  */
/*                                                                            */
/* This file is part of the XRootD software suite.                            */
/*                                                                            */
/* XRootD is free software: you can redistribute it and/or modify it under    */
/* the terms of the GNU Lesser General Public License as published by the     */
/* Free Software Foundation, either version 3 of the License, or (at your     */
/* option) any later version.                                                 */
/*                                                                            */
/* XRootD is distributed in the hope that it will be useful, but WITHOUT      */
/* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or      */
/* FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public       */
/* License for more details.                                                  */
/*                                                                            */
/* You should have received a copy of the GNU Lesser General Public License   */
/* along with XRootD in a file called COPYING.LESSER (LGPL license) and file  */
/* COPYING (GPL license).  If not, see <http://www.gnu.org/licenses/>.        */
/*                                                                            */
/* The copyright holder's institutional names and contributor's names may not */
/* be used to endorse or promote products derived from this software without  */
/* specific prior written permission of the institution or contributor.       */
/*                                                                            */
/******************************************************************************/

/******************************************************************************/
/*                                                                            */
/*  See README.VOMS for hints about usage of this library                     */
/*                                                                            */
/******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "XrdSecgsi/XrdSecgsiVOMS.hh"

#include "XrdCrypto/XrdCryptosslAux.hh"
#include "XrdCrypto/XrdCryptosslgsiAux.hh"
#include "XrdCrypto/XrdCryptoX509.hh"
#include "XrdCrypto/XrdCryptoX509Chain.hh"
#include "XrdOuc/XrdOucHash.hh"
#include "XrdOuc/XrdOucString.hh"
#include "XrdSec/XrdSecEntity.hh"
#include "XrdSecgsi/XrdSecgsiTrace.hh"
#include "XrdSut/XrdSutBucket.hh"

extern XrdOucTrace *gsiTrace;

#ifndef SafeFree
#define SafeFree(x) { if (x) free(x) ; x = 0; }
#endif

//
// These settings are configurable
static int gCertFmt = 0;                       //  certfmt:raw|pem [raw]
static int gGrpSel = 0;                        //  grpopt's sel = 0|1 [0]
static int gGrpWhich = 1;                      //  grpopt's which = 0|1 [1]
static XrdOucHash<int> gGrps;                  //  hash table with grps=grp1[,grp2,...]
static XrdOucHash<int> gVOs;                   //  hash table with vos=vo1[,vo2,...]
static bool gDebug = 0;                        //  Verbosity control
static XrdOucString gRequire;                   //  String with configuration options

#define VOMSDBG(m) \
   if (gDebug) { \
      PRINT(m); \
   } else { \
      DEBUG(m); \
   }
#define VOMSDBGSUBJ(m, c) \
   if (gDebug) { \
      XrdOucString subject; \
      XrdCryptosslNameOneLine(X509_get_subject_name(c), subject); \
      PRINT(m << subject); \
   }

//
// Main function
//
extern "C"
{
int XrdSecgsiVOMSFun(XrdSecEntity &ent)
{
   // Implementation of XrdSecgsiAuthzFun extracting the information from the 
   // proxy chain in entity.creds
   EPNAME("VOMSFun");

   vomsdata v;
   X509 *pxy = 0;
   STACK_OF(X509) *stk = 0;
   bool freestk = 1;
   
   if (gCertFmt == 0) {
      //
      // RAW format
      //
      XrdCryptoX509Chain *c = (XrdCryptoX509Chain *) ent.creds;
      if (!c) {
         PRINT("ERROR: no proxy chain found!");
         return -1;
      }

      XrdCryptoX509 *xp = c->End();
      if (!xp) {
         PRINT("ERROR: no proxy certificate in chain!");
         return -1;
      }
      pxy = (X509 *) xp->Opaque();
      VOMSDBGSUBJ("proxy: ", pxy)

      stk =sk_X509_new_null();
      XrdCryptoX509 *xxp = c->Begin();
      while (xxp) {
         if (xxp == c->End()) break;
         if (xxp->type != XrdCryptoX509::kCA) {
            VOMSDBGSUBJ("adding cert: ", (X509 *) xxp->Opaque())
            sk_X509_push(stk, (X509 *) xxp->Opaque());
         }
         xxp = c->Next();
      }
   } else if (gCertFmt == 1) {
      //
      // PEM format
      //
      // Create a bio_mem to store the certificates
      BIO *bmem = BIO_new(BIO_s_mem());
      if (!bmem) {
         PRINT("unable to create BIO for memory operations");
         return -1; 
      }

      // Write data to BIO
      int nw = BIO_write(bmem, (const void *)(ent.creds), ent.credslen);
      if (nw != ent.credslen) {
         PRINT("problems writing data to memory BIO (nw: "<<nw<<")");
         return -1; 
      }

      // Get certificate from BIO
      if (!(pxy = PEM_read_bio_X509(bmem,0,0,0))) {
         PRINT("unable to read certificate to memory BIO");
         return -1;
      }
      VOMSDBGSUBJ("proxy: ", pxy)
      //
      // The chain now
      X509 *xc = 0;
      stk =sk_X509_new_null();
      while ((xc =  PEM_read_bio_X509(bmem,0,0,0))) {
         VOMSDBGSUBJ("adding cert: ", xc)
         sk_X509_push(stk, xc);
      }
      //
      // Free BIO
      BIO_free(bmem);

   } else {
      //
      // STACK_OF(X509) format
      //
      gsiVOMS_x509_in_t *voms_in = (gsiVOMS_x509_in_t *) ent.creds;
      pxy = voms_in->cert;
      stk = voms_in->chain;
      freestk = 0;
   }

   bool extfound = 0;
   XrdOucString endor, grps, role, vo;
   if (v.Retrieve(pxy, stk, RECURSE_CHAIN)) {
      VOMSDBG("retrieval successful");
      extfound = 1;
      std::vector<voms>::iterator i = v.data.begin();
      for ( ; i != v.data.end(); i++) {
         vo = (*i).voname.c_str();
         VOMSDBG("found VO: " << vo);
         // Filter the VO?
         if (gVOs.Num() > 0 && !gVOs.Find(vo.c_str())) continue;
         // (*i) is voms
         std::vector<data> dat = (*i).std;
         std::vector<data>::iterator idat = dat.begin();
         grps = ""; role = "";
         for (; idat != dat.end(); idat ++) {
            VOMSDBG(" ---> group: '"<<(*idat).group<<"', role: '"<<(*idat).role<<"', cap: '" <<(*idat).cap<<"'");
            if (endor.length() > 0) endor += ",";
            bool fillgrp = 1;
            if (gGrpSel == 1 && !gGrps.Find((*idat).group.c_str())) fillgrp = 0;
            if (fillgrp) {
               grps = (*idat).group.c_str();
               role = (*idat).role.c_str();
            }
            // If we are asked to take the first we break
            if (gGrpWhich == 0 && grps.length() > 0) break;            
         }
         if (grps.length() > 0) {
            std::vector<std::string> fqa = (*i).fqan;
            std::vector<std::string>::iterator ifqa = fqa.begin();
            for (; ifqa != fqa.end(); ifqa ++) {
               VOMSDBG(" ---> fqan: '"<<(*ifqa)<<"'");
               if (endor.length() > 0) endor += ",";
               endor += (*ifqa).c_str();
            }
         } else {
            // Reset also the other fields
            role = "";
            vo = "";
            endor = "";
         }
      }
      // Save the VO
      SafeFree(ent.vorg);
      SafeFree(ent.grps);
      SafeFree(ent.role);
      SafeFree(ent.endorsements);
      if (vo.length() > 0 && grps.length() > 0) {
         ent.vorg = strdup(vo.c_str());
         // Save the groups
         ent.grps = strdup(grps.c_str());
         if (role.length() > 0) ent.role = strdup(role.c_str());
         // Save the whole string in endorsements
         if (endor.length() > 0) ent.endorsements = strdup(endor.c_str());
      } else if (extfound) {
         VOMSDBG("VOMS extensions do not match required criteria ("<<gRequire<<")");
      }
   } else {
      PRINT("retrieval FAILED: "<< v.ErrorMessage());
   }

   // Free memory taken by the chain, if required
   if (stk && freestk) {
      while (sk_X509_pop(stk)) { }
      sk_X509_free(stk);
   }
   
   // Done
   return (!ent.vorg ? -1 : 0);
}}

//
// Init the relevant parameters from a dedicated config file
//
extern "C"
{
int XrdSecgsiVOMSInit(const char *cfg)
{
   // Initialize the relevant parameters from the 'cfg' string.
   // Return -1 on failure.
   // Otherwise, the return code indicates the format required by the main function
   // defined by 'certfmt' below.
   //
   // Supported options:
   //         certfmt=raw|pem|x509   Certificate format:  [raw]
   //                                  raw   to be used with XrdCrypto tools
   //                                  pem   PEM base64 format (as in cert files)
   //                                  x509  As a STACK_OF(X509)
   //         grpopt=opt               What to do with the group names:  [1]
   //                                    opt = sel * 10 + which
   //                                  with 'sel'
   //                                    0    consider all those present
   //                                    1    select among those specified by 'grps' (see below)
   //                                  and 'which'
   //                                    0    take the first one
   //                                    1    take the last
   //         grps=grp1[,grp2,...]   Group(s) for which the information is extracted; if specified
   //                                the grpopt 'sel' is set to 1 regardless of the setting.
   //         vos=vo1[,vo2,...]      VOs to be considered; the first match is taken
   //         dbg                    To force verbose mode
   //
   EPNAME("VOMSInit");

   XrdOucString oos(cfg);

   XrdOucString grps, gr, voss, vo;
   if (oos.length() > 0) {

      // Certificate format
      int ifmt = oos.find("certfmt=");
      if (ifmt != STR_NPOS) {
         XrdOucString fmt(oos, ifmt + strlen("certfmt="));
         fmt.erase(fmt.find(' '));
         if (fmt == "raw") {
            gCertFmt = 0;
         } else if (fmt == "pem") {
            gCertFmt = 1;
         } else if (fmt == "x509") {
            gCertFmt = 2;
         }
      }

      // Group option
      int igo = oos.find("grpopt=");
      if (igo != STR_NPOS) {
         XrdOucString go(oos, igo + strlen("grpopt="));
         go.erase(go.find(' '));
         if (go.isdigit()) {
            int grpopt = go.atoi();
            gGrpSel = grpopt / 10;
            if (gGrpSel != 0 && gGrpSel != 1) {
               gGrpSel = 0;
               PRINT("WARNING: grpopt sel must be in [0,1] - ignoring");
            }
            gGrpWhich = grpopt % 10;
            if (gGrpWhich != 0 && gGrpWhich != 1) {
               gGrpWhich = 1;
               PRINT("WARNING: grpopt which must be in [0,1] - ignoring");
            }
         } else {
            PRINT("WARNING: you must pass a digit to grpopt: "<<go);
         }
         gRequire = "grpopt=";
         gRequire += go;
      }

      // Groups selection
      int igr = oos.find("grps=");
      if (igr != STR_NPOS) {
         grps.assign(oos, igr + strlen("grps="));
         grps.erase(grps.find(' '));
         if (grps.length() > 0) {
            int from = 0, flag = 1;
            while ((from = grps.tokenize(gr, from, ',')) != -1) {
               // Analyse tok
               gGrps.Add(gr.c_str(), &flag);
               gGrpSel = 1;
            }
            if (gRequire.length() > 0) gRequire += ";grps=";
            gRequire += grps;
         }
      }

      // VO selection
      int ivo = oos.find("vos=");
      if (ivo != STR_NPOS) {
         voss.assign(oos, ivo + strlen("vos="));
         voss.erase(voss.find(' '));
         if (voss.length() > 0) {
            int from = 0, flag = 1;
            while ((from = voss.tokenize(vo, from, ',')) != -1) {
               // Analyse tok
               gVOs.Add(vo.c_str(), &flag);
            }
            if (gRequire.length() > 0) gRequire += ";vos=";
            gRequire += voss;
         }
      }

      // Verbose mode
      if (oos.find("dbg") != STR_NPOS) gDebug = 1;
   }
      
   // Notify
   const char *cfmt[3] = { "raw", "pem base64", "STACK_OF(X509)" };
   const char *cgrs[2] = { "all", "specified group(s)"};
   const char *cgrw[2] = { "first", "last" };
   PRINT("++++++++++++++++++ VOMS plugi-in ++++++++++++++++++++++++++++++");
   PRINT("+++ proxy fmt:    "<< cfmt[gCertFmt]);
   PRINT("+++ group option: "<<cgrw[gGrpWhich]<<" of "<<cgrs[gGrpSel]);
   if (gGrpSel == 1) {
      if (grps.length() > 0) {
         PRINT("+++ group(s):     "<< grps);
      } else {
         PRINT("+++ group(s):      <not specified>");
      }
   }
   if (voss.length() > 0) PRINT("+++ VO(s):        "<< voss);
   PRINT("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
   // Done
   return gCertFmt;
}}
