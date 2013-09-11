#!/usr/bin/perl -w

use strict;
no strict "refs";
use IO::Socket;
use Getopt::Long;

my $PROGNAME = $0;
my $VERSION = "1.5.0";
my %ERRORS = (OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3, DEPENDENT => 4);
my $socket;
my $separatorin = '~';

sub print_help();
sub print_usage();
sub print_revision($$);

my %OPTION = (
    help => undef, version => undef,
    "esxd-host" => undef, "esxd-port" => 5700,
    vsphere => '',
    usage => undef,
    "light-perfdata" => undef,
    "esx-host" => undef,
    datastore => undef,
    nic => undef,
    warning => undef,
    critical => undef,
    on => undef,
    units => undef,
    free => undef,
    filter => undef
);

Getopt::Long::Configure('bundling');
GetOptions(
    "h|help"                    => \$OPTION{help},
    "V|version"                 => \$OPTION{version},
    "H|centreon-esxd-host=s"    => \$OPTION{'esxd-host'},
    "P|centreon-esxd-port=i"    => \$OPTION{'esxd-port'},

    "vsphere=s"                 => \$OPTION{vsphere},

    "u|usage=s"                 => \$OPTION{usage},
    "e|esx-host=s"              => \$OPTION{'esx-host'},
    "vm=s"                      => \$OPTION{vm},
    
    "filter"                    => \$OPTION{filter},
    "free"                      => \$OPTION{free},
    "units=s"                   => \$OPTION{units},
    "light-perfdata"            => \$OPTION{'light-perfdata'},
    "datastore=s"               => \$OPTION{datastore},
    "nic=s"                     => \$OPTION{nic},

    "older=i"                   => \$OPTION{older},
    "warn"                      => \$OPTION{warn},
    "crit"                      => \$OPTION{crit},
    
    "on"                        => \$OPTION{on},

    "w|warning=i"               => \$OPTION{warning},
    "c|critical=i"              => \$OPTION{critical},

    "warning2=i"                => \$OPTION{warning2},
    "critical2=i"               => \$OPTION{critical2},
);

if (defined($OPTION{version})) {
    print_revision($PROGNAME, $VERSION);
    exit $ERRORS{OK};
}

if (defined($OPTION{help})) {
    print_help();
    exit $ERRORS{OK};
}

#############
# Functions #
#############

