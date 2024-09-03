.. _rpm:

##########
Pré-requis
##########

+-----------+-----------------+
| Logiciels | Version minimum |
+-----------+-----------------+
| Centreon  | 2.2.x           |
+-----------+-----------------+
| Nagios    | 3.x             |
+-----------+-----------------+
| Java      | JRE 6 Oracle    |
+-----------+-----------------+
| AS/400    | V4R5\+          |
+-----------+-----------------+

Préconisations matérielles
**************************

Il est nécessaire d'évaluer les ressources matérielles nécessaires avant d'installer Centreon-Connector-AS400 sur un serveur.

- **mémoire vive** : 512 Mo minimum (Peut sensiblement augmenter en fonction du nombre de contrôle).

  - Compter 2 Go pour 2500 services avec un intervalle de 10 minutes entre chaque contrôle.

- **CPU** : même pré-requis que pour le serveur de collecte


List des ports utilisés
***********************

+-----------+-------------+--------------------------+------------------+
| Source    | Destination | Port                     | Peut être changé |
+-----------+-------------+--------------------------+------------------+
| Plugin    | Connector   | Non défini               | Oui              |
+-----------+-------------+--------------------------+------------------+


Liste des ports entre le connecteur et l'AS400
----------------------------------------------

+----------+------+
| Standard | SSL  | 
+----------+------+
| 446      | 448  |
+----------+------+
| 449      |      |
+----------+------+
| 8470     | 9470 |
+----------+------+
| 8471     | 9471 |
+----------+------+
| 8472     | 9472 |
+----------+------+
| 8473     | 9473 |
+----------+------+
| 8474     | 9474 |
+----------+------+
| 8475     | 9475 |
+----------+------+
| 8476     | 9476 |
+----------+------+


Une liste complète des ports utilisés par l'AS400 peut être trouvée `sur cette page <http://www-03.ibm.com/systems/power/software/i/toolbox/faq/ports.html>`_.
