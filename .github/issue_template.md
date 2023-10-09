Thank you for using Centreon plugins!

Please use this form only for actual **bugs** only. See **[Other requests](#other-requests)** for more details.

# Bug report

If you are certain it's a bug, please ensure that there aren't any [similar issues already open](https://github.com/centreon/centreon-plugins/issues) on the same bug. 
If the same bug has already been logged, please close your issue and add a comment to the existing one instead.

**For the sake of clarity, please remove the explanations from the issue template before submitting your issue.**

## Quick description

*In one or two sentences, what it your bug about?*

## How to reproduce

*Please provide below the initial conditions to reproduce the bug*

- **Environment**: result of `uname -a ; cat /etc/redhat-release /etc/debian_version`.
- **Version of the plugin**: version of the package or last commit date if using a clone of this repository.
- **Information about the monitored resource**: the exact model and version of the device, software or product you are trying to monitor.
- **Command line**: the command line that is used.

## Expected result

*What you were expecting to have as a result (output, exit return).*

## Actual result

*What you actually got. Please put emphasis on what seems wrong to you.*

# Other requests

## Questions

If you have trouble using our plugins, but are not sure whether it's a bug or a misuse, please take the time to ask for help on [The Watch Data Collection section](https://thewatch.centreon.com/data-collection-6) and become certain that it's a bug before submitting it here.

## New Plugins and modes

There is high demand for new plugins and new functionalities on existing plugins, so we have to rely on our community to help us prioritize them.
How? Post your suggestion on [The Watch Ideas](https://thewatch.centreon.com/ideas) with as much details as possible and we'll pick the most voted topics to add them to our product roadmap.

To develop a Plugin/mode, we need the following information depending on the protocol:
* **SNMP**: MIBs files and full snmpwalk of enterprise branch (`snmpwalk -ObentU -v 2c -c public address .1.3.6.1.4.1 > equipment.snmpwalk`) or [SNMP collections](https://thewatch.centreon.com/product-how-to-21/snmp-collection-tutorial-132).
* **HTTP API (SOAP, Rest/Json, XML-RPC)**: the documentation and some curls examples or HTTP [collections](https://thewatch.centreon.com/data-collection-6/centreon-plugins-discover-collection-modes-131).
* **CLI**: command line examples (command + result).
* **SQL**: queries + results + column types or [SQL collections](https://thewatch.centreon.com/product-how-to-21/sql-collection-tutorial-134).
* **JMX**: mbean names and attributes.

If some information are confidential, such as logins, IP addresses, obfuscate them in what is sent publicly and we'll get in touch with you by private message if these information are needed..

Please note that all the developments are open-source, we won't commit on a release date. If it's an emergency for you, please contact [Centreon's sales team](https://www.centreon.com/contact/).

