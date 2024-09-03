.. _tarball:

#######################################
Installation depuis le tarball (tar.gz)
#######################################

L'installation par tarball est déconseillé.

Pré-Requis
**********

To build Centreon-Connector-AS400 check plugin, you will need the following external dependencies:

a C++ compilation environment.
CMake (>= 2.8), a cross-platform build system.
the Qt (>= 4.7.4) framework with QtCore, and QtXml modules.
GnuTLS (>= 2.0), a secure communications library.

Installation du daemon
**********************

Décompresser l'archive::

  $ cd /tmp/ && tar xvzf centreon-connector-as400-server-1.x.x.tar.gz 
  
 Lancez l'instalation::
 
  $ /tmp/centreon-connector-as400-server-1.x.x/install.sh
 
Installation des sondes
***********************

Les sondes doivent etre compilées::

  $ cd /tmp/centreon-connector-as400-server-1.x.x/connector.plugins/
  $ cmake && make

Copiez ensuite la sonde as400 vers le dossier libexec nagios::

  $ cp /tmp/centreon-connector-as400-server-1.x.x/connector.plugins/as400_generic/check_centreon_as400 %nagios%/libexec/ 

