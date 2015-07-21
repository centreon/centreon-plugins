============
Installation
============

Pré-Requis
==========

Préconisations logicielles
``````````````````````````

Le connecteur "centreon-vmware" est testé et validé sur red-hat 6 uniquement avec des rpms. 
L'installation sur d'autres environnements n'est pas exclu mais non présenté dans ce document (Debian, ...).

====================== =====================
Logiciels               Version
====================== =====================
VMWare SDK Perl          5.1.0-780721
Perl                     5.8
centreon-vmware          2.0.0
perl-centreon-base       2.5.0
centreon-plugins-base    1.10
ZeroMQ                   3.x
Perl Date::Parse         1.x
Perl ZMQ::LibZMQ3        1.19
Perl ZMQ::Constants      1.04
====================== =====================

Il est expliqué comment installer par les sources dans ce document.

Préconisations matérielles
``````````````````````````

Le matériel nécessaire dépend du nombre de demandes de vérifications. Par défaut, le connecteur n'effectue aucunes vérifications. Les ressources minimales sont de :

* mémoire vive : 512 Mo minimum (Peut sensiblement augmenter en fonction du nombre de contrôle).
* CPU : même pré-requis que pour le serveur de collecte.

Centreon-vmware Installation - Debian Wheezy
============================================

Installation du SDK Perl VMWare
```````````````````````````````

Le connecteur « centreon-vmware » utilise le SDK Perl VMWare pour son fonctionnement. Nous allons donc l'installer en suivant les versions recommandées par VMWare (en dehors de ces versions, le fonctionnement n'est pas garanti).

========================== ===================== ======================
Dependency                  Version               Repository
========================== ===================== ======================
libwww-perl                   6.04                wheezy
libxml-libxml-perl            2.0001              wheezy
libclass-methodmaker-perl     2.18                wheezy
libcrypt-ssleay-perl          0.58                wheezy
libsoap-lite-perl             0.714               wheezy
libuuid-perl                  0.02                wheezy
========================== ===================== ======================

Installer les dépendances suivantes:
::

  # aptitude install make libxml-libxml-perl libwww-perl libclass-methodmaker-perl libcrypt-ssleay-perl libsoap-lite-perl libuuid-perl

Télécharger et installer le Perl SDK VMWare:
::

  # tar zxf VMware-vSphere-Perl-SDK-6.0.0-2503617.x86_64.tar.gz && cd vmware-vsphere-cli-distrib
  # perl Makefile.PL
  # make && make install

Pré-requis
``````````

Les dépendances suivantes sont nécessaires pour le fonctionnement de « centreon_vmware »:

* « perl-centreon-base »:  module depuis Centreon 2.5
* « centreon-plugins-base »: le client et des dépendances
* « zeromq » et son module Perl

Les dépendances suivantes sont optionnelles pour le fonctionnement de « centreon_vmware »:

*  « libtimedate-perl »

Installation de centreon-vmware par les sources
```````````````````````````````````````````````

Installer le paquet suivant:
::

  # aptitude install libtimedate-perl

Ajouter la ligne suivante dans le fichier  « /etc/apt/sources.list »:
::

  deb http://http.debian.net/debian wheezy-backports main

Installer la dépendance « zeromq »:
::

  # aptitude install libzmq3-dev gcc
  # wget https://cpan.metacpan.org/authors/id/D/DM/DMAKI/ZMQ-LibZMQ3-1.19.tar.gz
  # tar zxf ZMQ-LibZMQ3-1.19.tar.gz && cd ZMQ-LibZMQ3-1.19
  # perl Makefile.PL
  # make && make install
  # wget https://cpan.metacpan.org/authors/id/D/DM/DMAKI/ZMQ-Constants-1.04.tar.gz
  # tar zxf ZMQ-Constants-1.04.tar.gz && cd ZMQ-Constants-1.04
  # perl Makefile.PL
  # make && make install

Télécharger l'archive de « centreon-vmware » et installer le connecteur:
::

  # tar zxvf centreon-vmware-2.0.0.tar.gz
  # cd centreon-vmware-2.0.0
  # cp centreon_vmware.pl /usr/bin/
  
  # mkdir -p /etc/centreon
  # cp contrib/config/centreon_vmware-conf.pm /etc/centreon/centreon_vmware.pm
  # cp contrib/debian/centreon_vmware-init /etc/init.d/centreon_vmware
  # cp contrib/debian/centreon_vmware-default /etc/default/centreon_vmware
  # chmod 775 /etc/init.d/centreon_vmware /usr/bin/centreon_vmware.pl
  
  # mkdir -p /usr/share/perl5/centreon/vmware/ /usr/share/perl5/centreon/script/
  # cp centreon/vmware/* /usr/share/perl5/centreon/vmware/
  # cp centreon/script/centreon_vmware.pm /usr/share/perl5/centreon/script/

