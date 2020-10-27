Thanks for using centreon-plugins! Please follow the indications shown below according to your issue and describe it in English.

## New Plugins and modes

To develop a Plugin/mode, we need the following:
* SNMP: MIBs files and full snmpwalk of entreprise branch (snmpwalk -ObentU -v 2c -c public address .1.3.6.1.4.1 > equipment.snmpwalk)
* HTTP API (SOAP, Rest/Json, XML-RPC): the documentation and some curls examples
* CLI: command line examples
* SQL: requests
* JMX: mbean names and attributes

If some parts of information are confidentials, please send them directly by email to qgarnier@centreon.com and sbomm@centreon.com.

Please note that all the developments are open-source. We can't give a date for the development, achievement or release. If it's a priority for you,
send us an email about it (qgarnier@centreon.com and sbomm@centreon.com) and we'll put you in touch with our company.


## Bug/Question

If you are reporting a bug/question, make sure that there aren't any similar/duplicates issues already open. You 
can ensure this by searching the issue list for this repository. If so, please close your issue and add a comment to the existing one instead.

Otherwise, open a new issue and provide all parts of information you can (full command line used, actual output, expected output, error message...).
