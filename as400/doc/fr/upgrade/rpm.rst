.. _rpm:

######################################
Mise à jour à partir des package (RPM)
######################################

Mise à jour
***********

Arrêter service du connecteur::

  $ /etc/init.d/centreon-connector-as400 stop

Mettre à jour les rpm::

  $ yum update centreon-connector-as400-server ces-plugins-Operatingsystems-As400

Redémarrer le service du connecteur::

  $ /etc/init.d/centreon-connector-as400 start
