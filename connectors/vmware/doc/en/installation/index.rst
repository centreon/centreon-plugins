============
Installation
============

Prerequisites
=============

Software Recommandations 
````````````````````````

The "centreon-esxd" connector has been only tested on red-hat 6 with rpms.
Installation on other system is possible but is outside the scope of this document (Debian,...).

====================== =====================
Software                Version
====================== =====================
VMWare SDK Perl          5.1.0-780721
Perl                     5.8
centreon-esxd            1.6.0
perl-centreon-base       2.5.0
centreon-plugins-base    1.10
ZeroMQ                   3.x
Perl ZMQ::LibZMQ3        1.19
Perl ZMQ::Constants      1.04
====================== =====================

.. warning::
    The "centreon-esxd" RPMS provided by Merethis is designed to work with Centreon 2.5 (CES 3), it does not work with Centreon 2.4.

Hardware Recommandations
````````````````````````

Hardware prerequisites will depend of check numbers. Minimal used resources are :

* RAM : 512 Mo (May slightly increase with the number of checks).
* CPU : same as poller server.

Centreon-esxd Installation - centos/rhel 5 systems
==================================================

Not tested on centos/rhel 5. There is a problem with Perl ZMQ::LibZMQ3 module.

Centreon-esxd Installation - centos/rhel 6 systems
==================================================

SDK Perl VMWare Installation
````````````````````````````

The "centreon-esxd" connector uses SDK Perl VMWare for its operation. So we install it with VMWare recommandation (only tested with version below).

======================= ===================== ======================
Dependency               Version               Repository
======================= ===================== ======================
perl-libwww-perl             5.833            redhat/centos base
perl-XML-LibXML              1.70             redhat/centos base
perl-Class-MethodMaker       2.16             redhat/centos base
perl-Crypt-SSLeay            0.57             redhat/centos base
perl-SOAP-Lite               0.710.10         redhat/centos base
perl-UUID                    0.04             centreon plugin-packs
perl-VMware-vSphere          5.1.0-780721.1   centreon plugin-packs
======================= ===================== ======================

Install following dependency:
::

  root # yum install perl-VMware-vSphere

Requirements
```````````````````````````````

Following prerequisites are mandatory for « centreon_esxd »:

* « perl-centreon-base »:  module since Centreon 2.5 (repository ces standard)
* « centreon-plugins-base »: in repository centreon plugin-packs
* « zeromq » and Perl binding: in repository ces standard or EPEL

centreon-esxd Installation with rpm
```````````````````````````````````

Install the connector:
::

  root # yum install ces-plugins-Virtualization-VMWare

Install the client:
::

  root # yum install ces-plugins-Virtualization-VMWare-client
  
centreon-esxd Installation with source
``````````````````````````````````````

Download « centreon-esxd » archive, then install:
::
  
  root # tar zxvf centreon-esxd-1.6.0.tar.gz
  root # cd centreon-esxd-1.6.0
  root # cp centreon_esxd /usr/bin/
  
  root # mkdir -p /etc/centreon
  root # cp centreon_esxd-conf.pm /etc/centreon/centreon_esxd.pm
  root # cp centreon_esxd-init /etc/init.d/centreon_esxd
  
  root # mkdir -p /usr/share/perl5/vendor_perl/centreon/esxd/
  root # cp centreon/esxd/* /usr/share/perl5/vendor_perl/centreon/esxd/
  root # cp centreon/script/centreonesxd.pm /usr/share/perl5/vendor_perl/centreon/script/

Configure "centreon-esxd" daemon to start at boot:
::
  
  root # chkconfig --level 2345 centreon_esxd on

Install the client:
::

  root # git clone http://git.centreon.com/centreon-plugins.git
  root # cd centreon-plugins
  root # mkdir -p /usr/lib/nagios/plugins/centreon/plugins/
  root # cp centreon/plugins/* /usr/lib/nagios/plugins/centreon/plugins/
  root # mkdir -p /usr/lib/nagios/plugins/apps/vmware/
  root # cp -R apps/vmware/* /usr/lib/nagios/plugins/apps/vmware/
  root # cp centreon_plugins.pl /usr/lib/nagios/plugins/
