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
VMWare SDK Perl              5.0
Perl    		     5.8
centreon-esxd                1.3
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

Nous avons notre environnement prêt pour l'installation du SDK VMWare.

Télécharger la dernière version, correspondant à votre architecture 32/64 bits, sur le site officiel de VMWare (`SDK VMWare <http://www.vmware.com/support/developer/viperltoolkit/>`_).

Installer le SDK Perl VMWare::
 
  root # tar zxvf VMware-vSphere-Perl-SDK-5.1.0-780721.x86_64.tar.gz
  root # cd vmware-vsphere-cli-distrib
  root # perl Makefile.pl
  root # make && make install

Installation de modules complémentaires
```````````````````````````````````````

Certains modules complémentaires Perl peuvent être installés si vous souhaitez utiliser certaines fonctionnalités du centreon_esxd : 

Pour envoyer les logs au daemon « syslog », il est nécessaire d'installer le module « Unix::Syslog »::
  
  root # cpan install Unix::Syslog

Pour vérifier la date des snapshots d'une machine virtuelle, il est nécessaire d'installer le module « DateTime::Format::ISO8601 » ( **ce module installe beaucoup de modules CPAN et est difficilement installable sans mettre à jour globalement « Perl ». Cette mise à jour est très risqué** )::

  root # cpan install DateTime  
  root # cpan install DateTime::Format::ISO8601
  root # o conf make /usr/bin/make
  root # o conf commit

Ensuite redémarrer votre système. 

Installation de centreon-esxd
`````````````````````````````

Télécharger l'archive de « centreon-esxd ».

Installer les fichiers::
  
  root # tar zxvf centreon-esxd-1.X.tar.gz
  root # cd centreon-esxd-1.X
  root # cp centreon_esxd /usr/bin/
  
  root # mkdir -p /etc/centreon
  root # cp centreon_esxd-conf.pm /etc/centreon/centreon_esxd.pm
  root # cp centreon_esxd-init /etc/init.d/centreon_esxd
  
  root # mkdir -p /usr/share/centreon/lib/centreon-esxd
  root # cp lib/* /usr/share/centreon/lib/centreon-esxd/

Activer le daemon « centreon-esxd » au démarrage::
  
  root # chkconfig --level 2345 centreon_esxd on


*Le plugin « nagios » correspond au fichier « centreon_esx_client.pl ».*

Installation de centreon-esxd - Environnement centos/rhel 6
===========================================================

Installation du sdk Perl VMWare
```````````````````````````````

Le connecteur « centreon-esxd » utilise le SDK Perl VMWare pour son fonctionnement.

Le connecteur « centreon-esxd » utilise le SDK Perl VMWare pour son fonctionnement. Nous allons donc l'installer. Pour cela nous allons commencer par installer CPAN qui est le nom d'un module Perl qui rend aisés le téléchargement, l'installation, la mise à jour et la maintenance des autres modules Perl qui sont archivés sur le CPAN.

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

Nous avons notre environnement prêt pour l'installation du SDK VMWare.

Télécharger la dernière version, correspondant à votre architecture 32/64 bits, sur le site officiel de VMWare (`SDK VMWare <http://www.vmware.com/support/developer/viperltoolkit/>`_)

Installer le SDK Perl VMWare::

  root # tar zxvf VMware-vSphere-Perl-SDK-5.1.0-780721.x86_64.tar.gz
  root # cd vmware-vsphere-cli-distrib
  root # perl Makefile.pl
  root # make && make install

Installation de modules complémentaires
```````````````````````````````````````

Certains modules complémentaires Perl peuvent être installés si vous souhaitez utiliser certaines fonctionnalités du centreon_esxd :

Pour envoyer les logs au daemon « syslog », il est nécessaire d'installer le module « Unix::Syslog »::
  
  root # cpan install Unix::Syslog

Pour vérifier la date des snapshots d'une machine virtuelle, il est nécessaire d'installer le module « DateTime::Format::ISO8601 » ( **ce module installe beaucoup de modules CPAN et est difficilement installable sans mettre à jour globalement « Perl ». Cette mise à jour est très risqué** )::

  root # cpan install DateTime
  root # cpan install DateTime::Format::ISO8601
  root # o conf make /usr/bin/make
  root # o conf commit

Ensuite redémarrer votre système.

Installation de centreon-esxd
`````````````````````````````

Télécharger l'archive de « centreon-esxd ».

Installer les fichiers::
  
  root # tar zxvf centreon-esxd-1.X.tar.gz
  root # cd centreon-esxd-1.X
  root # cp centreon_esxd /usr/bin/
  
  root # mkdir -p /etc/centreon
  root # cp centreon_esxd-conf.pm /etc/centreon/centreon_esxd.pm
  root # cp centreon_esxd-init /etc/init.d/centreon_esxd
  
  root # mkdir -p /usr/share/centreon/lib/centreon-esxd
  root # cp lib/* /usr/share/centreon/lib/centreon-esxd/

Activer le daemon « centreon-esxd » au démarrage::
  
  root # chkconfig --level 2345 centreon_esxd on


*Le plugin « nagios » correspond au fichier « centreon_esx_client.pl ».*