sub print_usage () {
    print "Usage: ";
    print $PROGNAME."\n";
    print "   -V (--version)    Plugin version\n";
    print "   -h (--help)       usage help\n";
    print "   -H              centreon-esxd Host (required)\n";
    print "   -P              centreon-esxd Port (default 5700)\n";
    print "   --vsphere        vsphere name (default: none)\n";
    print "   -u (--usage)        What to check. The list and args (required)\n";
    print "\n";
    print "'healthhost':\n";
    print "   -e (--esx-host)   Esx Host to check (required)\n";
    print "\n";
    print "'maintenancehost':\n";
    print "   -e (--esx-host)   Esx Host to check (required)\n";
    print "\n";
    print "'statushost':\n";
    print "   -e (--esx-host)   Esx Host to check (required)\n";
    print "\n";
    print "'datastore-usage':\n";
    print "   --datastore       Datastore name to check (required)\n";
    print "   -w (--warning)    Warning Threshold (default 80)\n";
    print "   -c (--critical)   Critical Threshold (default 90)\n";
    print "   --units           Threshold units: %, MB (default is MB)\n";
    print "   --free            Threshold is for free size\n";
    print "   --filter          Use regexp for --datastore option (can check multiples datastores at once)\n";
    print "\n";
    print "'datastore-io':\n";
    print "   --datastore       Datastore name to check (required)\n";
    print "   -w (--warning)    Warning Threshold in kBps (default none)\n";
    print "   -c (--critical)   Critical Threshold in kBps (default none)\n";
    print "\n";
    print "'datastore-snapshots':\n";
    print "   --datastore       Datastore name to check (required)\n";
    print "   -w (--warning)    Warning Threshold in bytes for all snapshots (default none)\n";
    print "   -c (--critical)   Critical Threshold in bytes for all snapshots (default none)\n";
    print "   --warning2        Warning Threshold in bytes for one snapshot (default none)\n";
    print "   --critical2       Critical Threshold in bytes for one snapshot (default none)\n";
    print "\n";
    print "'cpuhost':\n";
    print "   -e (--esx-host)   Esx Host to check (required)\n";
    print "   -w (--warning)    Warning Threshold in percent (default 80)\n";
    print "   -c (--critical)   Critical Threshold in percent (default 90)\n";
    print "   --light-perfdata  Display only total average cpu perfdata\n";
    print "\n";
    print "'nethost':\n";
    print "   -e (--esx-host)   Esx Host to check (required)\n";
    print "   --nic             Physical nic name to check (required)\n";
    print "   -w (--warning)    Warning Threshold in percent (default 80)\n";
    print "   -c (--critical)   Critical Threshold in percent (default 90)\n";
    print "\n";
    print "'memhost':\n";
    print "   -e (--esx-host)   Esx Host to check (required)\n";
    print "   -w (--warning)    Warning Threshold in percent (default 80)\n";
    print "   -c (--critical)   Critical Threshold in percent (default 90)\n";
    print "\n";
    print "'swaphost':\n";
    print "   -e (--esx-host)   Esx Host to check (required)\n";
    print "   -w (--warning)    Warning Threshold in MB/s (default 0.8)\n";
    print "   -c (--critical)   Critical Threshold in MB/s (default 1)\n";
    print "\n";
    print "'datastoreshost':\n";
    print "   -e (--esx-host)   Esx Host to check (required)\n";
    print "   -w (--warning)    Warning Threshold in ms (latency) (default none)\n";
    print "   -c (--critical)   Critical Threshold in ms (latency) (default none)\n";
    print "   --filter-datastores   Datastores to verify (separated by coma)\n";
    print "\n";
    print "'countvmhost':\n";
    print "   -e (--esx-host)   Esx Host to check (required)\n";
    print "   -w (--warning)    Warning Threshold (default none)\n";
    print "   -c (--critical)   Critical Threshold (default none)\n";
    print "\n";
    print "'uptimehost':\n";
    print "   -e (--esx-host)   Esx Host to check (required)\n";
    print "\n";
    print "'cpuvm':\n";
    print "   --vm              VM to check (required)\n";
    print "   -w (--warning)    Warning Threshold in percent (default 80)\n";
    print "   -c (--critical)   Critical Threshold in percent (default 90)\n";
    print "\n";
    print "'toolsvm':\n";
    print "   --vm              VM to check (required)\n";
    print "\n";
    print "'snapshotvm':\n";
    print "   --vm              VM to check (required)\n";
    print "   --older           If older than ms\n";
    print "   --crit            Critical if: there is a snasphot, or a snapshot is older than (--older)\n";
    print "   --warn            Warn if: there is a snasphot, or a snapshot is older than (--older)\n";
    print "\n";
    print "'datastoresvm':\n";
    print "   --vm              VM to check (required)\n";
    print "   -w (--warning)    Warning Threshold in IOPS (default none)\n";
    print "   -c (--critical)   Critical Threshold in IOPS (default none)\n";
    print "\n";
    print "'memvm':\n";
    print "   --vm              VM to check (required)\n";
    print "   -w (--warning)    Warning Threshold in percent (default 80)\n";
    print "   -c (--critical)   Critical Threshold in percent (default 90)\n";
    print "\n";
    print "'swapvm':\n";
    print "   --vm              VM to check (required)\n";
    print "   -w (--warning)    Warning Threshold in MB/s (default 0.8)\n";
    print "   -c (--critical)   Critical Threshold in MB/s (default 1)\n";
    print "\n";
    print "'thinprovisioningvm':\n";
    print "   --vm              VM to check (required)\n";
    print "   --on              Warn or critical if thinprovisioning set\n";
    print "   --crit            Critical\n";
    print "   --warn            Warn\n";
    print "\n";
    print "'listhost':\n";
    print "   None\n";
    print "\n";
    print "'listdatastore':\n";
    print "   None\n";
    print "\n";
    print "'listnichost':\n";
    print "   -e (--esx-host)   Esx Host to check (required)\n";
    print "\n";
    print "'getmap':\n";
    print "   -e (--esx-host)   Esx Host to check\n";
    print "\n";
    print "'stats':\n";
    print "   -w (--warning)    Warning Threshold in total client connections (default none)\n";
    print "   -c (--critical)   Critical Threshold in total client connections (default none)\n";
}

