
  voms: VOMS attributes extraction plug-in for SCALLA/XROOTD
  ==========================================================


  This repository contains the source code for a SCALLA/XROOTD plug-in to extract
  the VOMS attributes. The plug-in is primarily intented for usage in conjuction
  with the XrdSecProtocolgsi authentication plug-in. It can, however, be used in
  others XROOTD plug-ins.

  This plug-in uses the official VOMS client libraries. This dependency is the main
  reason why the plug-in is not distributed with the SCALLA/XROOTD main distribution
  stream-line.

  The plug-in source code is under 'src' and consists in two files: XrdSecgsiVOMSFun.cc
  and XrdSecgsiVOMS.hh; the header file contains the interface for standalone usage.  

  The plug-in name is libXrdSecgsiVOMS.so .

  
  1. Building and runtime configuration
     ----------------------------------
  
  The plug-in requires the library 
                                           libvomsapi.so
                                           
  which at CERN can be found under
  
       /afs/cern.ch/sw/lcg/external/Grid/voms/<version>/<arch-compiler>/lib

  *** THIS REFERS TO THE INTEGRATION IN THE XROOTD BUILD SYSTEM ***
  *** NEEDS UPDATE FOR STANDALONE ***
       
  In order to build the plugin the VOMS installation must be passed via the switch
  VOMS_ROOT_DIR, e.g.
  
       -DVOMS_ROOT_DIR=/afs/cern.ch/sw/lcg/external/Grid/voms/2.0.8-1/x86_64-slc6-gcc46-opt
       
  The cmake output should contain the line
  
  -- VOMS API support:  yes

  in the summary if everything is OK.

  *** END OF THE OBSOLETE PART ***

  
  At runtime the path with libvomsapi.so must be in the library search path, which must
  also contain the openssl libraries.
  Check with ldd that all dependencies are resolved:

  $ ldd /home/ganis/local/xrootd/install_cmake/lib/libXrdSecgsiVOMS.so
        linux-vdso.so.1 =>  (0x00007fffb76d9000)
        libXrdSecgsi.so.0 => /home/ganis/local/xrootd/install_cmake/lib/libXrdSecgsi.so.0 (0x00007f6de7784000)
        libXrdCryptossl.so.1 => /home/ganis/local/xrootd/install_cmake/lib/libXrdCryptossl.so.1 (0x00007f6de755a000)
        libXrdCrypto.so.0 => /home/ganis/local/xrootd/install_cmake/lib/libXrdCrypto.so.0 (0x00007f6de733f000)
        libXrdUtils.so.1 => /home/ganis/local/xrootd/install_cmake/lib/libXrdUtils.so.1 (0x00007f6de70d1000)
        libvomsapi.so.1 => /afs/cern.ch/sw/lcg/external/Grid/voms/2.0.8-1/x86_64-slc6-gcc46-opt/lib64/libvomsapi.so.1 (0x00007f6de6e6d000)
        libstdc++.so.6 => /usr/lib/x86_64-linux-gnu/libstdc++.so.6 (0x00007f6de6b55000)
        libgcc_s.so.1 => /lib/x86_64-linux-gnu/libgcc_s.so.1 (0x00007f6de693f000)
        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f6de657f000)
        libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007f6de6362000)
        libssl.so.1.0.0 => /opt/openssl/openssl-1.0.0j/lib/libssl.so.1.0.0 (0x00007f6de6106000)
        libcrypto.so.1.0.0 => /opt/openssl/openssl-1.0.0j/lib/libcrypto.so.1.0.0 (0x00007f6de5d4b000)
        libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007f6de5b47000)
        librt.so.1 => /lib/x86_64-linux-gnu/librt.so.1 (0x00007f6de593f000)
        libexpat.so.1 => /lib/x86_64-linux-gnu/libexpat.so.1 (0x00007f6de5714000)
        libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007f6de5418000)
        /lib64/ld-linux-x86-64.so.2 (0x00007f6de7bb7000)


   2. Configuration
      -------------
      
   The plug-in is enabled with the switch
   
              -vomsfun:/home/ganis/local/xrootd/install_cmake/lib/libXrdSecgsiVOMS.so

   defining the alternative function to be used for VOMS extraction.
   The plug-in is configured with the switch

              -vomsfunparms:<options>

   Supported options (to be separated by a '|'):
   
              certfmt={raw,pem,x509}   Certificate format:  [raw]
                                       raw   to be used with XrdCrypto tools
                                       pem   PEM base64 format (as in cert files)
                                       x509  As a STACK_OF(X509) (struct gsiVOMS_x509_in_t,
                                             see XrdSecgsiVOMS.hh).
              grpopt=opt               What to do with the group names:  [1]
                                           opt = sel * 10 + which
                                       with 'sel'
                                           0    consider all those present
                                           1    select among those specified by 'grps' (see below)
                                       and 'which'
                                           0    take the first one
                                           1    take the last
              grps=grp1[,grp2,...]     Group(s) for which the information is extracted; if specified
                                       the grpopt 'sel' is set to 1 regardless of the setting.
              vos=vo1[,vo2,...]        VOs to be considered; the first match is taken
              dbg                      To force verbose mode


    Example:
              -vomsfunparms:grpopt=0|grps=/atlas/it|certfmt=raw
              
              to pass the certificate in RAW mode, to extract information when the first group in /atlas/it .
 
 
   3. External usage
      --------------

   The header XrdSecgsiVOMS.hh contains the definition of the gsiVOMS_x509_in_t structure for usage
   in other plug-ins.
 
 -------------------------------------------------------------------------------------------------------------
 (GG, 6 Jan 2013). 


  