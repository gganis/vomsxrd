#-------------------------------------------------------------------------------
# We assume the xrootd user when building for the OSG
#-------------------------------------------------------------------------------
%if "0%{?dist}" == "0.osg"
%define _with_xrootd_user 1
%endif

#-------------------------------------------------------------------------------
# Package definitions
#-------------------------------------------------------------------------------
Name:      vomsxrd
Epoch:     1
Version:   0.2.0
Release:   1%{?dist}%{?_with_xrootd_user:.xu}
Summary:   VOMS attribute extractor plug-in for XRootD
Group:     System Environment/Libraries
License:   BSD
URL:       https://github.com/gganis/voms
Prefix:    /usr

# git clone git://github.com/gganis/voms.git vomsxrd
# cd vomsxrd
# ./packaging/maketar.sh --prefix vomsxrd --output ~/rpmbuild/SOURCES/vomsxrd.tar.gz
Source0:   vomsxrd.tar.gz
BuildRoot: %{_tmppath}/%{name}-root

BuildRequires: cmake >= 2.6
BuildRequires: voms >= 2.0.6
BuildRequires: voms-devel >= 2.0.6
BuildRequires: xrootd-libs >= 3.2.7
BuildRequires: xrootd-libs-devel >= 3.2.7

Requires: voms >= 2.0.6
Requires: xrootd-libs >= 3.2.7

%description
The VOMS attribute extractor plug-in for XRootD

#-------------------------------------------------------------------------------
# devel
#-------------------------------------------------------------------------------
%package devel
Summary: Headers for using the VOMS attribute extractor plug-in
Group:   System Environment/Libraries
Requires: %{name} = %{epoch}:%{version}-%{release}
%description devel
Headers for using the VOMS attribute extractor plug-in

#-------------------------------------------------------------------------------
# Build instructions
#-------------------------------------------------------------------------------
%prep
%setup -c -n %{name}

%build
cd %{name}
mkdir build
cd build

cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=RelWithDebInfo ../

make VERBOSE=1 %{?_smp_mflags}

#-------------------------------------------------------------------------------
# Installation
#-------------------------------------------------------------------------------
%install
cd %{name}
cd build
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT
cd ..

%clean
rm -rf $RPM_BUILD_ROOT

#-------------------------------------------------------------------------------
# Post actions
#-------------------------------------------------------------------------------

%post 
/sbin/ldconfig

%postun
/sbin/ldconfig

#-------------------------------------------------------------------------------
# Files
#-------------------------------------------------------------------------------
%files 
%defattr(-,root,root,-)
%{_libdir}/libXrdSecgsiVOMS.so*
%doc %{_mandir}/man1/libXrdSecgsiVOMS.1.gz

%files devel
%defattr(-,root,root,-)
%{_includedir}/%{name}

#-------------------------------------------------------------------------------
# Changelog
#-------------------------------------------------------------------------------
%changelog
* Wed Mar 21 2013 G. Ganis <gerardo.ganis@cern.ch>
- Created
