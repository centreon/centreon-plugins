#!/usr/bin/perl -w 
############################## check_snmp_load #################
my $Version='1.12';
# Date : Oct 12 2007
# Author  : Patrick Proy ( patrick at proy.org)
# Help : http://nagios.manubulon.com/
# Licence : GPL - http://www.fsf.org/licenses/gpl.txt
# Contributors : F. Lacroix and many others !!!
#################################################################
#
# Help : ./check_snmp_load.pl -h
#

use strict;
use Getopt::Long;
require "@NAGIOS_PLUGINS@/Centreon/SNMP/Utils.pm";

# Nagios specific
my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

# SNMP Datas
my %OPTION = (
    "host" => undef,
    "snmp-community" => "public", "snmp-version" => 1, "snmp-port" => 161, 
    "snmp-auth-key" => undef, "snmp-auth-user" => undef, "snmp-auth-password" => undef, "snmp-auth-protocol" => "MD5",
    "snmp-priv-key" => undef, "snmp-priv-password" => undef, "snmp-priv-protocol" => "DES",
    "maxrepetitions" => undef, "snmptimeout" => undef,
    "64-bits" => undef,
);
my $session_params;

# Generic with host-ressource-mib
my $base_proc = "1.3.6.1.2.1.25.3.3.1";   # oid for all proc info
my $proc_id   = "1.3.6.1.2.1.25.3.3.1.1"; # list of processors (product ID)
my $proc_load = "1.3.6.1.2.1.25.3.3.1.2"; # %time the proc was not idle over last minute

# Linux load 

my $linload_table= "1.3.6.1.4.1.2021.10.1";   # net-snmp load table
my $linload_name = "1.3.6.1.4.1.2021.10.1.2"; # text 'Load-1','Load-5', 'Load-15'
my $linload_load = "1.3.6.1.4.1.2021.10.1.3"; # effective load table

# Cisco cpu/load

my $cisco_cpu_5m = "1.3.6.1.4.1.9.2.1.58.0"; # Cisco CPU load (5min %)
my $cisco_cpu_1m = "1.3.6.1.4.1.9.2.1.57.0"; # Cisco CPU load (1min %)
my $cisco_cpu_5s = "1.3.6.1.4.1.9.2.1.56.0"; # Cisco CPU load (5sec %)

# Cisco catalyst cpu/load

my $ciscocata_cpu_5m = ".1.3.6.1.4.1.9.9.109.1.1.1.1.5.9"; # Cisco CPU load (5min %)
my $ciscocata_cpu_1m = ".1.3.6.1.4.1.9.9.109.1.1.1.1.3.9"; # Cisco CPU load (1min %)
my $ciscocata_cpu_5s = ".1.3.6.1.4.1.9.9.109.1.1.1.1.4.9"; # Cisco CPU load (5sec %)

# Netscreen cpu/load

my $nsc_cpu_5m = "1.3.6.1.4.1.3224.16.1.4.0"; # NS CPU load (5min %)
my $nsc_cpu_1m = "1.3.6.1.4.1.3224.16.1.2.0"; # NS CPU load (1min %)
my $nsc_cpu_5s = "1.3.6.1.4.1.3224.16.1.3.0"; # NS CPU load (5sec %)

# AS/400 CPU

my $as400_cpu = "1.3.6.1.4.1.2.6.4.5.1.0"; # AS400 CPU load (10000=100%);

# Net-SNMP CPU

my $ns_cpu_idle   = "1.3.6.1.4.1.2021.11.11.0"; # Net-snmp cpu idle
my $ns_cpu_user   = "1.3.6.1.4.1.2021.11.9.0";  # Net-snmp user cpu usage
my $ns_cpu_system = "1.3.6.1.4.1.2021.11.10.0"; # Net-snmp system cpu usage

# Procurve CPU
my $procurve_cpu = "1.3.6.1.4.1.11.2.14.11.5.1.9.6.1.0"; # Procurve CPU Counter

# Nokia CPU
my $nokia_cpu = "1.3.6.1.4.1.94.1.21.1.7.1.0"; # Nokia CPU % usage

# Bluecoat Appliance
my $bluecoat_cpu = "1.3.6.1.4.1.3417.2.4.1.1.1.4.1"; # Bluecoat %cpu usage.

# Fortigate CPU
my $fortigate_cpu = ".1.3.6.1.4.1.12356.1.8.0"; # Fortigate CPU % usage

