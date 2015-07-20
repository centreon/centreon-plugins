# centreon-vmware

“centreon-vmware” is a free and open source project. The project can be used with Centreon and all monitoring softwares compatible with Nagios plugins.
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
   
Please follow the documentation for the installation: https://github.com/centreon/centreon-vmware/tree/master/docs/en/installation/index.rst

## Examples

Check vmtools states of virtual machines (with name matching the regexp 'prd'):

    $ perl centreon_plugins.pl --plugin=apps::vmware::connector::plugin  --custommode=connector --connector-hostname=127.0.0.1 --container=default --verbose --mode=tools-vm --display-description --vm-hostname='prd' --filter
    WARNING: 1 VM with VMTools not installed |
    vmtools not installed:
        prd-Reporting - 10.0.0.1 [description xxxx]

Check datastore IOPs of virtual machines (with name matching the regexp 'centreon-central-1|Formation'):

    $ perl centreon_plugins.pl --plugin=apps::vmware::connector::plugin  --custommode=connector --connector-hostname=127.0.0.1 --container=default --verbose --mode=datastore-vm --vm-hostname='centreon-central-1|Formation' --filter
    OK: All Datastore IOPS counters are ok | 'riops_Formation-Reporting - 10.30.2.89_R&D-BI'=0.00iops;;;0; 'wiops_Formation-Reporting - 10.30.2.89_R&D-BI'=1.43iops;;;0; 'riops_centreon-central-1_INTEGRATION'=0.00iops;;;0; 'wiops_centreon-central-1_INTEGRATION'=0.60iops;;;0;
    'Formation-Reporting - 10.30.2.89' read iops on 'R&D-BI' is 0.00
    'Formation-Reporting - 10.30.2.89' write iops on 'R&D-BI' is 1.43
    'centreon-central-1' read iops on 'INTEGRATION' is 0.00
    'centreon-central-1' write iops on 'INTEGRATION' is 0.60

Check the health of ESX Servers:

    $ perl centreon_plugins.pl --plugin=apps::vmware::connector::plugin  --custommode=connector --connector-hostname=127.0.0.1 --container=default --verbose --mode=health-host --esx-hostname='.*' --filter --disconnect-status='ok'
    OK: All ESX health checks are ok | 'problems_srvi-clus-esx-n2.merethis.net'=0;;;0;299 'problems_srvi-clus-esx-n1.merethis.net'=0;;;0;299 'problems_srvi-clus-esx-n4.merethis.net'=0;;;0;186 'problems_srvi-clus-esx-n3.merethis.net'=0;;;0;186
    Checking srvi-clus-esx-n2.merethis.net
    299 health checks are green
    Checking srvi-clus-esx-n1.merethis.net
    299 health checks are green
    Checking srvi-clus-esx-n4.merethis.net
    186 health checks are green
    Checking srvi-clus-esx-n3.merethis.net
    186 health checks are green
