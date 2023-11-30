Name:		perl-KeePass-Reader
Version:	0.2
Release:	2%{?dist}
Summary:	Interface to KeePass V4 database files
Group:		Development/Libraries
License:	Apache2
URL:		https://github.com/garnier-quentin/perl-KeePass-Reader
Source0:	%{name}.tar.gz
BuildArch:  noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildRequires:  make
BuildRequires:  perl(ExtUtils::MakeMaker)

Requires: perl(Crypt::Argon2)

%description
KeePass::Reader is a perl interface to read KeePass version 4.

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
rm -rf $RPM_BUILD_ROOT%{_usr}/bin/hexdump
%{_fixperms} $RPM_BUILD_ROOT/*

%check
#make test

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%{perl_vendorlib}
%{_mandir}/man3/*.3*

%changelog