Activer le daemon « centreon-vmware » au démarrage:
::
  
  # update-rc.d centreon_vmware defaults

Installer la dépendance « perl-centreon-base »:
::

  # git clone -b 2.6.x --single-branch https://github.com/centreon/centreon.git centreon
  # cd centreon
  # cp lib/perl/centreon/script.pm /usr/share/perl5/centreon/
  # cp -R lib/perl/centreon/common /usr/share/perl5/centreon/
  
Installer le client et les dépendances:
::

  # git clone http://git.centreon.com/centreon-plugins.git
  # cd centreon-plugins
  # cp -R centreon/plugins /usr/share/perl5/centreon/
  # mkdir -p /usr/lib/nagios/plugins/centreon/plugins/
  # cp centreon/plugins/* /usr/lib/nagios/plugins/centreon/plugins/
  # mkdir -p /usr/lib/nagios/plugins/apps/vmware/
  # cp -R apps/vmware/* /usr/lib/nagios/plugins/apps/vmware/
  # cp centreon_plugins.pl /usr/lib/nagios/plugins/

Installation de centreon-vmware - Environnement centos/rhel 5
=============================================================

Installation du SDK Perl VMWare
```````````````````````````````

Le connecteur « centreon-vmware » utilise le SDK Perl VMWare pour son fonctionnement. Nous allons donc l'installer en suivant les versions recommandées par VMWare (en dehors de ces versions, le fonctionnement n'est pas garanti).

======================= ===================== ======================
Dépendance               Version               Dépôt
======================= ===================== ======================
perl-libwww-perl             5.805            redhat/centos base
perl-XML-LibXML              1.58             redhat/centos base
perl-Class-MethodMaker       2.18             ces standard
perl-Crypt-SSLeay            0.51             redhat/centos base
perl-SOAP-Lite               0.712            ces standard
perl-UUID                    0.04             ces standard
perl-VMware-vSphere          5.1.0-780721.1   ces standard
======================= ===================== ======================

Installer la dépendance suivante:
::

  # yum install perl-VMware-vSphere

Pré-requis
``````````

Les dépendances suivantes sont nécessaires pour le fonctionnement de « centreon_vmware »:

* « perl-centreon-base »: module depuis Centreon 2.5 (dépôt ces standard)
* « centreon-plugins-base »: dépôt ces standard
* « zeromq » and Perl binding: dépôt ces standard ou EPEL

Les dépendances suivantes sont optionnelles pour le fonctionnement de « centreon_vmware »:

*  « perl-TimeDate »: dépôt redhat/centos base

Installation de centreon-vmware par rpm
```````````````````````````````````````

Installer le connecteur:
::

  # yum install ces-plugins-Virtualization-VMWare-daemon

Installer le client:
::

  # yum install ces-plugins-Virtualization-VMWare-client

Installation de centreon-vmware par les sources
```````````````````````````````````````````````

Télécharger l'archive de « centreon-vmware ».

Installer les fichiers:
::
  
  # tar zxvf centreon-vmware-2.0.0.tar.gz
  # cd centreon-vmware-2.0.0
  # cp centreon_vmware.pl /usr/bin/
  
  # mkdir -p /etc/centreon
  # cp contrib/config/centreon_vmware-conf.pm /etc/centreon/centreon_vmware.pm
  # cp contrib/redhat/centreon_vmware-init /etc/init.d/centreon_vmware
  # cp contrib/redhat/centreon_vmware-sysconfig /etc/sysconfig/centreon_vmware
  # chmod 775 /etc/init.d/centreon_vmware /usr/bin/centreon_vmware.pl
  
  # mkdir -p /usr/lib/perl5/vendor_perl/5.8.8/centreon/vmware/ /usr/lib/perl5/vendor_perl/5.8.8/centreon/script/
  # cp centreon/vmware/* /usr/lib/perl5/vendor_perl/5.8.8/centreon/vmware/
  # cp centreon/script/centreon_vmware.pm /usr/lib/perl5/vendor_perl/5.8.8/centreon/script/

Activer le daemon « centreon-vmware » au démarrage:
::
  
  # chkconfig --level 2345 centreon_vmware on

Installer la dépendance « perl-centreon-base »:
::

  # git clone -b 2.6.x --single-branch https://github.com/centreon/centreon.git centreon
  # cd centreon
  # cp lib/perl/centreon/script.pm /usr/lib/perl5/vendor_perl/5.8.8/centreon/
  # cp -R lib/perl/centreon/common /usr/lib/perl5/vendor_perl/5.8.8/centreon/
  
Installer le client et les dépendances:
::

  # git clone http://git.centreon.com/centreon-plugins.git
  # cd centreon-plugins
  # cp -R centreon/plugins /usr/lib/perl5/vendor_perl/5.8.8/centreon/
  # mkdir -p /usr/lib/nagios/plugins/centreon/plugins/
  # cp centreon/plugins/* /usr/lib/nagios/plugins/centreon/plugins/
  # mkdir -p /usr/lib/nagios/plugins/apps/vmware/
  # cp -R apps/vmware/* /usr/lib/nagios/plugins/apps/vmware/
  # cp centreon_plugins.pl /usr/lib/nagios/plugins/

Installation de centreon-vmware - Environnement centos/rhel 6
=============================================================

Installation du SDK Perl VMWare
```````````````````````````````

