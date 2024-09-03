.. _rpm:

#############################
Installation du package (RPM)
#############################

Pré-Requis
**********

Une installation recente de CES avec centreon-plugin-pack.

Installation
************

Lancez la commande::

  $ yum install centreon-connector-as400-server ces-plugins-Operatingsystems-As400 ces-pack-Operatingsystems-As400 

Puis démarrez le daemon::

  $ /etc/init.d/centreon-connector-as400 start