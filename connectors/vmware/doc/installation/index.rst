============
Installation
============

Pré-Requis
==========

Préconisations logicielles
``````````````````````````

Le connecteur "centreon-esxd" est testé et validé sur des environnements Linux. 
L'installation sur d'autres environnements n'est pas exclu mais non présenté dans ce document (Solaris, Windows, ...).

====================    =====================
Logiciels               Version minimum
====================    =====================
VMWare SDK Perl              5.1
Perl    		    		 5.8
centreon-esxd                1.4
centreon-common-perl         2.5
====================    =====================

Préconisations matérielles
``````````````````````````

Le matériel nécessaire dépend du nombre de demandes de vérifications. Par défaut, le connecteur n'effectue aucunes vérifications. Les ressources minimales sont de :

* mémoire vive : 512 Mo minimum (Peut sensiblement augmenter en fonction du nombre de contrôle).

* CPU : même pré-requis que pour le serveur de collecte.

Installation de centreon-esxd - Environnement centos/rhel 5
===========================================================

Installation du SDK Perl VMWare
```````````````````````````````

Le connecteur « centreon-esxd » utilise le SDK Perl VMWare pour son fonctionnement. Nous allons donc l'installer. Pour cela nous allons commencer par installer CPAN qui est le nom d'un module Perl qui rend aisés le téléchargement, l'installation, la mise à jour et la maintenance des autres modules Perl qui sont archivés sur le CPAN.

Installer les pré-requis CPAN::

  root # yum install gcc make unzip wget e2fsprogs-devel
  root # yum install perl-XML-LibXML perl-Crypt-SSLeay perl-libwww-perl perl-TimeDate
  
  root # cpan install Class::MethodMaker
  root # cpan install SOAP::Lite
  
  root # wget http://search.cpan.org/CPAN/authors/id/J/JN/JNH/UUID-0.04.tar.gz
  root # tar zxvf UUID-0.04.tar.gz
  root # cd UUID-0.04
  root # perl Makefile.PL
  root # make && make install

Nous avons notre environnement prêt pour l'installation du SDK VMWare.

Télécharger la dernière version, correspondant à votre architecture 32/64 bits, sur le site officiel de VMWare (`SDK VMWare <http://www.vmware.com/support/developer/viperltoolkit/>`_).

Installer le SDK Perl VMWare::
 
  root # tar zxvf VMware-vSphere-Perl-SDK-5.1.0-780721.x86_64.gz
  root # cd vmware-vsphere-cli-distrib
  root # perl Makefile.pl
  root # make && make install

Pré-requis
```````````````````````````````````````

« centreon-common-perl » est nécessaire pour le fonctionnement de « centreon_esxd ». Ce module est présent à partir de Centreon 2.5.

Installation de centreon-esxd
`````````````````````````````

Télécharger l'archive de « centreon-esxd ».

Installer les fichiers::
  
  root # tar zxvf centreon-esxd-1.4.tar.gz
  root # cd centreon-esxd-1.4
  root # cp centreon_esxd /usr/bin/
  
  root # mkdir -p /etc/centreon
  root # cp centreon_esxd-conf.pm /etc/centreon/centreon_esxd.pm
  root # cp centreon_esxd-init /etc/init.d/centreon_esxd
  
  root # mkdir -p /usr/lib/perl5/vendor_perl/5.8.8/centreon/esxd/
  root # cp lib/* /usr/lib/perl5/vendor_perl/5.8.8/centreon/esxd/
  root # cp centreonesxd.pm /usr/lib/perl5/vendor_perl/5.8.8/centreon/script/

Activer le daemon « centreon-esxd » au démarrage::
  
  root # chkconfig --level 2345 centreon_esxd on


*Le plugin « nagios » correspond au fichier « centreon_esx_client.pl ».*

Installation de centreon-esxd - Environnement centos/rhel 6
===========================================================

Installation du sdk Perl VMWare
```````````````````````````````

TODO


