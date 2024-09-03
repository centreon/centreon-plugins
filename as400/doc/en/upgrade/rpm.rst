.. _rpm:

############################
Upgrading from package (RPM)
############################

Upgrade
*******

Stop the connector service::

  $ /etc/init.d/centreon-connector-as400 stop

Upgrade the rpm::

  $ yum update centreon-connector-as400-server ces-plugins-Operatingsystems-As400

Restart the connector service::

  $ /etc/init.d/centreon-connector-as400 start
