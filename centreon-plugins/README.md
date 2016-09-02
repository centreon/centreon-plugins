# centreon-plugins

“centreon-plugins” is a free and open source project to monitor systems. The project can be used with Centreon and all monitoring softwares compatible with Nagios plugins.

You can monitor many systems:
* application: Apache, Asterisk, Elasticsearch, Github, Jenkins, Nginx, Pfsense, Tomcat, Varnish,...
* cloud: Docker
* database: Firebird, Informix, MS SQL, MySQL, Oracle, Postgres
* hardware: printers (rfc3805), UPS (Powerware, Mge, Standard), Sun Hardware, Cisco UCS, SensorIP, HP Proliant, HP Bladechassis, Dell Openmanage, Dell CMC, Raritan,...
* network: Aruba, Brocade, Bluecoat, Brocade, Checkpoint, Cisco AP/IronPort/ASA/Standard, Extreme, Fortigate, H3C, Hirschmann, HP Procurve, F5 BIG-IP, Juniper, PaloAlto, Redback, Riverbed, Ruggedcom, Stonesoft,...
* os: Linux (SNMP, NRPE), Freebsd (SNMP), AIX (SNMP), Solaris (SNMP)...
* storage: EMC Clariion, Netapp, Nimble, HP MSA p2000, Dell EqualLogic, Qnap, Panzura, Synology...

## Basic Usage

We'll use a basic example to show you how to monitor a system. I have finished the install section and i want to monitor a Linux in SNMP.
First, i need to find the plugin to use in the list:

    $ perl centreon_plugins.pl --list-plugin | grep -i linux | grep 'PLUGIN'
    PLUGIN: os::linux::local::plugin
    PLUGIN: os::linux::snmp::plugin

It seems that 'os::linux::snmp::plugin' is the good one. So i verify with the option ``--help`` to be sure:

    $ perl centreon_plugins.pl --plugin=os::linux::snmp::plugin --help
    ...
    Plugin Description:
      Check Linux operating systems in SNMP.

It's exactly what i need. Now i'll add the option ``--list-mode`` to know what can i do with it:

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

Eventually, i have to configure some SNMP options:

    $ perl centreon_plugins.pl --plugin=os::linux::snmp::plugin --mode=load --hostname=127.0.0.1 --snmp-version=2c --snmp-community=public
    OK: Load average: 0.00, 0.00, 0.00 | 'load1'=0.00;;;0; 'load5'=0.00;;;0; 'load15'=0.00;;;0;

I can set threshold with options ``--warning`` and ``--critical``:

    $ perl centreon_plugins.pl --plugin=os::linux::snmp::plugin --mode=load --hostname=127.0.0.1 --snmp-version=2c --snmp-community=public --warning=1,2,3 --critical=2,3,4
    OK: Load average: 0.00, 0.00, 0.00 | 'load1'=0.00;0:1;0:2;0; 'load5'=0.00;0:2;0:3;0; 'load15'=0.00;0:3;0:4;0;

For more information or help, please read 'docs/user/guide.rst' or go to http://documentation.centreon.com/docs/centreon-plugins/en/latest/
