.. _rpm:

#############
Prerequisites
#############

+----------+--------------+-+
| Software | Minimum      | |
+----------+--------------+-+
| Centreon | 2.2.x        | |
+----------+--------------+-+
| Nagios   | 3.x          | |
+----------+--------------+-+
| Java     | JRE 6 Oracle | |
+----------+--------------+-+
| AS/400   | V4R5\+       | |
+----------+--------------+-+

Hardware recommendations
************************

It is necessary to evaluate material resources before installing Centreon-Connector-AS400 on a server. 

- ** ** RAM: 512 MB ​​minimum (may increase significantly with the number of control). 

   - Count 2 GB for 2500 services with a 10 minute interval between each control. 

- ** CPU **: prerequisite identical to the collection server

List of used ports
******************

+-----------+-----------+--------------------------+----------------+
| Source    | Target    | Port                     | Can be changed |
+-----------+-----------+--------------------------+----------------+
| Plugin    | Connector | Custom                   | Yes            |
+-----------+-----------+--------------------------+----------------+

List of ports between the connector and the AS400
-------------------------------------------------

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

A detailed list of the ports used by the AS400 can be found `on this page <http://www-03.ibm.com/systems/power/software/i/toolbox/faq/ports.html>`_.
