#!/bin/bash
#-------------------------------------------------------------------------------
# Create a source tarball including information about the tag
# Author: Gerardo Ganis <gerardo.ganis@cern.ch> (March 2013)
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Find a program (L.Janisz)
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
  echo "${0} [--help] [--output PATH] [--prefix PREFIX]"     1>&2
  echo "  --help        prints this message"                 1>&2
  echo "  --output PATH tarball file"                        1>&2
  echo "                default: ../vomsxrd-<vers>.tar.gz"   1>&2
  echo "  --prefix PREFIX Prepend PREFIX/ to each filename"  1>&2
  echo "                in the archive [vomsxrd-<vers>]"     1>&2
}

#-------------------------------------------------------------------------------
# Parse the commandline, if only we could use getopt... :(
#-------------------------------------------------------------------------------
OUTFILE=".."
PREFIX=""
PRINTHELP=0

while test ${#} -ne 0; do
  if test x${1} = x--help; then
    PRINTHELP=1
  elif test x${1} = x--output; then
    if test ${#} -lt 2; then
      echo "--output parameter needs an argument" 1>&2
      exit 1
    fi
    OUTFILE=${2}
    shift
  elif test x${1} = x--prefix; then
    if test ${#} -lt 2; then
      echo "--prefix parameter needs an argument" 1>&2
      exit 1
    fi
    PREFIX=${2}
    shift
  fi
  shift
done

if test $PRINTHELP -eq 1; then
  printHelp
  exit 0
fi

echo "[I] Storing the output to: $OUTDIR"

#-------------------------------------------------------------------------------
# Check if we have all the necessary components
#-------------------------------------------------------------------------------
if test ! -d .git; then
  echo "[!] I can only work with a git repository" 1>&2
  exit 1
fi

if test x`findProg git` = x; then
  echo "[!] Unable to find git, aborting..." 1>&2
  exit 2
fi

#-------------------------------------------------------------------------------
# Get the tag, whether matching exactly or not
#-------------------------------------------------------------------------------
VERSION="`git describe --tags`"
# Drop the leading 'v'
VERSION=${VERSION/v/}
# Last tag
VTG=`echo $VERSION | sed "s|\(.*\)\-\(.*\)\-\(.*\)|\1|"`
# Since last patch ?
VRL=`echo $VERSION | sed "s|\(.*\)\-\(.*\)\-\(.*\)|\2|"`
# Exact tag?
if test x$VRL == x0 ; then
   VERSIONS=$VTG
else
   VERSIONS=`echo $VERSION | sed "s|\(.*\)\-\(.*\)\-\(.*\)|\1-\3|"`
fi
COMMIT=`git log --pretty=format:"%H" -1`
if test x$PREFIX == x ; then
   PREFIX="vomsxrd-$VERSIONS"
fi
if test x$OUTFILE == x.. ; then
   OUTFILE="../vomsxrd-$VERSIONS.tar.gz"
fi

#-------------------------------------------------------------------------------
# Unpack in dedicated temporary directory
#-------------------------------------------------------------------------------
TEMPDIR=`mktemp -d /tmp/vomsxrd.srpm.XXXXXXXXXX`
git archive --prefix="$PREFIX/" --format=tar $COMMIT -o $TEMPDIR/vomsxrd-$VERSIONS.tar
if test $? -ne 0; then
  echo "[!] Unable to create first archive" 1>&2
  exit 3
fi
CWD=$PWD
cd $TEMPDIR
tar xf $TEMPDIR/vomsxrd-$VERSIONS.tar
echo "Tag: $VERSION" >> $TEMPDIR/$PREFIX/VERSION_INFO
rm -fr $TEMPDIR/$PREFIX/.gitattributes
rm -fr $TEMPDIR/vomsxrd-$VERSIONS.tar
tar cf $TEMPDIR/vomsxrd-$VERSIONS.tar $PREFIX
if test $? -ne 0; then
  echo "[!] Unable to create new archive" 1>&2
  exit 4
fi
gzip -9fn $TEMPDIR/vomsxrd-$VERSIONS.tar
cd $CWD
mv $TEMPDIR/vomsxrd-$VERSIONS.tar.gz $OUTFILE
rm -fr $TEMPDIR

if test -f $OUTFILE ; then
  echo "[I] Tarball $OUTFILE successfully created"
else
  echo "[!] Unable to create tarball" 1>&2
  exit 5
fi
exit 0