# Linkproof Appliance
my $linkproof_cpu= "1.3.6.1.4.1.89.35.1.55.0"; # CPU RE (Routing Engine Tasks)
# 1.3.6.1.4.1.89.35.1.53.0 : Ressource utilisation (%) Considers network utilization and internal CPU utilization
# 1.3.6.1.4.1.89.35.1.54 : CPU only (%)
# 1.3.6.1.4.1.89.35.1.55 : network only (%)

# HP-UX cpu usage (thanks to krizb for the OIDs).
my $hpux_load_1_min="1.3.6.1.4.1.11.2.3.1.1.3.0";
my $hpux_load_5_min="1.3.6.1.4.1.11.2.3.1.1.4.0";
my $hpux_load_15_min="1.3.6.1.4.1.11.2.3.1.1.5.0";
 
# valid values 
my @valid_types = ("stand","netsc","netsl","as400","cisco","cata","nsc","fg","bc","nokia","hp","lp","hpux");
# CPU OID array
my %cpu_oid = ("netsc",$ns_cpu_idle,"as400",$as400_cpu,"bc",$bluecoat_cpu,"nokia",$nokia_cpu,"hp",$procurve_cpu,"lp",$linkproof_cpu,"fg",$fortigate_cpu);

# Globals

my $o_help=	undef; 		# wan't some help ?
my $o_verb=	undef;		# verbose mode
my $o_version=	undef;		# print version
# check type  : stand | netsc |  netsl | as400 | cisco | cata | nsc | fg | bc | nokia | hp | lp  | hpux
my $o_check_type= "stand";	
# End compatibility
my $o_warn=	undef;		# warning level
my @o_warnL=	undef;		# warning levels for Linux Load or Cisco CPU
my $o_crit=	undef;		# critical level
my @o_critL=	undef;		# critical level for Linux Load or Cisco CPU
my $o_perf=     undef;          # Output performance data

# functions

sub p_version { print "check_snmp_load version : $Version\n"; }

sub print_usage {
    print "Usage: $0 [-v] -H <host> -C <snmp_community> [-2] | (-l login -x passwd [-X pass -L <authp>,<privp>])  [-p <port>] -w <warn level> -c <crit level> -T=[stand|netsl|netsc|as400|cisco|cata|nsc|fg|bc|nokia|hp|lp|hpux] [-f] [-t <timeout>] [-V]\n";
}

sub isnnum { # Return true if arg is not a number
  my $num = shift;
  if ( $num =~ /^(\d+\.?\d*)|(^\.\d+)$/ ) { return 0 ;}
  return 1;
}

sub help {
   print "\nSNMP Load & CPU Monitor for Nagios version ",$Version,"\n";
   print "GPL licence, (c)2004-2007 Patrick Proy\n\n";
   print_usage();
   print <<EOT;
-v, --verbose
   print extra debugging information 
-h, --help
   print this help message
-H, --hostname=HOST
   name or IP address of host to check
-C, --community=COMMUNITY NAME
   community name for the host's SNMP agent (implies v1 protocol)
-l, --login=LOGIN ; -x, --passwd=PASSWD
   Login and auth password for snmpv3 authentication 
   If no priv password exists, implies AuthNoPriv 
-P, --port=PORT
   SNMP port (Default 161)
-w, --warn=INTEGER | INT,INT,INT
   1 value check : warning level for cpu in percent (on one minute)
   3 value check : comma separated level for load or cpu for 1min, 5min, 15min 
-c, --crit=INTEGER | INT,INT,INT
   critical level for cpu in percent (on one minute)
   1 value check : critical level for cpu in percent (on one minute)
   3 value check : comma separated level for load or cpu for 1min, 5min, 15min 
-T, --type=stand|netsl|netsc|as400|cisco|bc|nokia|hp|lp
	CPU check : 
		stand : standard MIBII (works with Windows), 
		        can handle multiple CPU.
		netsl : linux load provided by Net SNMP (1,5 & 15 minutes values)
		netsc : cpu usage given by net-snmp (100-idle)
		as400 : as400 CPU usage
		cisco : Cisco CPU usage
		cata  : Cisco catalyst CPU usage
		nsc   : NetScreen CPU usage
		fg    : Fortigate CPU usage
		bc    : Bluecoat CPU usage
		nokia : Nokia CPU usage
		hp    : HP procurve switch CPU usage
		lp    : Linkproof CPU usage
		hpux  : HP-UX load (1,5 & 15 minutes values)
-f, --perfparse
   Perfparse compatible output
-t, --timeout=INTEGER
   timeout for SNMP in seconds (Default: 5)
-V, --version
   prints version number
EOT
}

