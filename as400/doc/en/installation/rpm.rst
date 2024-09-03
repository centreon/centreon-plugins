.. _rpm:

#############################
Installing from package (RPM)
#############################

Prerequisites
*************

A recent installation of CES with centreon-plugin-pack. 

Installation
************

Run the command::

  $ yum install centreon-connector-as400-server ces-plugins-Operatingsystems-As400 ces-pack-Operatingsystems-As400 

Then start the daemon::

  $ /etc/init.d/centreon-connector-as400 start