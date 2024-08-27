# centreon-plugins

[![License](https://img.shields.io/badge/License-APACHE2-brightgreen.svg)](https://github.com/centreon/centreon-plugins/blob/master/LICENSE.txt)

<!-- SHIELDS -->
[![Contributors][contributors-shield]][contributors-url]
[![Stars][stars-shield]][stars-url]
[![Forks][forks-shield]][forks-url]
[![Issues][issues-shield]][issues-url]

## What are Centreon Plugins

[Centreon plugins](https://github.com/centreon/centreon-plugins/) is a free and open source project to monitor systems. The project can be used with Centreon and all monitoring softwares compatible with Nagios plugins.

### Principles

[Centreon plugins](https://github.com/centreon/centreon-plugins/) should comply with [Monitoring Plugins Development Guidelines](https://www.monitoring-plugins.org/doc/guidelines.html).

In short, they return:
- An error code:
    - `0` for `OK`
    - `1` for `WARNING`
    - `2` for `CRITICAL`
    - `3` for `UNKNOWN`
- A human understandable output message (example: `OK: CPU(s) average usage is 2.66 % - CPU '0' usage : 2.66 %`).
- A set of metrics provided as *perfdata* after a `|` character (example: `'cpu.utilization.percentage'=2.66%;;;0;100 '0#core.cpu.utilization.percentage'=2.66%;;;0;100`).

### What can Centreon Plugins monitor?

You can monitor many systems:
* **Application**: Apache, Asterisk, Elasticsearch, Github, Jenkins, Kafka, Nginx, Pfsense, Redis, Tomcat, Varnish, etc.
* **Cloud**: AWS, Azure, Docker, Office365, Nutanix, Prometheus, etc.
* **Databases**: Firebird, Informix, MS SQL, MySQL, Oracle, Postgres, Cassandra.
* **Hardware**: printers (RFC3805), UPS (Powerware, Mge, Standard), Sun Hardware, Cisco UCS, SensorIP, HP Proliant, HP Bladechassis, Dell Openmanage, Dell CMC, Raritan, etc.
* **Network**: Aruba, Brocade, Bluecoat, Brocade, Checkpoint, Cisco AP/IronPort/ASA/Standard, Extreme, Fortigate, H3C, Hirschmann, HP Procurve, F5 BIG-IP, Juniper, PaloAlto, Redback, Riverbed, Ruggedcom, Stonesoft, etc.
* **Operating systems**: Linux (SNMP, NRPE), Freebsd (SNMP), AIX (SNMP), Solaris (SNMP), etc.
* **Storage**: EMC Clariion, Netapp, Nimble, HP MSA p2000, Dell EqualLogic, Qnap, Panzura, Synology, etc.

To get a complete list, run:

```bash
perl src/centreon_plugins.pl --list-plugin
```

### Basic Usage

We'll use a basic example to show you how to monitor a system. I have finished the install section and I want to monitor a Linux in SNMP.
First, I need to find the plugin to use in the list:

```bash
perl centreon_plugins.pl --list-plugin | grep -i linux | grep 'PLUGIN'
```

It will return:

```
PLUGIN: os::linux::local::plugin
PLUGIN: os::linux::snmp::plugin
```

It seems that 'os::linux::snmp::plugin' is the good one. So I verify with the option ``--help`` to be sure:

    $ perl centreon_plugins.pl --plugin=os::linux::snmp::plugin --help
    ...
    Plugin Description:
      Check Linux operating systems in SNMP.

It's exactly what I need. Now I'll add the option ``--list-mode`` to know what can I do with it:

    $ perl centreon_plugins.pl --plugin=os::linux::snmp::plugin --list-mode
    ...
    Modes Available:
     processcount
     time
     list-storages
     disk-usage
     diskio
     uptime
     swap
     cpu-detailed
     load
     traffic
     cpu
     inodes
     list-diskspath
     list-interfaces
     packet-errors
     memory
     tcpcon
     storage

I would like to test the 'load' mode:

    $ perl centreon_plugins.pl --plugin=os::linux::snmp::plugin --mode=load
    UNKNOWN: Missing parameter --hostname.

It's not working because some options are missing. I can have a description of the mode and options with the option ``--help``:

    $ perl centreon_plugins.pl --plugin=os::linux::snmp::plugin --mode=load --help

Eventually, I have to configure some SNMP options:

    $ perl centreon_plugins.pl --plugin=os::linux::snmp::plugin --mode=load --hostname=127.0.0.1 --snmp-version=2c --snmp-community=public
    OK: Load average: 0.00, 0.00, 0.00 | 'load1'=0.00;;;0; 'load5'=0.00;;;0; 'load15'=0.00;;;0;

I can set threshold with options ``--warning`` and ``--critical``:

    $ perl centreon_plugins.pl --plugin=os::linux::snmp::plugin --mode=load --hostname=127.0.0.1 --snmp-version=2c --snmp-community=public --warning=1,2,3 --critical=2,3,4
    OK: Load average: 0.00, 0.00, 0.00 | 'load1'=0.00;0:1;0:2;0; 'load5'=0.00;0:2;0:3;0; 'load15'=0.00;0:3;0:4;0;

For more information or help, please read ['doc/en/user/guide.rst'](./doc/en/user/guide.rst).

## Contributions

### Code contributions/pull requests

If you want to contribute by submitting new functionalities, enhancements or bug fixes, first thank you for participating :-)
Then have a look, if not already done, to our **[development guide](https://github.com/centreon/centreon-plugins/blob/develop/doc/en/developer/guide.md)**.
Then create a [fork](https://github.com/centreon/centreon-plugins/fork) and a development branch, and once it's done, you may submit a [pull request](https://github.com/centreon/centreon-plugins/pulls) that the corporate development team will examine.

### Issues/bug reports

If you encounter a behaviour that is clearly a bug or a regression, you are welcome to submit an [issue](https://github.com/centreon/centreon-plugins/issues). Please be aware that this is an open source project and that there is no guaranteed response time.

### Questions/search for help

If you have trouble using our plugins, but are not sure whether it's due to a bug or a misuse, please take the time to ask for help on [The Watch, Data Collection section](https://thewatch.centreon.com/data-collection-6) and become certain that it is a bug before submitting it here.

### Feature/enhancement request

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

### Continuous integration

Please follow documentation [here](./doc/CI.md)

<!-- URL AND IMAGES FOR SHIELDS -->
[contributors-shield]: https://img.shields.io/github/contributors/centreon/centreon-plugins?color=%2384BD00&label=CONTRIBUTORS&style=for-the-badge
[stars-shield]: https://img.shields.io/github/stars/centreon/centreon-plugins?color=%23433b02a&label=STARS&style=for-the-badge
[forks-shield]: https://img.shields.io/github/forks/centreon/centreon-plugins?color=%23009fdf&label=FORKS&style=for-the-badge
[issues-shield]: https://img.shields.io/github/issues/centreon/centreon-plugins?color=%230072ce&label=ISSUES&style=for-the-badge

[contributors-url]: https://github.com/centreon/centreon-plugins/graphs/contributors
[forks-url]: https://github.com/centreon/centreon-plugins/network/members
[stars-url]: https://github.com/centreon/centreon-plugins/stargazers
[issues-url]: https://github.com/centreon/centreon-plugins/issues