# For verbose output
sub verb { my $t=shift; print $t,"\n" if defined($o_verb) ; }

sub check_options {
    Getopt::Long::Configure ("bundling");
    GetOptions(
        "H|hostname|host=s"         => \$OPTION{'host'},
        "C|community=s"             => \$OPTION{'snmp-community'},
        "snmp|snmp-version=s"       => \$OPTION{'snmp-version'},
        "p|port|P|snmpport|snmp-port=i"    => \$OPTION{'snmp-port'},
        "l|login|username=s"        => \$OPTION{'snmp-auth-user'},
        "x|passwd|authpassword|password=s" => \$OPTION{'snmp-auth-password'},
        "k|authkey=s"               => \$OPTION{'snmp-auth-key'},
        "authprotocol=s"            => \$OPTION{'snmp-auth-protocol'},
        "privpassword=s"            => \$OPTION{'snmp-priv-password'},
        "privkey=s"                 => \$OPTION{'snmp-priv-key'},
        "privprotocol=s"            => \$OPTION{'snmp-priv-protocol'},
        "maxrepetitions=s"          => \$OPTION{'maxrepetitions'},
        "t|timeout|snmp-timeout=i"  => \$OPTION{'snmptimeout'},
        "64-bits"                   => \$OPTION{'64-bits'},

        'v'     => \$o_verb,		'verbose'	=> \$o_verb,
        'h'     => \$o_help,    	'help'        	=> \$o_help,
        'V'     => \$o_version,		'version'	=> \$o_version,
        'c:s'   => \$o_crit,            'critical:s'    => \$o_crit,
        'w:s'   => \$o_warn,            'warn:s'        => \$o_warn,
        'f'     => \$o_perf,            'perfparse'     => \$o_perf,
        'T:s'	=> \$o_check_type,	'type:s'	=> \$o_check_type
	);
    # check snmp information
    ($session_params) = Centreon::SNMP::Utils::check_snmp_options($ERRORS{'UNKNOWN'}, \%OPTION);
    # check the -T option
    my $T_option_valid=0; 
    foreach (@valid_types) { if ($_ eq $o_check_type) {$T_option_valid=1} };
    if ( $T_option_valid == 0 ) 
       {print "Invalid check type (-T)!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
    if (defined ($o_help) ) { help(); exit $ERRORS{"UNKNOWN"}};
    if (defined($o_version)) { p_version(); exit $ERRORS{"UNKNOWN"}};
    # Check warnings and critical
    if (!defined($o_warn) || !defined($o_crit))
 	{ print "put warning and critical info!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
    # Get rid of % sign
    $o_warn =~ s/\%//g; 
    $o_crit =~ s/\%//g;
    # Check for multiple warning and crit in case of -L
	if (($o_check_type eq "netsl") || ($o_check_type eq "cisco") || ($o_check_type eq "cata") || 
		($o_check_type eq "nsc") || ($o_check_type eq "hpux")) {
		@o_warnL=split(/,/ , $o_warn);
		@o_critL=split(/,/ , $o_crit);
		if (($#o_warnL != 2) || ($#o_critL != 2)) 
			{ print "3 warnings and critical !\n";print_usage(); exit $ERRORS{"UNKNOWN"}}
		for (my $i=0;$i<3;$i++) {
			if ( isnnum($o_warnL[$i]) || isnnum($o_critL[$i])) 
				{ print "Numeric value for warning or critical !\n";print_usage(); exit $ERRORS{"UNKNOWN"}}
			if ($o_warnL[$i] > $o_critL[$i]) 
				{ print "warning <= critical ! \n";print_usage(); exit $ERRORS{"UNKNOWN"}}
		}
	} else {
		if (($o_warn =~ /,/) || ($o_crit =~ /,/)) {
             { print "Multiple warning/critical levels not available for this check\n";print_usage(); exit $ERRORS{"UNKNOWN"}}
		}
        if ( isnnum($o_warn) || isnnum($o_crit) ) 
			{ print "Numeric value for warning or critical !\n";print_usage(); exit $ERRORS{"UNKNOWN"}}
		if ($o_warn > $o_crit) 
            { print "warning <= critical ! \n";print_usage(); exit $ERRORS{"UNKNOWN"}}
	}
}

########## MAIN #######

check_options();

# Connect to host
my $session = Centreon::SNMP::Utils::connection($ERRORS{'UNKNOWN'}, $session_params);

my $exit_val=undef;
########### Linux load check ##############

if ($o_check_type eq "netsl") {
    verb("Checking linux load");
    # Get load table
    my $resultat = Centreon::SNMP::Utils::get_snmp_table($linload_table, $session, $ERRORS{'UNKNOWN'}, \%OPTION);

    my @load = undef;
    my @iload = undef;
    my @oid=undef;
    my $exist=0;
    foreach my $key ( keys %$resultat) {
        verb("OID : $key, Desc : $$resultat{$key}");
        if ( $key =~ /$linload_name/ ) { 
            @oid=split (/\./,$key);
            $iload[0]= pop(@oid) if ($$resultat{$key} eq "Load-1");
            $iload[1]= pop(@oid) if ($$resultat{$key} eq "Load-5");
            $iload[2]= pop(@oid) if ($$resultat{$key} eq "Load-15");
            $exist=1
        }
    }

    if ($exist == 0) {
        print "Can't find snmp information on load : UNKNOWN\n";
        exit $ERRORS{"UNKNOWN"};
    }

    for (my $i=0;$i<3;$i++) { $load[$i] = $$resultat{$linload_load . "." . $iload[$i]}};

        print "Load : $load[0] $load[1] $load[2] :";

        $exit_val=$ERRORS{"OK"};
        for (my $i=0;$i<3;$i++) {
            if ( $load[$i] > $o_critL[$i] ) {
                print " $load[$i] > $o_critL[$i] : CRITICAL";
                $exit_val=$ERRORS{"CRITICAL"};
            }
            if ( $load[$i] > $o_warnL[$i] ) {
                # output warn error only if no critical was found 
                if ($exit_val eq $ERRORS{"OK"}) {
                    print " $load[$i] > $o_warnL[$i] : WARNING"; 
                    $exit_val=$ERRORS{"WARNING"};
                }
            }
        }
    print " OK" if ($exit_val eq $ERRORS{"OK"});
    if (defined($o_perf)) { 
        print " | load_1_min=$load[0];$o_warnL[0];$o_critL[0] ";
        print "load_5_min=$load[1];$o_warnL[1];$o_critL[1] ";
        print "load_15_min=$load[2];$o_warnL[2];$o_critL[2]\n";
    } else {
        print "\n";
    }
    exit $exit_val;
}

############## Cisco CPU check ################

if ($o_check_type eq "cisco") {
    my @oidlists = ($cisco_cpu_5m, $cisco_cpu_1m, $cisco_cpu_5s);
    my $resultat = Centreon::SNMP::Utils::get_snmp_leef(\@oidlists, $session, $ERRORS{'UNKNOWN'});

    if (!defined ($$resultat{$cisco_cpu_5s})) {
        print "No CPU information : UNKNOWN\n";
        exit $ERRORS{"UNKNOWN"};
    }

    my @load = undef;

    $load[0]=$$resultat{$cisco_cpu_5s};
    $load[1]=$$resultat{$cisco_cpu_1m};
    $load[2]=$$resultat{$cisco_cpu_5m};

    print "CPU : $load[0] $load[1] $load[2] :";

    $exit_val=$ERRORS{"OK"};
    for (my $i=0;$i<3;$i++) {
        if ( $load[$i] > $o_critL[$i] ) {
            print " $load[$i] > $o_critL[$i] : CRITICAL";
            $exit_val=$ERRORS{"CRITICAL"};
        }
        if ( $load[$i] > $o_warnL[$i] ) {
            # output warn error only if no critical was found
            if ($exit_val eq $ERRORS{"OK"}) {
                print " $load[$i] > $o_warnL[$i] : WARNING"; 
                $exit_val=$ERRORS{"WARNING"};
            }
        }
    }
    print " OK" if ($exit_val eq $ERRORS{"OK"});
    if (defined($o_perf)) {
        print " | load_5_sec=$load[0]%;$o_warnL[0];$o_critL[0] ";
        print "load_1_min=$load[1]%;$o_warnL[1];$o_critL[1] ";
        print "load_5_min=$load[2]%;$o_warnL[2];$o_critL[2]\n";
    } else {
        print "\n";
    }

    exit $exit_val;
}

############## Cisco Catalyst CPU check ################

if ($o_check_type eq "cata") {
    my @oidlists = ($ciscocata_cpu_5m, $ciscocata_cpu_1m, $ciscocata_cpu_5s);
    my $resultat = Centreon::SNMP::Utils::get_snmp_leef(\@oidlists, $session, $ERRORS{'UNKNOWN'});

    if (!defined ($$resultat{$ciscocata_cpu_5s})) {
        print "No CPU information : UNKNOWN\n";
        exit $ERRORS{"UNKNOWN"};
    }

    my @load = undef;

    $load[0]=$$resultat{$ciscocata_cpu_5s};
    $load[1]=$$resultat{$ciscocata_cpu_1m};
    $load[2]=$$resultat{$ciscocata_cpu_5m};

    print "CPU : $load[0] $load[1] $load[2] :";

    $exit_val=$ERRORS{"OK"};
    for (my $i=0;$i<3;$i++) {
        if ( $load[$i] > $o_critL[$i] ) {
            print " $load[$i] > $o_critL[$i] : CRITICAL";
            $exit_val=$ERRORS{"CRITICAL"};
        }
        if ( $load[$i] > $o_warnL[$i] ) {
            # output warn error only if no critical was found
            if ($exit_val eq $ERRORS{"OK"}) {
                print " $load[$i] > $o_warnL[$i] : WARNING"; 
                $exit_val=$ERRORS{"WARNING"};
            }
        }
    }
    print " OK" if ($exit_val eq $ERRORS{"OK"});
    if (defined($o_perf)) {
        print " | load_5_sec=$load[0]%;$o_warnL[0];$o_critL[0] ";
        print "load_1_min=$load[1]%;$o_warnL[1];$o_critL[1] ";
        print "load_5_min=$load[2]%;$o_warnL[2];$o_critL[2]\n";
    } else {
        print "\n";
    }

    exit $exit_val;
}

############## Netscreen CPU check ################

if ($o_check_type eq "nsc") {
    my @oidlists = ($nsc_cpu_5m, $nsc_cpu_1m, $nsc_cpu_5s);
    my $resultat = Centreon::SNMP::Utils::get_snmp_leef(\@oidlists, $session, $ERRORS{'UNKNOWN'});

    if (!defined ($$resultat{$nsc_cpu_5s})) {
        print "No CPU information : UNKNOWN\n";
        exit $ERRORS{"UNKNOWN"};
    }

    my @load = undef;

    $load[0]=$$resultat{$nsc_cpu_5s};
    $load[1]=$$resultat{$nsc_cpu_1m};
    $load[2]=$$resultat{$nsc_cpu_5m};

    print "CPU : $load[0] $load[1] $load[2] :";

    $exit_val=$ERRORS{"OK"};
    for (my $i=0;$i<3;$i++) {
        if ( $load[$i] > $o_critL[$i] ) {
            print " $load[$i] > $o_critL[$i] : CRITICAL";
            $exit_val=$ERRORS{"CRITICAL"};
        }
        if ( $load[$i] > $o_warnL[$i] ) {
            # output warn error only if no critical was found
            if ($exit_val eq $ERRORS{"OK"}) {
                print " $load[$i] > $o_warnL[$i] : WARNING"; 
                $exit_val=$ERRORS{"WARNING"};
            }
        }
    }
    print " OK" if ($exit_val eq $ERRORS{"OK"});
    if (defined($o_perf)) {
        print " | cpu_5_sec=$load[0]%;$o_warnL[0];$o_critL[0] ";
        print "cpu_1_min=$load[1]%;$o_warnL[1];$o_critL[1] ";
        print "cpu_5_min=$load[2]%;$o_warnL[2];$o_critL[2]\n";
    } else {
        print "\n";
    }

    exit $exit_val;
}

################## CPU for : AS/400 , Netsnmp, HP, Bluecoat, linkproof, fortigate  ###########
if ( $o_check_type =~ /netsc|as400|bc|nokia|^hp$|lp|fg/ ) {

    # Get load table
    my @oidlist = $cpu_oid{$o_check_type}; 
    verb("Checking OID : @oidlist");
    my $resultat = Centreon::SNMP::Utils::get_snmp_leef(\@oidlist, $session, $ERRORS{'UNKNOWN'});

    if (!defined ($$resultat{$cpu_oid{$o_check_type}})) {
        print "No CPU information : UNKNOWN\n";
        exit $ERRORS{"UNKNOWN"};
    }

    my $load=$$resultat{$cpu_oid{$o_check_type}};
    verb("OID returned $load");
    # for AS400, divide by 100
    if ($o_check_type eq "as400") {$load /= 100; };
    # for Net-snmp : oid returned idle time so load = 100-idle.
    if ($o_check_type eq "netsc") {$load = 100 - $load; }; 

    printf("CPU used %.1f%% (",$load);

    $exit_val=$ERRORS{"OK"};
    if ($load > $o_crit) {
        print ">$o_crit) : CRITICAL";
        $exit_val=$ERRORS{"CRITICAL"};
    } else {
        if ($load > $o_warn) {
            print ">$o_warn) : WARNING";
            $exit_val=$ERRORS{"WARNING"};
        }
    }
    print "<$o_warn) : OK" if ($exit_val eq $ERRORS{"OK"});
    (defined($o_perf)) ?
        print " | cpu_prct_used=$load%;$o_warn;$o_crit\n"
        : print "\n";
    exit $exit_val;
}

##### Checking hpux load
if ($o_check_type eq "hpux") {

    verb("Checking hpux load");

    my @oidlists = ($hpux_load_1_min, $hpux_load_5_min, $hpux_load_15_min);
    my $resultat = Centreon::SNMP::Utils::get_snmp_leef(\@oidlists, $session, $ERRORS{'UNKNOWN'});

    if (!defined ($$resultat{$hpux_load_1_min})) {
        print "No Load information : UNKNOWN\n";
        exit $ERRORS{"UNKNOWN"};
    }

    my @load = undef;

    $load[0]=$$resultat{$hpux_load_1_min}/100;
    $load[1]=$$resultat{$hpux_load_5_min}/100;
    $load[2]=$$resultat{$hpux_load_15_min}/100;

    print "Load : $load[0] $load[1] $load[2] :";

    $exit_val=$ERRORS{"OK"};
    for (my $i=0;$i<3;$i++) {
        if ( $load[$i] > $o_critL[$i] ) {
            print " $load[$i] > $o_critL[$i] : CRITICAL";
            $exit_val=$ERRORS{"CRITICAL"};
        }
        if ( $load[$i] > $o_warnL[$i] ) {
            # output warn error only if no critical was found
            if ($exit_val eq $ERRORS{"OK"}) {
                print " $load[$i] > $o_warnL[$i] : WARNING"; 
                $exit_val=$ERRORS{"WARNING"};
            }
        }
    }
    print " OK" if ($exit_val eq $ERRORS{"OK"});
    if (defined($o_perf)) {
        print " | load_1_min=$load[0]%;$o_warnL[0];$o_critL[0] ";
        print "load_5_min=$load[1]%;$o_warnL[1];$o_critL[1] ";
        print "load_15_min=$load[2]%;$o_warnL[2];$o_critL[2]\n";
    } else {
        print "\n";
    }

    exit $exit_val;
}

########## Standard cpu usage check ############
# Get desctiption table
my $resultat = Centreon::SNMP::Utils::get_snmp_table($base_proc, $session, $ERRORS{'UNKNOWN'}, \%OPTION);

my ($cpu_used,$ncpu)=(0,0);
foreach my $key ( keys %$resultat) {
    verb("OID : $key, Desc : $$resultat{$key}");
    if ( $key =~ /$proc_load/) {
        $cpu_used += $$resultat{$key};
        $ncpu++;
    }
}

if ($ncpu==0) {
    print "Can't find CPU usage information : UNKNOWN\n";
    exit $ERRORS{"UNKNOWN"};
}

$cpu_used /= $ncpu;

print "$ncpu CPU, ", $ncpu==1 ? "load" : "average load";
printf(" %.1f%%",$cpu_used);
$exit_val=$ERRORS{"OK"};

if ($cpu_used > $o_crit) {
    print " > $o_crit% : CRITICAL";
    $exit_val=$ERRORS{"CRITICAL"};
} else {
    if ($cpu_used > $o_warn) {
        print " > $o_warn% : WARNING";
        $exit_val=$ERRORS{"WARNING"};
    }
}
print " < $o_warn% : OK" if ($exit_val eq $ERRORS{"OK"});
(defined($o_perf)) ?
   print " | cpu_prct_used=$cpu_used%;$o_warn;$o_crit\n"
 : print "\n";
exit $exit_val;