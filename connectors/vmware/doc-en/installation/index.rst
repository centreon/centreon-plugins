============
Installation
============

Prerequisites
=============

Software Recommandations 
````````````````````````

The "centreon-esxd" connector has been tested on linux systems.
Installation on other system is possible but is outside the scope of this document.

====================    =====================
Software                Minimal Version
====================    =====================
VMWare SDK Perl              5.1
Perl    		             5.8
centreon-esxd                1.4
centreon-common-perl         2.5
====================    =====================

Hardware Recommandations
````````````````````````

Hardware prerequisites will vary depending on the number of monitored hosts. Without configured, no checks are done. Minimal used ressources are :

* RAM : 512 Mo (May slightly increase with the number of checks).

* CPU : same as poller server.

Centreon-esxd Installation - centos/rhel 5 systems
==================================================

SDK Perl VMWare Installation
````````````````````````````

The "centreon-esxd" connector uses SDK Perl VMWare for its operation. So we install it. To do this, we begin by install CPAN, it's the name of a Perl module who improves the download, the installation, the upgrade and the maintenance of others Perl modules who are archived on the CPAN.

Install CPAN prerequisites ::

  root # yum install gcc make unzip wget e2fsprogs-devel
  root # yum install perl-XML-LibXML perl-Crypt-SSLeay perl-libwww-perl perl-TimeDate
  
  root # cpan install Class::MethodMaker
  root # cpan install SOAP::Lite
  
  root # wget http://search.cpan.org/CPAN/authors/id/J/JN/JNH/UUID-0.04.tar.gz
  root # tar zxvf UUID-0.04.tar.gz
  root # cd UUID-0.04
  root # perl Makefile.PL
  root # make && make install

All SDK prerequisites are installed.

Download the last version on the VMWare website (`SDK VMWare <http://www.vmware.com/support/developer/viperltoolkit/>`_) (choose the file correponding to your architecture)

Install VMWare Perl SDK::
 
  root # tar zxvf VMware-vSphere-Perl-SDK-5.1.0-780721.x86_64.gz
  root # cd vmware-vsphere-cli-distrib
  root # perl Makefile.pl
  root # make && make install

Requirements
```````````````````````````````

« centreon-common-perl » is a prerequisite for « centreon_esxd ». (Module in Centreon 2.5)


centreon-esxd Installation
``````````````````````````

Download « centreon-esxd » archive, then install ::
  
  root # tar zxvf centreon-esxd-1.4.tar.gz
  root # cd centreon-esxd-1.4
  root # cp centreon_esxd /usr/bin/
  
  root # mkdir -p /etc/centreon
  root # cp centreon_esxd-conf.pm /etc/centreon/centreon_esxd.pm
  root # cp centreon_esxd-init /etc/init.d/centreon_esxd
  
  root # mkdir -p /usr/lib/perl5/vendor_perl/5.8.8/centreon/esxd/
  root # cp lib/* /usr/lib/perl5/vendor_perl/5.8.8/centreon/esxd/
  root # cp centreonesxd.pm /usr/lib/perl5/vendor_perl/5.8.8/centreon/script/

Configure "centreon-esxd" daemon to start at boot ::
  
  root # chkconfig --level 2345 centreon_esxd on


*"centreon_esx_client.pl" is the corresponding nagios plugin.*

Centreon-esxd Installation - centos/rhel 6 systems
==================================================

SDK Perl VMWare Installation
`````````````````````````````

TODO