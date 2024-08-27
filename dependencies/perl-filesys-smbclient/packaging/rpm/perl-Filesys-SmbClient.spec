Name:		perl-Filesys-SmbClient
Version:	4.0
Release:	1%{?dist}
Summary:	perl interface to access Samba filesystem with libsmclient.so
Group:		Development/Libraries
License:	Apache
URL:		https://github.com/garnier-quentin/Filesys-SmbClient
Source0:	%{name}.tar.gz
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildRequires:  libsmbclient-devel
BuildRequires:  make
BuildRequires:  gcc
BuildRequires:  perl-ExtUtils-MakeMaker

Provides:	    perl(Filesys::SmbClient)
Requires:	    libsmbclient
AutoReqProv:    no

%description
Provide interface to access routine defined in libsmbclient.so provided with Samba.

%prep
%setup -q -n %{name}

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor OPTIMIZE="$RPM_OPT_FLAGS"
make %{?_smp_mflags}

%install
rm -rf %{buildroot}
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
%{_fixperms} $RPM_BUILD_ROOT/*

%check
#make test

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%{perl_vendorarch}/
%{_mandir}/man3/*.3*

%changelog
