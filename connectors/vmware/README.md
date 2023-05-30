# centreon-vmware

"centreon-vmware" is a free and open source project. The project can be used with Centreon and all monitoring softwares compatible with Nagios plugins.
It's a Perl daemon in charged to get back VMWare indicators. This program uses the SDK Perl provided by VMWare.

The connector could get following indicators:
* For ESX Server:
    * Current alarms
    * CPU usage
    * Memory usage
    * Swap usage
    * Interface trafics
    * Count VMs
    * Health status
    * Global status
    * Uptime
* For Virtual Machines:
    * CPU usage
    * Memory usage
    * Swap usage
    * IOPs on datastores
    * Limits configured (CPU, memory and disks)
    * Snapshot age and consolidation
    * Thinprovisioning configuration
    * VMTools state
* For Datastores:
    * Usage
    * IOPs
    * Usage in bytes/s
    * Snapshost sizes
* For Cluster:
    * Operations on virtual machines (Clone, VMotion,...)
* For Datacenter:
    * Current alarms

You can check one or X entities for each checks. Moreover, you can also "scope" it. It means: i can check the virtual machines of a datacenter(s) and/or a cluster(s).
   
Please follow the documentation for the installation: https://github.com/centreon/centreon-vmware/blob/master/doc/en/installation/index.rst

## Examples

Check vmtools states of virtual machines (with name matching the regexp 'prd'):

    $ perl centreon_plugins.pl --plugin=apps::vmware::connector::plugin --connector-hostname=127.0.0.1 --container=default --verbose --mode=tools-vm --display-description --vm-hostname='prd' --filter
    WARNING: 1 VM with VMTools not installed |
    vmtools not installed:
        prd-Reporting - 10.0.0.1 [description xxxx]

Check datastore IOPs of virtual machines (with name matching the regexp 'centreon-central-1|Formation'):

    $ perl centreon_plugins.pl --plugin=apps::vmware::connector::plugin --connector-hostname=127.0.0.1 --container=default --verbose --mode=datastore-vm --vm-hostname='woot|test-migration' --filter
    OK: All virtual machines are ok | 'max_total_latency_test-migration'=2.00ms;;;0; 'riops_test-migration_INTEGRATION'=0.41iops;;;0; 'wiops_test-migration_INTEGRATION'=4.84iops;;;0;4.84 'riops_test-migration_ISOs'=0.00iops;;;0; 'wiops_test-migration_ISOs'=0.00iops;;;0;0.00 'max_total_latency_woot'=23.00ms;;;0; 'riops_woot'=0.02iops;;;0; 'wiops_woot'=0.67iops;;;0;0.67
    checking virtual machine 'test-migration'
        [connection state connected][power state poweredOn]
        max total latency is 2.00 ms
        datastore 'INTEGRATION' 0.41 read iops, 4.84 write iops
        datastore 'ISOs' 0.00 read iops, 0.00 write iops
    checking virtual machine 'woot'
        [connection state connected][power state poweredOn]
        max total latency is 23.00 ms
        datastore 'DSI' 0.02 read iops, 0.67 write iops

Check the health of ESX Servers:

    $ perl centreon_plugins.pl --plugin=apps::vmware::connector::plugin --connector-hostname=127.0.0.1 --container=default --verbose --mode=health-host --esx-hostname='.*' --filter --disconnect-status='ok'
    OK: 0 total health issue(s) found - All ESX hosts are ok | 'total_problems'=0;;;0;1034 'problems_srvi-clus-esx-n1.int.centreon.com'=0;;;0;315 'problems_yellow_srvi-clus-esx-n1.int.centreon.com'=0;;;0;315 'problems_red_srvi-clus-esx-n1.int.centreon.com'=0;;;0;315 'problems_srvi-clus-esx-n2.int.centreon.com'=0;;;0;315 'problems_yellow_srvi-clus-esx-n2.int.centreon.com'=0;;;0;315 'problems_red_srvi-clus-esx-n2.int.centreon.com'=0;;;0;315 'problems_srvi-clus-esx-n3.int.centreon.com'=0;;;0;202 'problems_yellow_srvi-clus-esx-n3.int.centreon.com'=0;;;0;202 'problems_red_srvi-clus-esx-n3.int.centreon.com'=0;;;0;202 'problems_srvi-clus-esx-n4.int.centreon.com'=0;;;0;202 'problems_yellow_srvi-clus-esx-n4.int.centreon.com'=0;;;0;202 'problems_red_srvi-clus-esx-n4.int.centreon.com'=0;;;0;202
    checking host 'srvi-clus-esx-n1.int.centreon.com'
        status connected
        315 health checks are green, 0 total health issue(s) found, 0 yellow health issue(s) found, 0 red health issue(s) found
    checking host 'srvi-clus-esx-n2.int.centreon.com'
        status connected
        315 health checks are green, 0 total health issue(s) found, 0 yellow health issue(s) found, 0 red health issue(s) found
    checking host 'srvi-clus-esx-n3.int.centreon.com'
        status connected
        202 health checks are green, 0 total health issue(s) found, 0 yellow health issue(s) found, 0 red health issue(s) found
    checking host 'srvi-clus-esx-n4.int.centreon.com'
        status connected
        202 health checks are green, 0 total health issue(s) found, 0 yellow health issue(s) found, 0 red health issue(s) found
