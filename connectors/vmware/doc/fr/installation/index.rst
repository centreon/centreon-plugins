============
Installation
============

Pré-Requis
==========

Préconisations logicielles
``````````````````````````

Le connecteur "centreon-esxd" est testé et validé sur red-hat 5 et 6 avec des rpms. 
L'installation sur d'autres environnements n'est pas exclu mais non présenté dans ce document (Debian, ...).

==================== =====================
Logiciels             Version
==================== =====================
VMWare SDK Perl          5.1.0-780721
Perl                     5.8
centreon-esxd            1.5.4
perl-centreon-base       2.5.0
==================== =====================

.. warning::
    Le connecteur "centreon-esxd" fourni par Merethis est conçu pour fonctionner Centreon 2.5 (CES 2.2 ou CES 3), il ne fonctionne pas avec Centreon 2.4.

Préconisations matérielles
``````````````````````````

Le matériel nécessaire dépend du nombre de demandes de vérifications. Par défaut, le connecteur n'effectue aucunes vérifications. Les ressources minimales sont de :

* mémoire vive : 512 Mo minimum (Peut sensiblement augmenter en fonction du nombre de contrôle).
* CPU : même pré-requis que pour le serveur de collecte.

Installation de centreon-esxd - Environnement centos/rhel 5
===========================================================

Installation du SDK Perl VMWare
```````````````````````````````

Le connecteur « centreon-esxd » utilise le SDK Perl VMWare pour son fonctionnement. Nous allons donc l'installer en suivant les versions recommandées par VMWare (en dehors de ces versions, le fonctionnement n'est pas garanti).

======================= ===================== ======================
Dépendance               Version               Dépôt
======================= ===================== ======================
perl-libwww-perl             5.805            redhat/centos base
perl-XML-LibXML              1.58             redhat/centos base
perl-Class-MethodMaker       2.18             ces base
perl-Crypt-SSLeay            0.51             redhat/centos base
perl-SOAP-Lite               0.712            ces base
perl-UUID                    0.04             ces base
perl-VMware-vSphere          5.1.0-780721.1   centreon plugin-packs
======================= ===================== ======================

Installer la dépendance suivante::

  root # yum install perl-VMware-vSphere

Pré-requis
```````````````````````````````````````

« perl-centreon-base » est nécessaire pour le fonctionnement de « centreon_esxd ». Ce module est présent à partir de Centreon 2.5.

Installation de centreon-esxd par rpm
`````````````````````````````````````

Installer le connecteur::

  root # yum install ces-plugins-Virtualization-VMWare

Installation de centreon-esxd par les sources
`````````````````````````````````````````````

Télécharger l'archive de « centreon-esxd ».

Installer les fichiers::
  
  root # tar zxvf centreon-esxd-1.5.4.tar.gz
  root # cd centreon-esxd-1.5.4
  root # cp centreon_esxd /usr/bin/
  
  root # mkdir -p /etc/centreon
  root # cp centreon_esxd-conf.pm /etc/centreon/centreon_esxd.pm
  root # cp centreon_esxd-init /etc/init.d/centreon_esxd
  
  root # mkdir -p /usr/share/perl5/vendor_perl/centreon/esxd/
  root # cp lib/* /usr/share/perl5/vendor_perl/centreon/esxd/
  root # cp centreonesxd.pm /usr/share/perl5/vendor_perl/centreon/script/

Activer le daemon « centreon-esxd » au démarrage::
  
  root # chkconfig --level 2345 centreon_esxd on

*Le plugin « nagios » correspond au fichier « centreon_esx_client.pl ».*

Installation de centreon-esxd - Environnement centos/rhel 6
===========================================================

Installation du SDK Perl VMWare
```````````````````````````````

Le connecteur « centreon-esxd » utilise le SDK Perl VMWare pour son fonctionnement. Nous allons donc l'installer en suivant les versions recommandées par VMWare (en dehors de ces versions, le fonctionnement n'est pas garanti).

======================= ===================== ======================
Dépendance               Version               Dépôt
======================= ===================== ======================
perl-libwww-perl             5.833            redhat/centos base
perl-XML-LibXML              1.70             redhat/centos base
perl-Class-MethodMaker       2.16             redhat/centos base
perl-Crypt-SSLeay            0.57             redhat/centos base
perl-SOAP-Lite               0.710.10         redhat/centos base
perl-UUID                    0.04             centreon plugin-packs
perl-VMware-vSphere          5.1.0-780721.1   centreon plugin-packs
======================= ===================== ======================

Installer la dépendance suivante::

  root # yum install perl-VMware-vSphere

Pré-requis
```````````````````````````````````````

« perl-centreon-base » est nécessaire pour le fonctionnement de « centreon_esxd ». Ce module est présent à partir de Centreon 2.5.

Installation de centreon-esxd par rpm
`````````````````````````````````````

Installer le connecteur::

  root # yum install ces-plugins-Virtualization-VMWare

Installation de centreon-esxd par les sources
`````````````````````````````````````````````

Télécharger l'archive de « centreon-esxd ».

Installer les fichiers::
  
  root # tar zxvf centreon-esxd-1.5.4.tar.gz
  root # cd centreon-esxd-1.5.4
  root # cp centreon_esxd /usr/bin/
  
  root # mkdir -p /etc/centreon
  root # cp centreon_esxd-conf.pm /etc/centreon/centreon_esxd.pm
  root # cp centreon_esxd-init /etc/init.d/centreon_esxd
  
  root # mkdir -p /usr/share/perl5/vendor_perl/centreon/esxd/
  root # cp lib/* /usr/share/perl5/vendor_perl/centreon/esxd/
  root # cp centreonesxd.pm /usr/share/perl5/vendor_perl/centreon/script/

Activer le daemon « centreon-esxd » au démarrage::
  
  root # chkconfig --level 2345 centreon_esxd on

*Le plugin « nagios » correspond au fichier « centreon_esx_client.pl ».*


