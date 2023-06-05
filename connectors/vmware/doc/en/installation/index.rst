============
Installation
============

Prerequisites
=============

Software Recommandations 
````````````````````````

The "centreon-vmware" connector has been only tested on red-hat 5 and 6 with rpms.
Installation on other system should be possible.

====================== =====================
Software                Version
====================== =====================
VMWare SDK Perl          5.1.0-780721
Perl                     5.8
centreon-vmware          2.0.0
perl-centreon-base       2.6.0
centreon-plugins-base    1.11
ZeroMQ                   4.x
Perl Date::Parse         1.x
Perl ZMQ::LibZMQ4        0.01
Perl ZMQ::Constants      1.04
====================== =====================

How to install from sources is explained in the current documentation.

Hardware Recommandations
````````````````````````

Hardware prerequisites will depend of check numbers. Minimal used resources are :

* RAM : 512 Mo (May slightly increase with the number of checks).
* CPU : same as poller server.

Centreon-vmware Installation - Debian Stretch
=============================================

SDK Perl VMWare Installation
````````````````````````````

The "centreon-vmware" connector uses SDK Perl VMWare for its operation. So we install it with VMWare recommandation (only tested with version below).

========================== ===================== ======================
Dependency                  Version               Repository
========================== ===================== ======================
libwww-perl                   6.15                stretch
libxml-libxml-perl            2.0128              stretch
libclass-methodmaker-perl     2.24                stretch
libcrypt-ssleay-perl          0.73                stretch
libsoap-lite-perl             1.20                stretch
libuuid-perl                  0.27                stretch
========================== ===================== ======================

Install following dependency:
::

  # apt-get install make libxml-libxml-perl libwww-perl libclass-methodmaker-perl libcrypt-ssleay-perl libsoap-lite-perl libuuid-perl libtext-template-perl
  
Download the Perl SDK VMWare and install it:
::

  # tar zxf VMware-vSphere-Perl-SDK-6.7.0-8156551.x86_64.tar.gz && cd vmware-vsphere-cli-distrib
  # perl Makefile.PL
  # make && make install

Requirements
`````````````

Following prerequisites are mandatory for « centreon_vmware »:

* « zeromq » and Perl binding

centreon-vmware Installation with source
````````````````````````````````````````

Install the following package:
::

  # aptitude install libzmq5

Install « zeromq » perl binding dependency (need to patch the installer: https://rt.cpan.org/Public/Bug/Display.html?id=122932):
::

  # apt-get install gcc libmodule-install-perl libzmq3-dev
  # wget https://github.com/lestrrat/p5-ZMQ/archive/master.zip
  # unzip master.zip
  # cd p5-ZMQ-master/ZMQ-LibZMQ4/
  # perl Makefile.PL
  # make && make install
  # cd p5-ZMQ-master/ZMQ-Constants/
  # perl Makefile.PL
  # make && make install

Download « centreon-vmware » archive, then install:
::
  
  # tar zxvf centreon-vmware-3.0.0.tar.gz
  # cd centreon-vmware-3.0.0
  # cp centreon_vmware.pl /usr/bin/
  
  # mkdir -p /etc/centreon /var/log/centreon
  # useradd centreon
  # chown centreon:centreon /var/log/centreon
  # cp contrib/config/centreon_vmware-conf.pm /etc/centreon/centreon_vmware.pm
  # cp contrib/debian/centreon_vmware-systemd /lib/systemd/system/centreon_vmware.service
  # chmod 664 /lib/systemd/system/centreon_vmware.service
  
  # mkdir -p /usr/share/perl5/centreon/vmware/ /usr/share/perl5/centreon/script/
  # cp centreon/vmware/* /usr/share/perl5/centreon/vmware/
  # cp centreon/script/centreon_vmware.pm /usr/share/perl5/centreon/script/

Configure "centreon-vmware" daemon to start at boot:
::
  
  # systemctl enable centreon_vmware.service
  
Install the client and dependency:
::

  # apt-get install libtimedate-perl
  # git clone http://git.centreon.com/centreon-plugins.git
  # cd centreon-plugins
  # mkdir -p /usr/lib/nagios/plugins/centreon/plugins/
  # cp centreon/plugins/* /usr/lib/nagios/plugins/centreon/plugins/
  # mkdir -p /usr/lib/nagios/plugins/apps/vmware/
  # cp -R apps/vmware/* /usr/lib/nagios/plugins/apps/vmware/
  # cp centreon_plugins.pl /usr/lib/nagios/plugins/

Centreon-vmware Installation - centos/rhel 5 systems
====================================================

SDK Perl VMWare Installation
````````````````````````````

The "centreon-vmware" connector uses SDK Perl VMWare for its operation. So we install it with VMWare recommandation (only tested with version below).

======================= ===================== ======================
Dependency               Version               Repository
======================= ===================== ======================
perl-libwww-perl             5.805            redhat/centos base
perl-XML-LibXML              1.58             redhat/centos base
perl-Class-MethodMaker       2.18             ces standard
perl-Crypt-SSLeay            0.51             redhat/centos base
perl-SOAP-Lite               0.712            ces standard
perl-UUID                    0.04             ces standard
perl-VMware-vSphere          5.1.0-780721.1   ces standard
======================= ===================== ======================

Install following dependency:
::

  # yum install perl-VMware-vSphere

Requirements
`````````````

Following prerequisites are mandatory for « centreon_vmware »:

* « centreon-plugins-base »: in repository ces standard
* « zeromq » and Perl binding: in repository ces standard or EPEL

