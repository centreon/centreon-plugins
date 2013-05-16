============
Installation
============

Prerequisites
==========

Software Recommandations 
````````````````````````

The "centreon-esxd" connector has been tested on linux systems.
Installation on other system is possible but is outside the scope of this document.

====================    =====================
Software                Minimal Version
====================    =====================
VMWare SDK Perl              5.0
Perl    		     5.8
centreon-esxd                1.3
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

Le connecteur « centreon-esxd » utilise le SDK Perl VMWare pour son fonctionnement. Nous allons donc l'installer. Pour cela nous allons commencer par installer CPAN qui est le nom d'un module Perl qui rend aisés le téléchargement, l'installation, la mise à jour et la maintenance des autres modules Perl qui sont archivés sur le CPAN.


Installer les pré-requis CPAN::

  root # yum install gcc make unzip wget expat-devel e2fsprogs-devel openssl-devel
  root # yum install perl-XML-LibXML perl-Crypt-SSLeay 
  
  root # cpan install Class::MethodMaker
  root # cpan install LWP
  root # cpan install Net::SSLeay
  root # cpan install LWP::Protocol::https
  root # cpan install SOAP::Lite
  
  root # wget http://search.cpan.org/CPAN/authors/id/J/JN/JNH/UUID-0.04.tar.gz
  root # tar zxvf UUID-0.04.tar.gz
  root # cd UUID-0.04
  root # perl Makefile.PL
  root # make && make install

All SDK prerequisites are installed.

Download the last version on the VMWare website (`SDK VMWare <http://www.vmware.com/support/developer/viperltoolkit/>`_) (choose the file correponding to your architecture)

Install VMWare Perl SDK::
 
  root # tar zxvf VMware-vSphere-Perl-SDK-5.1.0-780721.x86_64.tar.gz
  root # cd vmware-vsphere-cli-distrib
  root # perl Makefile.pl
  root # make && make install

Addtionnal Modules Installation
```````````````````````````````

Some features require additionnal prerequisites.

To send data to a syslog daemon, the " Unix::Syslog" must be installed ::
  
  root # cpan install Unix::Syslog

To check a virtual server snapshots date, the "DateTime::Format::ISO8601" is required (**be advise that this module has a lot of CPAN dependencies and may need a full Perl update. This update is hazardous**) ::

  root # cpan install DateTime  
  root # cpan install DateTime::Format::ISO8601
  root # o conf make /usr/bin/make
  root # o conf commit

Reboot your system to complete.

centreon-esxd Installation
``````````````````````````

Download « centreon-esxd » archive, then install ::
  
  root # tar zxvf centreon-esxd-1.X.tar.gz
  root # cd centreon-esxd-1.X
  root # cp centreon_esxd /usr/bin/
  
  root # mkdir -p /etc/centreon
  root # cp centreon_esxd-conf.pm /etc/centreon/centreon_esxd.pm
  root # cp centreon_esxd-init /etc/init.d/centreon_esxd
  
  root # mkdir -p /usr/share/centreon/lib/centreon-esxd
  root # cp lib/* /usr/share/centreon/lib/centreon-esxd/

Configure "centreon-esxd" daemon to start at boot ::
  
  root # chkconfig --level 2345 centreon_esxd on


*"centreon_esx_client.pl" is the corresponding nagios plugin.*

Centreon-esxd Installation - centos/rhel 6 systems
==================================================

SDK Perl VMWare Installation
`````````````````````````````

Le connecteur « centreon-esxd » utilise le SDK Perl VMWare pour son fonctionnement. Nous allons donc l'installer. Pour cela nous allons commencer par installer CPAN qui est le nom d'un module Perl qui rend aisés le téléchargement, l'installation, la mise à jour et la maintenance des autres modules Perl qui sont archivés sur le CPAN.

Installer les pré-requis CPAN::
  
  root # yum install gcc make unzip wget expat-devel e2fsprogs-devel openssl-devel perl-CPAN libuuid-devel
  root # yum install perl-XML-LibXML perl-Crypt-SSLeay perl-Class-MethodMaker perl-SOAP-Lite

  root # cpan install Test::More
  root # cpan install LWP
  root # cpan install Net::SSLeay
  root # cpan install LWP::Protocol::https

  root # wget http://search.cpan.org/CPAN/authors/id/J/JN/JNH/UUID-0.04.tar.gz
  root # tar zxvf UUID-0.04.tar.gz
  root # cd UUID-0.04
  root # perl Makefile.PL
  root # make && make install

All SDK prerequisites are installed.

Download the last version on the VMWare website (`SDK VMWare <http://www.vmware.com/support/developer/viperltoolkit/>`_) (choose the file correponding to your architecture)

Install VMWare Perl SDK::

  root # tar zxvf VMware-vSphere-Perl-SDK-5.1.0-780721.x86_64.tar.gz
  root # cd vmware-vsphere-cli-distrib
  root # perl Makefile.pl
  root # make && make install

Addtionnal Modules Installation
```````````````````````````````

Some features require additionnal prerequisites.

To send data to a syslog daemon, the " Unix::Syslog" must be installed ::
  
  root # cpan install Unix::Syslog

To check a virtual server snapshots date, the "DateTime::Format::ISO8601" is required (**be advise that this module has a lot of CPAN dependencies and may need a full Perl update. This update is hazardous**) ::

  root # cpan install DateTime
  root # cpan install DateTime::Format::ISO8601
  root # o conf make /usr/bin/make
  root # o conf commit

Reboot your system to complete.

centreon-esxd Installation
``````````````````````````

Download « centreon-esxd » archive, then install ::
  
  root # tar zxvf centreon-esxd-1.X.tar.gz
  root # cd centreon-esxd-1.X
  root # cp centreon_esxd /usr/bin/
  
  root # mkdir -p /etc/centreon
  root # cp centreon_esxd-conf.pm /etc/centreon/centreon_esxd.pm
  root # cp centreon_esxd-init /etc/init.d/centreon_esxd
  
  root # mkdir -p /usr/share/centreon/lib/centreon-esxd
  root # cp lib/* /usr/share/centreon/lib/centreon-esxd/

Configure "centreon-esxd" daemon to start at boot ::
  
  root # chkconfig --level 2345 centreon_esxd on


*"centreon_esx_client.pl" is the corresponding nagios plugin.*