Le connecteur « centreon-vmware » utilise le SDK Perl VMWare pour son fonctionnement. Nous allons donc l'installer en suivant les versions recommandées par VMWare (en dehors de ces versions, le fonctionnement n'est pas garanti).

======================= ===================== ======================
Dépendance               Version               Dépôt
======================= ===================== ======================
perl-libwww-perl             5.833            redhat/centos base
perl-XML-LibXML              1.70             redhat/centos base
perl-Class-MethodMaker       2.16             redhat/centos base
perl-Crypt-SSLeay            0.57             redhat/centos base
perl-SOAP-Lite               0.710.10         redhat/centos base
perl-UUID                    0.04             ces standard
perl-VMware-vSphere          5.1.0-780721.1   ces standard
======================= ===================== ======================

Installer la dépendance suivante:
::

  # yum install perl-VMware-vSphere

Pré-requis
``````````

Les dépendances suivantes sont nécessaires pour le fonctionnement de « centreon_vmware »:

* « perl-centreon-base » :  module est présent à partir de Centreon 2.5 (dépôt ces standard)
* « centreon-plugins-base » : présent dans le dépôt ces standard
* « zeromq » et le binding Perl : présent dans le dépôt ces standard ou EPEL

Les dépendances suivantes sont optionnelles pour le fonctionnement de « centreon_vmware »:

*  « perl-TimeDate »: dépôt redhat/centos base

Installation de centreon-vmware par rpm
```````````````````````````````````````

Installer le connecteur:
::

  # yum install ces-plugins-Virtualization-VMWare-daemon

Installer le client:
::

  # yum install ces-plugins-Virtualization-VMWare-client

Installation de centreon-vmware par les sources
```````````````````````````````````````````````

Télécharger l'archive de « centreon-vmware ».

Installer le connecteur:
::

  # tar zxvf centreon-vmware-2.0.0.tar.gz
  # cd centreon-vmware-2.0.0
  # cp centreon_vmware.pl /usr/bin/
  
  # mkdir -p /etc/centreon
  # cp contrib/config/centreon_vmware-conf.pm /etc/centreon/centreon_vmware.pm
  # cp contrib/redhat/centreon_vmware-init /etc/init.d/centreon_vmware
  # cp contrib/redhat/centreon_vmware-sysconfig /etc/sysconfig/centreon_vmware
  # chmod 775 /etc/init.d/centreon_vmware /usr/bin/centreon_vmware.pl
  
  # mkdir -p /usr/share/perl5/vendor_perl/centreon/vmware/ /usr/share/perl5/vendor_perl/centreon/script/
  # cp centreon/vmware/* /usr/share/perl5/vendor_perl/centreon/vmware/
  # cp centreon/script/centreon_vmware.pm /usr/share/perl5/vendor_perl/centreon/script/

Activer le daemon « centreon-vmware » au démarrage:
::
  
  # chkconfig --level 2345 centreon_vmware on
  
Installer la dépendance « perl-centreon-base »:
::

  # git clone -b 2.6.x --single-branch https://github.com/centreon/centreon.git centreon
  # cd centreon
  # cp lib/perl/centreon/script.pm /usr/share/perl5/vendor_perl/centreon/
  # cp -R lib/perl/centreon/common /usr/share/perl5/vendor_perl/centreon/
  
Installer le client et les dépendances:
::

  # git clone http://git.centreon.com/centreon-plugins.git
  # cd centreon-plugins
  # cp -R centreon/plugins /usr/share/perl5/vendor_perl/centreon/
  # mkdir -p /usr/lib/nagios/plugins/centreon/plugins/
  # cp centreon/plugins/* /usr/lib/nagios/plugins/centreon/plugins/
  # mkdir -p /usr/lib/nagios/plugins/apps/vmware/
  # cp -R apps/vmware/* /usr/lib/nagios/plugins/apps/vmware/
  # cp centreon_plugins.pl /usr/lib/nagios/plugins/
