#!/bin/bash
#-------------------------------------------------------------------------------
# Create a source RPM package
# Author: Lukasz Janyst <ljanyst@cern.ch> (10.03.2011)
# Adapted to VOMS xrd by Gerardo Ganis <gerardo.ganis@cern.ch> (March 2013)
#-------------------------------------------------------------------------------

RCEXP='^[0-9]+\.[0-9]+\.[0-9]+\-rc.*$'

#-------------------------------------------------------------------------------
# Find a program
#-------------------------------------------------------------------------------
function findProg()
{
  for prog in $@; do
    if test -x "`which $prog 2>/dev/null`"; then
      echo $prog
      break
    fi
  done
}

#-------------------------------------------------------------------------------
# Print help
#-------------------------------------------------------------------------------
function printHelp()
{
  echo "Usage:"                                              1>&2
  echo "${0} [--help] [--source PATH] [--output PATH] [--xrdvers VERSION]"       1>&2
  echo "  --help        prints this message"                 1>&2
  echo "  --rpmname NAME specify the RPM name: vomsxrd or vomsxrd-compat" 1>&2
  echo "                defaults to vomsxrd"                     1>&2
  echo "  --source PATH specify the root of the source tree" 1>&2
  echo "                defaults to ../"                     1>&2
  echo "  --output PATH the directory where the source rpm"  1>&2
  echo "                should be stored, defaulting to ."   1>&2
  echo "  --xrdsrc PATH specofy path to xrootd source tarball"  1>&2
  echo "                default none (XrdCrypto deps not built)"   1>&2
  echo "  --xrdvers VERSION the xrootd version against"      1>&2
  echo "                which we are build (e.g. v3.3.1);"   1>&2
  echo "                default none (XrdCrypto deps not built)"   1>&2
}

#-------------------------------------------------------------------------------
# Parse the commandline, if only we could use getopt... :(
#-------------------------------------------------------------------------------
RPMNAME="vomsxrd"
SOURCEPATH="../"
OUTPUTPATH="."
XRDSRCPATH=""
XRDVERS=""
PRINTHELP=0

