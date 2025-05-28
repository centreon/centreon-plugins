---
name: Other requests
about: For other requests such as questions or enhancement requests, take a look at this form.
title: ''
labels: ''
assignees: ''

---

Thank you for using Centreon plugins!

# Other requests

## Questions

If you have trouble using our plugins, but are not sure whether it's due to a bug or a misuse, please take the time to ask for help on [The Watch, Data Collection section](https://thewatch.centreon.com/data-collection-6) and become certain that it is a bug before submitting it here.

## New Plugins and modes

There is high demand for new plugins and new functionalities on existing plugins, so we have to rely on our community to help us prioritize them.
How? Post your suggestion on [The Watch Ideas](https://thewatch.centreon.com/ideas) with as much detail as possible and we will pick the most voted topics to add them to our product roadmap.

To develop a plugin/mode, we need the following information, depending on the protocol:
* **SNMP**: MIB files and full snmpwalk of enterprise branch (`snmpwalk -ObentU -v 2c -c public address .1.3.6.1.4.1 > equipment.snmpwalk`) or [SNMP collections](https://thewatch.centreon.com/product-how-to-21/snmp-collection-tutorial-132).
* **HTTP API (SOAP, Rest/Json, XML-RPC)**: the documentation and some curl examples or HTTP [collections](https://thewatch.centreon.com/data-collection-6/centreon-plugins-discover-collection-modes-131).
* **CLI**: command line examples (command + result).
* **SQL**: queries + results + column types or [SQL collections](https://thewatch.centreon.com/product-how-to-21/sql-collection-tutorial-134).
* **JMX**: mbean names and attributes.

If some information is confidential, such as logins or IP addresses, obfuscate them in what is sent publicly and we'll get in touch with you by private message if this information is needed.

Please note that all the developments are open source, we will not commit to a release date. If it is an emergency for you, please contact [Centreon's sales team](https://www.centreon.com/contact/).
