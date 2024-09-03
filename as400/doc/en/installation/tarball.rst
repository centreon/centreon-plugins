.. _tarball:

################################
Installing from tarball (tar.gz)
################################

Tarball installation is not recommended

Prerequisites
*************

To build Centreon-Connector-AS400 check plugin, you will need the following external dependencies:

a C++ compilation environment.
CMake (>= 2.8), a cross-platform build system.
the Qt (>= 4.7.4) framework with QtCore, and QtXml modules.
GnuTLS (>= 2.0), a secure communications library.

Installing daemon
*****************

Unzip tarball::

  $ cd /tmp/ && tar xvzf centreon-connector-as400-server-1.x.x.tar.gz 
  
 Start the installation::
 
  $ /tmp/centreon-connector-as400-server-1.x.x/install.sh
 
Installing check plugin
***********************

Check plugin must be compiled::

  $ cd /tmp/centreon-connector-as400-server-1.x.x/connector.plugins/
  $ cmake && make

Then copy the as400 check plugin to the nagios libexec folder ::

  $ cp /tmp/centreon-connector-as400-server-1.x.x/connector.plugins/as400_generic/check_centreon_as400 %nagios%/libexec/ 