sub print_help () {
    print "##############################################\n";
    print "#    Copyright (c) 2005-2013 Centreon        #\n";
    print "#    Bugs to http://redmine.merethis.net/    #\n";
    print "##############################################\n";
    print "\n";
    print_usage();
    print "\n";
}

sub print_revision($$) {
        my $commandName = shift;
        my $pluginRevision = shift;
        print "$commandName v$pluginRevision (centreon-esxd)\n";
}

sub myconnect {
    if (!($socket = IO::Socket::INET->new( Proto => "tcp",
                     PeerAddr => $OPTION{'esxd-host'},
                     PeerPort => $OPTION{'esxd-port'}))) {
        print "Cannot connect to on '$OPTION{'esxd-host'}': $!\n";
        exit $ERRORS{UNKNOWN};
    }
    $socket->autoflush(1);
}

#################
# Func Usage
#################

sub maintenancehost_check_arg {
    if (!defined($OPTION{'esx-host'})) {
        print "Option --esx-host is required\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    return 0;
}

sub maintenancehost_get_str {
    return join($separatorin, 
               ('maintenancehost', $OPTION{vsphere}, $OPTION{'esx-host'}));
}

sub statushost_check_arg {
    if (!defined($OPTION{'esx-host'})) {
        print "Option --esx-host is required\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    return 0;
}

sub statushost_get_str {
    return join($separatorin, 
               ('statushost', $OPTION{vsphere}, $OPTION{'esx-host'}));
}

sub healthhost_check_arg {
    if (!defined($OPTION{'esx-host'})) {
        print "Option --esx-host is required\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    return 0;
}

sub healthhost_get_str {
    return join($separatorin, 
               ('healthhost', $OPTION{vsphere}, $OPTION{'esx-host'}));
}

sub datastoreusage_check_arg {
    if (!defined($OPTION{datastore})) {
        print "Option --datastore is required.\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    if (defined($OPTION{filter})) {
        $OPTION{filter} = 1;
    } else {
        $OPTION{filter} = 0;
    }
    if (defined($OPTION{free})) {
        $OPTION{free} = 1;
    } else {
        $OPTION{free} = 0;
    }
    if (!defined($OPTION{warning})) {
        $OPTION{warning} = ($OPTION{free} == 1) ? 20 : 80;
    }
    if (!defined($OPTION{critical})) {
        $OPTION{critical} = ($OPTION{free} == 1) ? 10 : 90;
    }
    if (defined($OPTION{units})) {
        if ($OPTION{units} ne '%' && $OPTION{units} ne 'MB') {
            print "Option --units accept '%' or 'MB'.\n";
            print_usage();
            exit $ERRORS{UNKNOWN};
        }
    } else {
        $OPTION{units} = '';
    }
    return 0;
}

sub datastoreusage_get_str {
    return join($separatorin, 
               ('datastore-usage', $OPTION{vsphere}, $OPTION{datastore}, $OPTION{filter}, $OPTION{warning}, $OPTION{critical}, $OPTION{free}, $OPTION{units}));
}

sub datastoreio_check_arg {
    if (!defined($OPTION{'datastore'})) {
        print "Option --datastore is required\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    if (!defined($OPTION{warning})) {
        $OPTION{warning} = '';
    }
    if (!defined($OPTION{critical})) {
        $OPTION{critical} = '';
    }
    return 0;
}

sub datastoreio_get_str {
    return join($separatorin, 
               ('datastore-io', $OPTION{vsphere}, $OPTION{datastore}, $OPTION{warning}, $OPTION{critical}));
}

sub datastoresnapshots_check_arg {
    if (!defined($OPTION{datastore})) {
        print "Option --datastore is required\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    if (!defined($OPTION{warning})) {
        $OPTION{warning} = '';
    }
    if (!defined($OPTION{critical})) {
        $OPTION{critical} = '';
    }
    if (!defined($OPTION{warning2})) {
        $OPTION{warning2} = '';
    }
    if (!defined($OPTION{critical2})) {
        $OPTION{critical2} = '';
    }
    return 0;
}

sub datastoresnapshots_get_str {
     return join($separatorin, 
               ('datastore-snapshots', $OPTION{vsphere}, $OPTION{datastore}, $OPTION{warning}, $OPTION{critical}, $OPTION{warning2}, $OPTION{critical2}));
}

sub cpuhost_check_arg {
    if (!defined($OPTION{'esx-host'})) {
        print "Option --esx-host is required\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    if (!defined($OPTION{warning})) {
        $OPTION{warning} = 80;
    }
    if (!defined($OPTION{critical})) {
        $OPTION{critical} = 90;
    }
    if (!defined($OPTION{'light-perfdata'})) {
        $OPTION{'light-perfdata'} = 0;
    }
    return 0;
}

sub cpuhost_get_str {
    return join($separatorin, 
               ('cpuhost', $OPTION{vsphere}, $OPTION{'esx-host'}, $OPTION{warning}, $OPTION{critical}, $OPTION{'light-perfdata'}));
}

sub datastoreshost_check_arg {
    if (!defined($OPTION{'esx-host'})) {
        print "Option --esx-host is required\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    if (!defined($OPTION{warning})) {
        $OPTION{warning} = '';
    }
    if (!defined($OPTION{critical})) {
        $OPTION{critical} = '';
    }
    if (!defined($OPTION{'filter-datastores'})) {
        $OPTION{'filter-datastores'} = '';
    }
    return 0;
}

sub datastoreshost_get_str {
     return join($separatorin, 
                ('datastoreshost', $OPTION{vsphere}, $OPTION{'esx-host'}, $OPTION{warning}, $OPTION{critical} , $OPTION{'filter-datastores'}));
}

sub memhost_check_arg {
    if (!defined($OPTION{'esx-host'})) {
        print "Option --esx-host is required\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    if (!defined($OPTION{warning})) {
        $OPTION{warning} = 80;
    }
    if (!defined($OPTION{critical})) {
        $OPTION{critical} = 90;
    }
    return 0;
}

sub memhost_get_str {
    return join($separatorin, 
                ('memhost', $OPTION{vsphere}, $OPTION{'esx-host'}, $OPTION{warning}, $OPTION{critical}));
}

sub swaphost_check_arg {
    if (!defined($OPTION{'esx-host'})) {
        print "Option --esx-host is required\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    if (!defined($OPTION{warning})) {
        $OPTION{warning} = 0.8;
    }
    if (!defined($OPTION{critical})) {
        $OPTION{critical} = 1;
    }
    return 0;
}

sub swaphost_get_str {
    return join($separatorin, 
                ('swaphost', $OPTION{vsphere}, $OPTION{'esx-host'}, $OPTION{warning}, $OPTION{critical}));
}

sub nethost_check_arg {
    if (!defined($OPTION{'esx-host'})) {
        print "Option --esx-host is required\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    if (!defined($OPTION{nic})) {
        print "Option --nic is required\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    if (!defined($OPTION{warning})) {
        $OPTION{warning} = 80;
    }
    if (!defined($OPTION{critical})) {
        $OPTION{critical} = 90;
    }
    return 0;
}

sub nethost_get_str {
    return join($separatorin, 
               ('nethost', $OPTION{vsphere}, $OPTION{'esx-host'}, $OPTION{nic}, $OPTION{warning}, $OPTION{critical}));
}

sub countvmhost_check_arg {
    if (!defined($OPTION{'esx-host'})) {
        print "Option --esx-host is required\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    if (!defined($OPTION{warning})) {
        $OPTION{warning} = '';
    }
    if (!defined($OPTION{critical})) {
        $OPTION{critical} = '';
    }
    return 0;
}

sub countvmhost_get_str {
    return join($separatorin, 
               ('countvmhost', $OPTION{vsphere}, $OPTION{'esx-host'}, $OPTION{warning}, $OPTION{critical}));
}

sub uptimehost_check_arg {
    if (!defined($OPTION{'esx-host'})) {
        print "Option --esx-host is required\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    return 0;
}

sub uptimehost_get_str {
    return join($separatorin, 
               ('uptimehost', $OPTION{vsphere}, $OPTION{'esx-host'}));
}

sub cpuvm_check_arg {
    if (!defined($OPTION{vm})) {
        print "Option --vm is required\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    if (!defined($OPTION{warning})) {
        $OPTION{warning} = 80;
    }
    if (!defined($OPTION{critical})) {
        $OPTION{critical} = 90;
    }
    return 0;
}

sub cpuvm_get_str {
    return join($separatorin, 
               ('cpuvm', $OPTION{vsphere}, $OPTION{vm}, $OPTION{warning}, $OPTION{critical}));
}

sub toolsvm_check_arg {
    if (!defined($OPTION{vm})) {
        print "Option --vm is required\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    return 0;
}

sub toolsvm_get_str {
    return join($separatorin, 
               ('toolsvm', $OPTION{vsphere}, $OPTION{vm}));
}

sub snapshotvm_check_arg {
    if (!defined($OPTION{vm})) {
        print "Option --vm is required\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    if (!defined($OPTION{older})) {
        $OPTION{older} = '';
    }
    if (!defined($OPTION{warn})) {
        $OPTION{warn} = 0;
    } else {
        $OPTION{warn} = 1;
    }
    if (!defined($OPTION{crit})) {
        $OPTION{crit} = 0;
    } else {
        $OPTION{crit} = 1;
    }
    return 0;
}

sub snapshotvm_get_str {
    return join($separatorin, 
               ('snapshotvm', $OPTION{vsphere}, $OPTION{vm}, $OPTION{older}, $OPTION{warn}, $OPTION{crit}));
}

sub datastoresvm_check_arg {
    if (!defined($OPTION{vm})) {
        print "Option --vm is required\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    if (!defined($OPTION{warning})) {
        $OPTION{warning} = '';
    }
    if (!defined($OPTION{critical})) {
        $OPTION{critical} = '';
    }
    return 0;
}

sub datastoresvm_get_str {
    return join($separatorin, 
               ('datastoresvm', $OPTION{vsphere}, $OPTION{vm}, $OPTION{warning}, $OPTION{critical}));
}

sub memvm_check_arg {
    if (!defined($OPTION{vm})) {
        print "Option --vm is required\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    if (!defined($OPTION{warning})) {
        $OPTION{warning} = 80;
    }
    if (!defined($OPTION{critical})) {
        $OPTION{critical} = 90;
    }
    return 0;
}

sub memvm_get_str {
    return join($separatorin, 
               ('memvm', $OPTION{vsphere}, $OPTION{vm}, $OPTION{warning}, $OPTION{critical}));
}

sub swapvm_check_arg {
    if (!defined($OPTION{vm})) {
        print "Option --vm is required\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    if (!defined($OPTION{warning})) {
        $OPTION{warning} = 0.8;
    }
    if (!defined($OPTION{critical})) {
        $OPTION{critical} = 1;
    }
    return 0;
}

sub swapvm_get_str {
    return join($separatorin, 
               ('swapvm', $OPTION{vsphere}, $OPTION{vm}, $OPTION{warning}, $OPTION{critical}));
}

sub thinprovisioningvm_check_arg {
    if (!defined($OPTION{vm})) {
        print "Option --vm is required\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    if (!defined($OPTION{on})) {
        $OPTION{on} = 0;
    } else {
        $OPTION{on} = 1;
    }
    if (!defined($OPTION{warn})) {
        $OPTION{warn} = 0;
    } else {
        $OPTION{warn} = 1;
    }
    if (!defined($OPTION{crit})) {
        $OPTION{crit} = 0;
    } else {
        $OPTION{crit} = 1;
    }
    return 0;
}

sub thinprovisioningvm_get_str {
    return join($separatorin, 
               ('thinprovisioningvm', $OPTION{vsphere}, $OPTION{vm}, $OPTION{on}, $OPTION{warn}, $OPTION{crit}));
}


sub listhost_check_arg {
    return 0;
}

sub listhost_get_str {
    return join($separatorin, 
               ('listhost', $OPTION{vsphere}));
}

sub listdatastore_check_arg {
    return 0;
}

sub listdatastore_get_str {
    return join($separatorin, 
               ('listdatastore', $OPTION{vsphere}));
}

sub listnichost_check_arg {
    if (!defined($OPTION{'esx-host'})) {
        print "Option --esx-host is required\n";
        print_usage();
        exit $ERRORS{UNKNOWN};
    }
    return 0;
}

sub listnichost_get_str {
    return join($separatorin, 
               ('listnichost', $OPTION{vsphere}, $OPTION{'esx-host'}));
}

sub getmap_check_arg {
    if (!defined($OPTION{'esx-host'})) {
        $OPTION{'esx-host'} = "";
    }
    return 0;
}

sub getmap_get_str {
    return join($separatorin, 
               ('getmap', $OPTION{vsphere}, $OPTION{'esx-host'}));
}

sub stats_check_arg {
    if (!defined($OPTION{warning})) {
        $OPTION{warning} = "";
    }
    if (!defined($OPTION{critical})) {
        $OPTION{critical} = "";
    }
    return 0;
}

sub stats_get_str {
    return join($separatorin, 
               ('stats', $OPTION{warning}, $OPTION{critical}));
}

#################
#################

if (!defined($OPTION{'esxd-host'})) {
    print "Option -H (--esxd-host) is required\n";
    print_usage();
    exit $ERRORS{UNKNOWN};
}

if (!defined($OPTION{usage})) {
    print "Option -u (--usage) is required\n";
    print_usage();
    exit $ERRORS{UNKNOWN};
}
if ($OPTION{usage} !~ /^(healthhost|datastore-usage|datastore-io|datastore-snapshots|maintenancehost|statushost|cpuhost|datastoreshost|nethost|memhost|swaphost|countvmhost|uptimehost|cpuvm|toolsvm|snapshotvm|datastoresvm|memvm|swapvm|thinprovisioningvm|listhost|listdatastore|listnichost|getmap|stats)$/) {
    print "Usage value is unknown\n";
    print_usage();
    exit $ERRORS{UNKNOWN};
}

$OPTION{'usage'} =~ s/-//g;
my $func_check_arg = $OPTION{'usage'} . "_check_arg";
my $func_get_str = $OPTION{'usage'} . "_get_str";
&$func_check_arg();
my $str_send = &$func_get_str();
myconnect();
print $socket "$str_send\n";
my $return = <$socket>;
close $socket;

chomp $return;
$return =~ /^(-?[0-9]*?)\|/;
my $status_return = $1;
$return =~ s/^(-?[0-9]*?)\|//;
print $return . "\n";

if ($status_return < 0) {
    $status_return = 3;
}
exit $status_return;

#print $remote "healthhost||srvi-esx-dev-1.merethis.net\n";
#print $remote "datastores||LUN-VMFS-QGARNIER|80|90\n";
#print $remote "maintenancehost||srvi-esx-dev-1.merethis.net\n";
#print $remote "statushost||srvi-esx-dev-1.merethis.net\n";
#print $remote "cpuhost||srvi-esx-dev-1.merethis.net|60\n";
#print $remote "nethost||srvi-esx-dev-1.merethis.net|vmnic1|60\n";
#print $remote "memhost||srvi-esx-dev-1.merethis.net|80\n";
#print $remote "swaphost||srvi-esx-dev-1.merethis.net|80\n";