while test ${#} -ne 0; do
  if test x${1} = x--help; then
    PRINTHELP=1
  elif test x${1} = x--rpmname; then
    if test ${#} -lt 2; then
      echo "--rpmname parameter needs an argument" 1>&2
      exit 1
    fi
    RPMNAME=${2}
    shift
  elif test x${1} = x--source; then
    if test ${#} -lt 2; then
      echo "--source parameter needs an argument" 1>&2
      exit 1
    fi
    SOURCEPATH=${2}
    shift
  elif test x${1} = x--output; then
    if test ${#} -lt 2; then
      echo "--output parameter needs an argument" 1>&2
      exit 1
    fi
    OUTPUTPATH=${2}
    shift
  elif test x${1} = x--xrdsrc; then
    if test ${#} -lt 2; then
      echo "--xrdsrc parameter needs an argument" 1>&2
      exit 1
    fi
    XRDSRCPATH=${2}
    shift
  elif test x${1} = x--xrdvers; then
    if test ${#} -lt 2; then
      echo "--xrdvers parameter needs an argument" 1>&2
      exit 1
    fi
    XRDVERS=${2}
    shift
  fi
  shift
done

if test $PRINTHELP -eq 1; then
  printHelp
  exit 0
fi

echo "[i] Creating source RPM for '$RPMNAME'"
echo "[i] Working on: $SOURCEPATH"
echo "[i] Storing the output to: $OUTPUTPATH"
if test ! "x$XRDSRCPATH" = "x" ; then
   echo "[i] Taking XRootD source from $XRDSRCPATH"
fi

#-------------------------------------------------------------------------------
# Check if the source and the output dirs
#-------------------------------------------------------------------------------
if test ! -d $SOURCEPATH -o ! -r $SOURCEPATH; then
  echo "[!] Source path does not exist or is not readable" 1>&2
  exit 2
fi

if test ! -d $OUTPUTPATH -o ! -w $OUTPUTPATH; then
  echo "[!] Output path does not exist or is not writeable" 1>&2
  exit 2
fi

#-------------------------------------------------------------------------------
# Check if we have all the necessary components
#-------------------------------------------------------------------------------
if test x`findProg rpmbuild` = x; then
  echo "[!] Unable to find rpmbuild, aborting..." 1>&2
  exit 1
fi

if test x`findProg git` = x; then
  echo "[!] Unable to find git, aborting..." 1>&2
  exit 1
fi

#-------------------------------------------------------------------------------
# Check if the source is a git repository
#-------------------------------------------------------------------------------
if test ! -d $SOURCEPATH/.git; then
  echo "[!] I can only work with a git repository" 1>&2
  exit 2
fi

#-------------------------------------------------------------------------------
# Check the version number
#-------------------------------------------------------------------------------
if test ! -x $SOURCEPATH/genversion.sh; then
  echo "[!] Unable to find the genversion script" 1>&2
  exit 3
fi

VERSION=`$SOURCEPATH/genversion.sh --print-only $SOURCEPATH 2>/dev/null`
if test $? -ne 0; then
  echo "[!] Unable to figure out the version number" 1>&2
  exit 4
fi

echo "[i] Working with version: $VERSION"

if test x${VERSION:0:1} = x"v"; then
  VERSION=${VERSION:1}
fi

XRDV4="no"
if test x${XRDVERS:0:2} = x"v4"; then
  XRDV4="yes"
fi

#-------------------------------------------------------------------------------
# Deal with release candidates
#-------------------------------------------------------------------------------
RELEASE=1
if test x`echo $VERSION | egrep $RCEXP` != x; then
  RELEASE=0.`echo $VERSION | sed 's/.*-rc/rc/'`
  VERSION=`echo $VERSION | sed 's/-rc.*//'`
fi

VERSION=`echo $VERSION | sed 's/-/./g'`
echo "[i] RPM compliant version: $VERSION-$RELEASE"

#-------------------------------------------------------------------------------
# Create a tempdir and copy the files there
#-------------------------------------------------------------------------------
# exit on any error
set -e

TEMPDIR=`mktemp -d /tmp/xrootd.srpm.XXXXXXXXXX`
RPMSOURCES=$TEMPDIR/rpmbuild/SOURCES
mkdir -p $RPMSOURCES
mkdir -p $TEMPDIR/rpmbuild/SRPMS

echo "[i] Working in: $TEMPDIR" 1>&2

if test -d rhel -a -r rhel; then
  for i in rhel/*; do
    cp $i $RPMSOURCES
  done
fi

if test -d common -a -r common; then
  for i in common/*; do
    cp $i $RPMSOURCES
  done
fi

#-------------------------------------------------------------------------------
# Make a tarball 
#-------------------------------------------------------------------------------
# no more exiting on error
set +e

CWD=$PWD
cd $SOURCEPATH

VXPREF="$RPMNAME"
VXTARGZ="$RPMNAME.tar.gz"

./packaging/maketar.sh --prefix $VXPREF --output $RPMSOURCES/$VXTARGZ

if test $? -ne 0; then
  echo "[!] Unable to create the source tarball" 1>&2
  exit 6
fi
cd $CWD

#-------------------------------------------------------------------------------
# Retrieve xrootd tarball if required 
#-------------------------------------------------------------------------------

if test ! x$XRDVERS == x ; then
   if test x${XRDVERS:0:1} = x"v"; then
      XRDVERS=${XRDVERS:1}
   fi
   if test "x$XRDSRCPATH" = "x" ; then
      wget http://xrootd.org/download/v$XRDVERS/xrootd-$XRDVERS.tar.gz -O $RPMSOURCES/xrootd.tar.gz
   else
      cp -rp $XRDSRCPATH -O $RPMSOURCES/xrootd.tar.gz
   fi
   if test $? -ne 0; then
      echo "[!] Unable to retrieve the required XRootD source tarball" 1>&2
      exit 6
   fi
   # Unpack and retrieve required files 
   CWD=$PWD
   cd $TEMPDIR
   mkdir unpack
   cd unpack
   tar xzf $RPMSOURCES/$VXTARGZ
   tar xzf $RPMSOURCES/xrootd.tar.gz
   mkdir -p $VXPREF/src/XrdCrypto
   xrdcryptoh="XrdCryptoAux.hh XrdCryptosslAux.hh XrdCryptosslgsiX509Chain.hh
               XrdCryptoX509Crl.hh XrdCryptoX509Req.hh XrdCryptoRSA.hh
               XrdCryptosslgsiAux.hh XrdCryptoX509Chain.hh XrdCryptoX509.hh"
   for h in $xrdcryptoh ; do
      cp -rp xrootd-$XRDVERS/src/XrdCrypto/$h $VXPREF/src/XrdCrypto
   done
   mkdir -p $VXPREF/src/XrdSut
   xrdsuth="XrdSutAux.hh  XrdSutBucket.hh"
   for h in $xrdsuth ; do
      cp -rp xrootd-$XRDVERS/src/XrdSut/$h $VXPREF/src/XrdSut
   done
   # Repack $VXTARGZ
   tar czf $RPMSOURCES/$VXTARGZ $VXPREF
   # Remove the xrootd tarball
   rm -fr $RPMSOURCES/xrootd.tar.gz
   # Restore working directory
   cd $CWD
fi

#-------------------------------------------------------------------------------
# Generate the spec file
#-------------------------------------------------------------------------------
VXSPECIN="$RPMNAME.spec.in"
VXSPEC="$RPMNAME.spec"
if test ! -r $VXSPECIN; then
  echo "[!] The specfile template does not exist! $PWD" 1>&2
  exit 7
fi
cat $VXSPECIN | sed "s/__VERSION__/$VERSION/" | \
  sed "s/__RELEASE__/$RELEASE/" > $TEMPDIR/$VXSPEC

#-------------------------------------------------------------------------------
# Build the source RPM
#-------------------------------------------------------------------------------
echo "[i] Creating the source RPM..."

# Dirty, dirty hack!
echo "%_sourcedir $RPMSOURCES" >> $TEMPDIR/rpmmacros
rpmbuild --define "_topdir $TEMPDIR/rpmbuild"    \
         --define "%_sourcedir $RPMSOURCES"      \
         --define "%_srcrpmdir %{_topdir}/SRPMS" \
         --define "_source_filedigest_algorithm md5" \
         --define "_binary_filedigest_algorithm md5" \
  -bs $TEMPDIR/$VXSPEC > $TEMPDIR/log
if test $? -ne 0; then
  echo "[!] RPM creation failed" 1>&2
  exit 8
fi

cp $TEMPDIR/rpmbuild/SRPMS/$RPMNAME.src.rpm $OUTPUTPATH
cp $TEMPDIR/$VXSPEC $OUTPUTPATH
rm -rf $TEMPDIR

echo "[i] Done."
