============
Installation
============

Prerequisites
=============

Software Recommandations 
````````````````````````

The "centreon-esxd" connector has been tested on red-hat 5 and 6 with rpms.
Installation on other system is possible but is outside the scope of this document (Debian,...).

==================== =====================
Software              Version
==================== =====================
VMWare SDK Perl              5.1
Perl                         5.8
centreon-esxd                1.4
centreon-common-perl         2.5
==================== =====================

.. warning::
    The "centreon-esxd" RPMS provided by Merethis is designed to work with Centreon 2.5 (CES 2.2 or CES 3), it does not work with Centreon 2.4.

Hardware Recommandations
````````````````````````

Hardware prerequisites will depend of check numbers. Minimal used ressources are :

* RAM : 512 Mo (May slightly increase with the number of checks).
* CPU : same as poller server.

Centreon-esxd Installation - centos/rhel 5 systems
==================================================

SDK Perl VMWare Installation
````````````````````````````

The "centreon-esxd" connector uses SDK Perl VMWare for its operation. So we install it with VMWare recommandation (only tested with version below).

======================= ===================== ======================
Dependency               Version               Repository
======================= ===================== ======================
perl-libwww-perl             5.805            redhat/centos base
perl-XML-LibXML              1.58             redhat/centos base
perl-Class-MethodMaker       2.18             ces base
perl-Crypt-SSLeay            0.51             redhat/centos base
perl-SOAP-Lite               0.712            ces base
perl-UUID                    0.04             ces base
perl-VMware-vSphere          5.1.0-780721.1   centreon plugin-packs
======================= ===================== ======================

Install following dependency::

  root # yum install perl-VMware-vSphere

Requirements
```````````````````````````````

« perl-centreon-base » is a prerequisite for « centreon_esxd ». (Module in Centreon 2.5)

centreon-esxd Installation with rpm
```````````````````````````````````

Install the connector::

  root # yum install ces-plugins-Virtualization-VMWare

centreon-esxd Installation with source
``````````````````````````````````````

Download « centreon-esxd » archive, then install ::
  
  root # tar zxvf centreon-esxd-1.5.4.tar.gz
  root # cd centreon-esxd-1.5.4
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

Install following dependency::

  root # yum install perl-VMware-vSphere

Requirements
```````````````````````````````

« perl-centreon-base » is a prerequisite for « centreon_esxd ». (Module in Centreon 2.5)

centreon-esxd Installation with rpm
```````````````````````````````````

Install the connector::

  root # yum install ces-plugins-Virtualization-VMWare

centreon-esxd Installation with source
``````````````````````````````````````

Download « centreon-esxd » archive, then install ::
  
  root # tar zxvf centreon-esxd-1.5.4.tar.gz
  root # cd centreon-esxd-1.5.4
  root # cp centreon_esxd /usr/bin/
  
  root # mkdir -p /etc/centreon
  root # cp centreon_esxd-conf.pm /etc/centreon/centreon_esxd.pm
  root # cp centreon_esxd-init /etc/init.d/centreon_esxd
  
  root # mkdir -p /usr/share/perl5/vendor_perl/centreon/esxd/
  root # cp lib/* /usr/share/perl5/vendor_perl/centreon/esxd/
  root # cp centreonesxd.pm /usr/share/perl5/vendor_perl/centreon/script/

Configure "centreon-esxd" daemon to start at boot ::
  
  root # chkconfig --level 2345 centreon_esxd on

*"centreon_esx_client.pl" is the corresponding nagios plugin.*
