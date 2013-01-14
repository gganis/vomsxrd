
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

  In order to build the plugin the VOMS installation must be passed via the switch
  VOMS_ROOT_DIR, e.g.
  
       -DVOMS_ROOT_DIR=/afs/cern.ch/sw/lcg/external/Grid/voms/2.0.8-1/x86_64-slc6-gcc46-opt

  The other dependency is of course XRootD, which is defined by the switch XROOTD_ROOT_DIR, e.g.
  
       -DXROOTD_ROOT_DIR=/afs/cern.ch/sw/lcg/external/xrootd/3.2.7/x86_64-slc6-gcc46-opt
          
  The output of a successful run of cmake should look something like
  
-- The C compiler identification is GNU
-- The CXX compiler identification is GNU
-- Check for working C compiler: /usr/bin/gcc
-- Check for working C compiler: /usr/bin/gcc -- works
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Check for working CXX compiler: /usr/bin/c++
-- Check for working CXX compiler: /usr/bin/c++ -- works
-- Detecting CXX compiler ABI info
-- Detecting CXX compiler ABI info - done
-- Found VOMS: /afs/cern.ch/sw/lcg/external/Grid/voms/2.0.8-1/x86_64-slc6-gcc46-opt/lib64/libvomsapi.so 
-- Found XROOTD: /afs/cern.ch/sw/lcg/external/xrootd/3.2.7/x86_64-slc6-gcc46-opt/lib64/libXrdCryptossl.so 
-- ----------------------------------------
-- Installation path: /home/ganis/local/xrootd/voms/install
-- Build type:        RELEASE
-- ----------------------------------------
-- Configuring done
-- Generating done
-- Build files have been written to: /home/ganis/local/xrootd/voms/build
    
  
  At runtime the path with libvomsapi.so must be in the library search path, which must
  also contain the openssl libraries.
  Check with ldd that all dependencies are resolved:

 $ ldd /afs/cern.ch/user/g/ganis/work/public/vomsxrd/vomsxrd-0.0.1/slc6/lib64/libXrdSecgsiVOMS.so 
        linux-vdso.so.1 =>  (0x00007fff6532a000)
        /$LIB/snoopy.so => /lib64/snoopy.so (0x00007f6fb6bd4000)
        libXrdCryptossl.so.1 => /afs/cern.ch/sw/lcg/external/xrootd/3.2.7/x86_64-slc6-gcc46-opt/lib64/libXrdCryptossl.so.1 (0x00007f6fb69ab000)
        libvomsapi.so.1 => /afs/cern.ch/sw/lcg/external/Grid/voms/2.0.8-1/x86_64-slc6-gcc46-opt/lib64/libvomsapi.so.1 (0x00007f6fb6748000)
        libstdc++.so.6 => /afs/cern.ch/sw/lcg/contrib/gcc/4.6.3/x86_64-slc6/lib64/libstdc++.so.6 (0x00007f6fb6444000)
        libm.so.6 => /lib64/libm.so.6 (0x00007f6fb618d000)
        libgcc_s.so.1 => /afs/cern.ch/sw/lcg/contrib/gcc/4.6.3/x86_64-slc6/lib64/libgcc_s.so.1 (0x00007f6fb5f78000)
        libc.so.6 => /lib64/libc.so.6 (0x00007f6fb5be5000)
        libdl.so.2 => /lib64/libdl.so.2 (0x00007f6fb59e0000)
        libXrdCrypto.so.0 => /afs/cern.ch/sw/lcg/external/xrootd/3.2.7/x86_64-slc6-gcc46-opt/lib64/libXrdCrypto.so.0 (0x00007f6fb57c6000)
        libXrdUtils.so.1 => /afs/cern.ch/sw/lcg/external/xrootd/3.2.7/x86_64-slc6-gcc46-opt/lib64/libXrdUtils.so.1 (0x00007f6fb5563000)
        libpthread.so.0 => /lib64/libpthread.so.0 (0x00007f6fb5345000)
        libssl.so.10 => /usr/lib64/libssl.so.10 (0x00007f6fb50ea000)
        libcrypto.so.10 => /usr/lib64/libcrypto.so.10 (0x00007f6fb4d50000)
        libexpat.so.1 => /lib64/libexpat.so.1 (0x00007f6fb4b27000)
        /lib64/ld-linux-x86-64.so.2 (0x00007f6fb6fde000)
        librt.so.1 => /lib64/librt.so.1 (0x00007f6fb491f000)
        libgssapi_krb5.so.2 => /lib64/libgssapi_krb5.so.2 (0x00007f6fb46dc000)
        libkrb5.so.3 => /lib64/libkrb5.so.3 (0x00007f6fb43fd000)
        libcom_err.so.2 => /lib64/libcom_err.so.2 (0x00007f6fb41f9000)
        libk5crypto.so.3 => /lib64/libk5crypto.so.3 (0x00007f6fb3fcc000)
        libz.so.1 => /lib64/libz.so.1 (0x00007f6fb3db6000)
        libkrb5support.so.0 => /lib64/libkrb5support.so.0 (0x00007f6fb3bab000)
        libkeyutils.so.1 => /lib64/libkeyutils.so.1 (0x00007f6fb39a7000)
        libresolv.so.2 => /lib64/libresolv.so.2 (0x00007f6fb378d000)
        libselinux.so.1 => /lib64/libselinux.so.1 (0x00007f6fb356d000)

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
 (GG, 14 Jan 2013). 


  