Following prerequisites are optional for « centreon_vmware »:

*  « perl-TimeDate »: in repository redhat/centos base

centreon-vmware Installation with rpm
`````````````````````````````````````

Install the connector:
::

  # yum install ces-plugins-Virtualization-VMWare-daemon

Install the client:
::

  # yum install ces-plugins-Virtualization-VMWare-client

centreon-vmware Installation with source
````````````````````````````````````````

Download « centreon-vmware » archive, then install:
::
  
  # tar zxvf centreon-vmware-3.0.0.tar.gz
  # cd centreon-vmware-3.0.0
  # cp centreon_vmware.pl /usr/bin/
  
  # mkdir -p /etc/centreon
  # cp contrib/config/centreon_vmware-conf.pm /etc/centreon/centreon_vmware.pm
  # cp contrib/redhat/centreon_vmware-init /etc/init.d/centreon_vmware
  # cp contrib/redhat/centreon_vmware-sysconfig /etc/sysconfig/centreon_vmware
  # chmod 775 /etc/init.d/centreon_vmware /usr/bin/centreon_vmware.pl
  
  # mkdir -p /usr/lib/perl5/vendor_perl/5.8.8/centreon/vmware/ /usr/lib/perl5/vendor_perl/5.8.8/centreon/script/
  # cp centreon/vmware/* /usr/lib/perl5/vendor_perl/5.8.8/centreon/vmware/
  # cp centreon/script/centreon_vmware.pm /usr/lib/perl5/vendor_perl/5.8.8/centreon/script/

Configure "centreon-vmware" daemon to start at boot:
::
  
  # chkconfig --level 2345 centreon_vmware on
  
Install the client and dependency:
::

  # git clone http://git.centreon.com/centreon-plugins.git
  # cd centreon-plugins
  # mkdir -p /usr/lib/nagios/plugins/centreon/plugins/
  # cp centreon/plugins/* /usr/lib/nagios/plugins/centreon/plugins/
  # mkdir -p /usr/lib/nagios/plugins/apps/vmware/
  # cp -R apps/vmware/* /usr/lib/nagios/plugins/apps/vmware/
  # cp centreon_plugins.pl /usr/lib/nagios/plugins/

Centreon-vmware Installation - centos/rhel 6 systems & centos 7
====================================================

SDK Perl VMWare Installation
````````````````````````````

The "centreon-vmware" connector uses SDK Perl VMWare for its operation. So we install it with VMWare recommendation (only tested with version below).

======================= ===================== ======================
Dependency               Version               Repository
======================= ===================== ======================
perl-libwww-perl             5.833            redhat/centos base
perl-XML-LibXML              1.70             redhat/centos base
perl-Class-MethodMaker       2.16             redhat/centos base
perl-Crypt-SSLeay            0.57             redhat/centos base
perl-SOAP-Lite               0.710.10         redhat/centos base
perl-UUID                    0.04             ces standard
perl-VMware-vSphere          5.1.0-780721.1   ces standard
======================= ===================== ======================

Install following dependency:
::

  root # yum install perl-VMware-vSphere

Requirements
````````````

Following prerequisites are mandatory for « centreon_vmware »:

* « perl-centreon-base »:  module since Centreon 2.5 (repository ces standard)
* « centreon-plugins-base »: in repository ces standard
* « zeromq » and Perl binding: in repository ces standard or EPEL

Following prerequisites are optional for « centreon_vmware »:

*  « perl-TimeDate »: in repository redhat/centos base

centreon-vmware Installation with rpm
`````````````````````````````````````

Install the connector:
::

  # yum install centreon-plugin-Virtualization-VMWare-daemon

Install the client:
::

  # yum install centreon-plugin-Virtualization-Vmware2-Connector-Plugin
  
centreon-vmware Installation with source
````````````````````````````````````````

Download « centreon-vmware » archive, then install:
::
  
  # tar zxvf centreon-vmware-3.0.0.tar.gz
  # cd centreon-vmware-3.0.0
  # cp centreon_vmware.pl /usr/bin/
  
  # mkdir -p /etc/centreon
  # cp contrib/config/centreon_vmware-conf.pm /etc/centreon/centreon_vmware.pm
  # cp contrib/redhat/centreon_vmware-init /etc/init.d/centreon_vmware
  # cp contrib/redhat/centreon_vmware-sysconfig /etc/sysconfig/centreon_vmware
  # chmod 775 /etc/init.d/centreon_vmware /usr/bin/centreon_vmware.pl
  
  # mkdir -p /usr/share/perl5/vendor_perl/centreon/vmware/ /usr/share/perl5/vendor_perl/centreon/script/
  # cp centreon/vmware/* /usr/share/perl5/vendor_perl/centreon/vmware/
  # cp centreon/script/centreon_vmware.pm /usr/share/perl5/vendor_perl/centreon/script/

Configure "centreon-vmware" daemon to start at boot:
::
  
  # chkconfig --level 2345 centreon_vmware on
  
Install the client and dependency:
::

  # git clone http://git.centreon.com/centreon-plugins.git
  # cd centreon-plugins
  # mkdir -p /usr/lib/nagios/plugins/centreon/plugins/
  # cp centreon/plugins/* /usr/lib/nagios/plugins/centreon/plugins/
  # mkdir -p /usr/lib/nagios/plugins/apps/vmware/
  # cp -R apps/vmware/* /usr/lib/nagios/plugins/apps/vmware/
  # cp centreon_plugins.pl /usr/lib/nagios/plugins/
