%define archive_name putty

Name:       plink
Version:    0.74
Release:    1%{?dist}
Summary:    Plink (PuTTY Link) is a command-line connection tool similar to UNIX ssh.

Group:      Development/Tools
License:    MIT licence
URL:        http://www.chiark.greenend.org.uk/~sgtatham/putty/

Source0:    %{archive_name}-%{version}.tar.gz
BuildRoot:  %(mktemp -ud %{_tmppath}/%{archive_name}-%{version}-%{release}-XXXXXX)

BuildRequires:  make
BuildRequires:  gcc

%description
Plink (PuTTY Link) is a command-line connection tool similar to UNIX ssh.
It is mostly used for automated operations, such as making CVS access a repository on a remote server.

%prep
%setup -q -n %{archive_name}-%{version}

%build
%configure --without-gtk
make %{?_smp_mflags}

%install
rm -rf %{buildroot}
make install DESTDIR=%{buildroot}
rm -rf $RPM_BUILD_ROOT%{_bindir}/pscp
rm -rf $RPM_BUILD_ROOT%{_bindir}/psftp
rm -rf $RPM_BUILD_ROOT%{_bindir}/puttygen
rm -rf $RPM_BUILD_ROOT%{_mandir}/

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%doc
%{_bindir}/plink

%changelog
