
Please follow the indications shown below according to your issue and describe it in English.
If some parts of the information are confidentials, please send them directly by email to qgarnier@centreon.com and sbomm@centreon.com

## Bug/Question

If you are reporting a bug/question, make sure that there aren't any similar/duplicates issues already open. You 
can ensure this by searching the issue list for this repository. If so, please 
close your issue and add a comment to the existing one instead.

Otherwise, open your issue and provide all parts of information you can (full command line used, actual output, expected output...)

## New plugins and modes

To develop a plugin/mode, we need the following:
* SNMP: MIBs files and full snmpwalk of entreprise branch (snmpwalk -ObentU -v 2c -c public address .1.3.6.1.4.1 > equipment.snmpwalk)
* HTTP API (SOAP, Rest/Json, XML-RPC): the documentation and some curls examples
* CLI: command line examples
* SQL: requests
* JMX: mbean names and attributes

If you aren't able to provide any of the mandatory details requested, we'll close the ticket. The issue can be reopened if more information is provided.
All developments are open-source. We can't give a date for the development. If it's a priority for you, please send us an email about it (qgarnier@centreon.com and sbomm@centreon.com) and we'll put you in touch with our company. 

Thanks for using centreon-plugins!
