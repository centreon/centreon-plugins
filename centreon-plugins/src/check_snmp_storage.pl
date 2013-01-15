#!/usr/bin/perl -w
############################## check_snmp_storage ##############
# Version : 1.3.3
# Date :  Jun 1 2007
# Author  : Patrick Proy ( patrick at proy.org)
# Help : http://nagios.manubulon.com
# Licence : GPL - http://www.fsf.org/licenses/gpl.txt
# TODO : 
# Contribs : Dimo Velev, Makina Corpus, A. Greiner-Bär
#################################################################
#
# help : ./check_snmp_storage -h
 
use strict;
use Getopt::Long;
require "@NAGIOS_PLUGINS@/Centreon/SNMP/Utils.pm";

# Nagios specific

use lib "@NAGIOS_PLUGINS@";
use utils qw(%ERRORS $TIMEOUT);
#my $TIMEOUT = 15;
#my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

my %OPTION = (
    "host" => undef,
    "snmp-community" => "public", "snmp-version" => 1, "snmp-port" => 161, 
    "snmp-auth-key" => undef, "snmp-auth-user" => undef, "snmp-auth-password" => undef, "snmp-auth-protocol" => "MD5",
    "snmp-priv-key" => undef, "snmp-priv-password" => undef, "snmp-priv-protocol" => "DES",
    "maxrepetitions" => undef,
    "64-bits" => undef,
);
my $session_params;

# SNMP Datas
my $storage_table= '1.3.6.1.2.1.25.2.3.1';
my $storagetype_table = '1.3.6.1.2.1.25.2.3.1.2';
my $index_table = '1.3.6.1.2.1.25.2.3.1.1';
my $descr_table = '1.3.6.1.2.1.25.2.3.1.3';
my $size_table = '1.3.6.1.2.1.25.2.3.1.5.';
my $used_table = '1.3.6.1.2.1.25.2.3.1.6.';
my $alloc_units = '1.3.6.1.2.1.25.2.3.1.4.';

#Storage types definition  - from /usr/share/snmp/mibs/HOST-RESOURCES-TYPES.txt
my %hrStorage;
$hrStorage{"Other"} = '1.3.6.1.2.1.25.2.1.1';
$hrStorage{"1.3.6.1.2.1.25.2.1.1"} = 'Other';
$hrStorage{"Ram"} = '1.3.6.1.2.1.25.2.1.2';
$hrStorage{"1.3.6.1.2.1.25.2.1.2"} = 'Ram';
$hrStorage{"VirtualMemory"} = '1.3.6.1.2.1.25.2.1.3';
$hrStorage{"1.3.6.1.2.1.25.2.1.3"} = 'VirtualMemory';
$hrStorage{"FixedDisk"} = '1.3.6.1.2.1.25.2.1.4';
$hrStorage{"1.3.6.1.2.1.25.2.1.4"} = 'FixedDisk';
$hrStorage{"RemovableDisk"} = '1.3.6.1.2.1.25.2.1.5';
$hrStorage{"1.3.6.1.2.1.25.2.1.5"} = 'RemovableDisk';
$hrStorage{"FloppyDisk"} = '1.3.6.1.2.1.25.2.1.6';
$hrStorage{"1.3.6.1.2.1.25.2.1.6"} = 'FloppyDisk';
$hrStorage{"CompactDisk"} = '1.3.6.1.2.1.25.2.1.7';
$hrStorage{"1.3.6.1.2.1.25.2.1.7"} = 'CompactDisk';
$hrStorage{"RamDisk"} = '1.3.6.1.2.1.25.2.1.8';
$hrStorage{"1.3.6.1.2.1.25.2.1.8"} = 'RamDisk';
$hrStorage{"FlashMemory"} = '1.3.6.1.2.1.25.2.1.9';
$hrStorage{"1.3.6.1.2.1.25.2.1.9"} = 'FlashMemory';
$hrStorage{"NetworkDisk"} = '1.3.6.1.2.1.25.2.1.10';
$hrStorage{"1.3.6.1.2.1.25.2.1.10"} = 'NetworkDisk';

# Globals

my $Name='check_snmp_storage';
my $Version='1.3.3';

my $o_descr = 	undef; 		# description filter 
my $o_storagetype = undef;    # parse storage type also
my $o_warn = 	undef; 		# warning limit 
my $o_crit=	undef; 		# critical limit
my $o_help=	undef; 		# wan't some help ?
my $o_type=	undef;		# pl, pu, mbl, mbu 
my @o_typeok=   ("pu","pl","bu","bl"); # valid values for o_type
my $o_verb=	undef;		# verbose mode
my $o_version=  undef;          # print version
my $o_noreg=	undef;		# Do not use Regexp for name
my $o_sum=	undef;		# add all storage before testing
my $o_index=	undef;		# Parse index instead of description
my $o_negate=	undef;		# Negate the regexp if set
my $o_timeout=  5;            	# Default 5s Timeout
my $o_perf=	undef;		# Output performance data
my $o_short=	undef;	# Short output parameters
my @o_shortL=	undef;		# output type,where,cut
my $o_reserve=	0;              # % reserved blocks (A. Greiner-Bär patch)
my $o_giga=		undef;	# output and levels in gigabytes instead of megabytes

# functions

sub p_version { print "$Name version : $Version\n"; }

sub print_usage {
    print "Usage: $Name [-v] -H <host> -C <snmp_community> [-2] | (-l login -x passwd) [-p <port>] -m <name in desc_oid> [-q storagetype] -w <warn_level> -c <crit_level> [-t <timeout>] [-T pl|pu|bl|bu ] [-r -s -i -G] [-e] [-S 0|1[,1,<car>]] [-o <octet_length>] [-R <% reserved>]\n";
}

sub round ($$) {
    sprintf "%.$_[1]f", $_[0];
}

sub is_pattern_valid { # Test for things like "<I\s*[^>" or "+5-i"
    my $pat = shift;
    if (!defined($pat)) { $pat=" ";} # Just to get rid of compilation time warnings
    return eval { "" =~ /$pat/; 1 } || 0;
}

# Get the alarm signal (just in case snmp timout screws up)
$SIG{'ALRM'} = sub {
    print ("ERROR: General time-out (Alarm signal)\n");
    exit $ERRORS{"UNKNOWN"};
};

sub isnnum { # Return true if arg is not a number
    my $num = shift;
    if ( $num =~ /^-?(\d+\.?\d*)|(^\.\d+)$/ ) { return 0 ;}
    return 1;
}

sub help {
   print "\nSNMP Disk Monitor for Nagios version ",$Version,"\n";
   print "(c)2004-2007 Patrick Proy\n\n";
   print_usage();
   print <<EOT;
By default, plugin will monitor %used on drives :
warn if %used > warn and critical if %used > crit
-v, --verbose
   print extra debugging information (and lists all storages)
-h, --help
   print this help message
-H, --hostname=HOST
   name or IP address of host to check
-C, --community=COMMUNITY NAME
   community name for the host's SNMP agent (implies SNMP v1)
-l, --login=LOGIN ; -x, --passwd=PASSWD
   Login and auth password for snmpv3 authentication 
   If no priv password exists, implies AuthNoPriv 
-p, --port=PORT
   SNMP port (Default 161)
-m, --name=NAME
   Name in description OID (can be mounpoints '/home' or 'Swap Space'...)
   This is treated as a regexp : -m /var will match /var , /var/log, /opt/var ...
   Test it before, because there are known bugs (ex : trailling /)
   No trailing slash for mountpoints !
-q, --storagetype=[Other|Ram|VirtualMemory|FixedDisk|RemovableDisk|FloppyDisk
                    CompactDisk|RamDisk|FlashMemory|NetworkDisk]
   Also check the storage type in addition of the name
   It is possible to use regular expressions ( "FixedDisk|FloppyDisk" )
-r, --noregexp
   Do not use regexp to match NAME in description OID
-s, --sum
   Add all storages that match NAME (used space and total space)
   THEN make the tests.
-i, --index
   Parse index table instead of description table to select storage
-e, --exclude
   Select all storages except the one(s) selected by -m
   No action on storage type selection
-T, --type=TYPE
   pl : calculate percent left
   pu : calculate percent used (Default)
   bl : calculate MegaBytes left
   bu : calculate MegaBytes used
-w, --warn=INTEGER
   percent / MB of disk used to generate WARNING state
   you can add the % sign 
-c, --critical=INTEGER
   percent / MB of disk used to generate CRITICAL state
   you can add the % sign 
-R, --reserved=INTEGER
   % reserved blocks for superuser
   For ext2/3 filesystems, it is 5% by default
-G, --gigabyte
   output, warning & critical levels in gigabytes
-f, --perfparse
   Perfparse compatible output
-S, --short=<type>[,<where>,<cut>]
   <type>: Make the output shorter :
     0 : only print the global result except the disk in warning or critical
         ex: "< 80% : OK"
     1 : Don't print all info for every disk 
         ex : "/ : 66 %used  (<  80) : OK"
   <where>: (optional) if = 1, put the OK/WARN/CRIT at the beginning
   <cut>: take the <n> first caracters or <n> last if n<0
-o, --octetlength=INTEGER
  max-size of the SNMP message, usefull in case of Too Long responses.
  Be carefull with network filters. Range 484 - 65535, default are
  usually 1472,1452,1460 or 1440.   
-t, --timeout=INTEGER
   timeout for SNMP in seconds (Default: 5)
-V, --version
   prints version number
Note : 
  with T=pu or T=bu : OK < warn < crit
  with T=pl ot T=bl : crit < warn < OK
  
  If multiple storage are selected, the worse condition will be returned
  i.e if one disk is critical, the return is critical
 
  example : 
  Browse storage list : <script> -C <community> -H <host> -m <anything> -w 1 -c 2 -v 
  the -m option allows regexp in perl format : 
  Test drive C,F,G,H,I on Windows 	: -m ^[CFGHI]:    
  Test all mounts containing /var      	: -m /var
  Test all mounts under /var      	: -m ^/var
  Test only /var                 	: -m /var -r
  Test all swap spaces			: -m ^Swap
  Test all but swap spaces		: -m ^Swap -e

EOT
}

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
        "64-bits"                   => \$OPTION{'64-bits'},
		'v'     => \$o_verb,		'verbose'	=> \$o_verb,
        'h'     => \$o_help,    	'help'        	=> \$o_help,
        'c:s'   => \$o_crit,    	'critical:s'	=> \$o_crit,
        'w:s'   => \$o_warn,    	'warn:s'	=> \$o_warn,
        't:i'   => \$o_timeout,       	'timeout:i'     => \$o_timeout,
        'm:s'   => \$o_descr,		'name:s'	=> \$o_descr,
        'T:s'	=> \$o_type,		'type:s'	=> \$o_type,
        'r'     => \$o_noreg,           'noregexp'      => \$o_noreg,
        's'     => \$o_sum,           	'sum'      	=> \$o_sum,
        'i'     => \$o_index,          	'index'      	=> \$o_index,
        'e'     => \$o_negate,         	'exclude'    	=> \$o_negate,
        'V'     => \$o_version,         'version'       => \$o_version,
		'q:s'  	=> \$o_storagetype,	'storagetype:s'=> \$o_storagetype,
        'S:s'   => \$o_short,         	'short:s'       => \$o_short,
        'f'     => \$o_perf,		'perfparse'	=> \$o_perf,
        'R:i'	=> \$o_reserve,	        'reserved:i'	=> \$o_reserve,
        'G'     => \$o_giga,	        'gigabyte'	=> \$o_giga
    );
    if (defined($o_help) ) { help(); exit $ERRORS{"UNKNOWN"}};
    if (defined($o_version) ) { p_version(); exit $ERRORS{"UNKNOWN"}};
    # check mount point regexp
    if (!is_pattern_valid($o_descr)) 
	{ print "Bad pattern for mount point !\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}    
    # check snmp information
    ($session_params) = Centreon::SNMP::Utils::check_snmp_options($ERRORS{'UNKNOWN'}, \%OPTION);
    # Check types
    if ( !defined($o_type) ) { $o_type="pu" ;}
    if ( ! grep( /^$o_type$/ ,@o_typeok) ) { print_usage(); exit $ERRORS{"UNKNOWN"}};   
    # Check compulsory attributes
    if ( ! defined($o_descr) || !defined($o_warn) || 
	!defined($o_crit)) { print_usage(); exit $ERRORS{"UNKNOWN"}};
    # Get rid of % sign if any
    $o_warn =~ s/\%//; 
    $o_crit =~ s/\%//;
    # Check for positive numbers
    if (($o_warn < 0) || ($o_crit < 0)) { print " warn and critical > 0 \n";print_usage(); exit $ERRORS{"UNKNOWN"}};
    # check if warn or crit  in % and MB is tested
    if (  ( ( $o_warn =~ /%/ ) || ($o_crit =~ /%/)) && ( ( $o_type eq 'bu' ) || ( $o_type eq 'bl' ) ) ) {
	print "warning or critical cannot be in % when MB are tested\n";
	print_usage(); exit $ERRORS{"UNKNOWN"};
    }
    # Check warning and critical values
    if ( ( $o_type eq 'pu' ) || ( $o_type eq 'bu' )) {
	if ($o_warn >= $o_crit) { print " warn < crit if type=",$o_type,"\n";print_usage(); exit $ERRORS{"UNKNOWN"}};
    }
    if ( ( $o_type eq 'pl' ) || ( $o_type eq 'bl' )) {
	if ($o_warn <= $o_crit) { print " warn > crit if type=",$o_type,"\n";print_usage(); exit $ERRORS{"UNKNOWN"}};
    }
    if ( ($o_warn < 0 ) || ($o_crit < 0 )) { print "warn and crit must be > 0\n";print_usage(); exit $ERRORS{"UNKNOWN"}}; 
    if ( ( $o_type eq 'pl' ) || ( $o_type eq 'pu' )) {
        if ( ($o_warn > 100 ) || ($o_crit > 100 )) { print "percent must be < 100\n";print_usage(); exit $ERRORS{"UNKNOWN"}}; 
    } 
	# Check short values
	if ( defined ($o_short)) {
 	  @o_shortL=split(/,/,$o_short);
	  if ((isnnum($o_shortL[0])) || ($o_shortL[0] !=0) && ($o_shortL[0]!=1)) {
	    print "-S first option must be 0 or 1\n";print_usage(); exit $ERRORS{"UNKNOWN"};
	  }
	  if (defined ($o_shortL[1])&& $o_shortL[1] eq "") {$o_shortL[1]=undef};
	  if (defined ($o_shortL[2]) && isnnum($o_shortL[2]))
	    {print "-S last option must be an integer\n";print_usage(); exit $ERRORS{"UNKNOWN"};}
	}
    #### reserved blocks checks (A. Greiner-Bär patch).
    if (defined ($o_reserve) && (isnnum($o_reserve) || $o_reserve > 99 || $o_reserve < 0 )) {
		print "reserved blocks must be < 100 and >= 0\n";print_usage(); exit $ERRORS{"UNKNOWN"};
    }
}

########## MAIN #######

check_options();

# Check gobal timeout
if (defined($TIMEOUT)) {
    verb("Alarm at $TIMEOUT");
    alarm($TIMEOUT);
} else {
    verb("no timeout defined : $o_timeout + 10");
    alarm ($o_timeout+10);
}

# Connect to host
my $session = Centreon::SNMP::Utils::connection($ERRORS{'UNKNOWN'}, $session_params);
my $resultat=undef;
my $stype=undef;

if (defined ($o_index)){
    $resultat = Centreon::SNMP::Utils::get_snmp_table($index_table, $session, $ERRORS{'UNKNOWN'}, \%OPTION);
} else {
    $resultat = Centreon::SNMP::Utils::get_snmp_table($descr_table, $session, $ERRORS{'UNKNOWN'}, \%OPTION);
}
#get storage typetable for reference
if (defined($o_storagetype)){
    $stype = Centreon::SNMP::Utils::get_snmp_table($storagetype_table, $session, $ERRORS{'UNKNOWN'}, \%OPTION);
}

my @tindex = undef;
my @oids = undef;
my @descr = undef;
my $num_int = 0;
my $count_oid = 0;
my $test = undef;
my $perf_out=	undef;
# Select storage by regexp of exact match
# and put the oid to query in an array

verb("Filter : $o_descr");

foreach my $key ( keys %$resultat) {
    verb("OID : $key, Desc : $$resultat{$key}");
    # test by regexp or exact match / include or exclude
    if (defined($o_negate)) {
        $test = defined($o_noreg)
            ? $$resultat{$key} ne $o_descr
            : $$resultat{$key} !~ /$o_descr/;
    } else {
        $test = defined($o_noreg)
            ? $$resultat{$key} eq $o_descr
            : $$resultat{$key} =~ /$o_descr/;
    }  
    if ($test) {
        # get the index number of the interface
        my @oid_list = split (/\./,$key);
        $tindex[$num_int] = pop (@oid_list);
        # Check if storage type is OK
        if (defined($o_storagetype)) {
            my($skey)=$storagetype_table.".".$tindex[$num_int];
            verb("   OID : $skey, Storagetype: $hrStorage{$$stype{$skey}} ?= $o_storagetype");
            if ( $hrStorage{$$stype{$skey}} !~ $o_storagetype) {
                $test=undef;
            }
        }
        if ($test) {
            # get the full description
            $descr[$num_int]=$$resultat{$key};
            # put the oid in an array
            $oids[$count_oid++]=$size_table . $tindex[$num_int];
            $oids[$count_oid++]=$used_table . $tindex[$num_int];
            $oids[$count_oid++]=$alloc_units . $tindex[$num_int];

            verb("   Name : $descr[$num_int], Index : $tindex[$num_int]");
            $num_int++;
        }
    }
}
verb("storages selected : $num_int");
if ( $num_int == 0 ) { print "Unknown storage : $o_descr : ERROR\n" ; exit $ERRORS{"UNKNOWN"};}

my $result = Centreon::SNMP::Utils::get_snmp_leef(\@oids, $session, $ERRORS{'UNKNOWN'});

# Only a few ms left...
alarm(0);

# Sum everything if -s and more than one storage
if ( defined ($o_sum) && ($num_int > 1) ) {
    verb("Adding all entries");
    $$result{$size_table . $tindex[0]} *= $$result{$alloc_units . $tindex[0]};
    $$result{$used_table . $tindex[0]} *= $$result{$alloc_units . $tindex[0]};
    $$result{$alloc_units . $tindex[0]} = 1;
    for (my $i=1;$i<$num_int;$i++) {
        $$result{$size_table . $tindex[0]} += ($$result{$size_table . $tindex[$i]} 
            * $$result{$alloc_units . $tindex[$i]}); 
        $$result{$used_table . $tindex[0]} += ($$result{$used_table . $tindex[$i]}
            * $$result{$alloc_units . $tindex[$i]});
    }
    $num_int=1;
    $descr[0]="Sum of all $o_descr";
}

my $i=undef;
my $warn_state=0;
my $crit_state=0;
my ($p_warn,$p_crit);
my $output=undef;
my $output_metric_val = 1024**2;
my $output_metric = "M";
# Set the metric 
if (defined($o_giga)) {
    $output_metric_val *= 1024;
    $output_metric='G';
}

for ($i=0;$i<$num_int;$i++) {
    verb("Descr : $descr[$i]");
    verb("Size :  $$result{$size_table . $tindex[$i]}");
    verb("Used : $$result{$used_table . $tindex[$i]}");
    verb("Alloc : $$result{$alloc_units . $tindex[$i]}");
    if (!defined($$result{$size_table . $tindex[$i]}) || 
        !defined($$result{$used_table . $tindex[$i]}) || 
        !defined ($$result{$alloc_units . $tindex[$i]})) {
        print "Data not fully defined for storage ",$descr[$i]," : UNKNOWN\n";
        exit $ERRORS{"UNKNOWN"};
    }
    my $to = $$result{$size_table . $tindex[$i]} * ( ( 100 - $o_reserve ) / 100 ) * $$result{$alloc_units . $tindex[$i]} / $output_metric_val;
    my $pu=undef;
    if ( $$result{$used_table . $tindex[$i]} != 0 ) {
        $pu = $$result{$used_table . $tindex[$i]}* 100 /  ( $$result{$size_table . $tindex[$i]} * ( 100 - $o_reserve ) / 100 );
    }else {
        $pu=0;
    } 
    my $bu = $$result{$used_table . $tindex[$i]} *  $$result{$alloc_units . $tindex[$i]} / $output_metric_val;
    my $pl = 100 - $pu;
    my $bl = ( ( $$result{$size_table . $tindex[$i]} * ( ( 100 - $o_reserve ) / 100 ) - ( $$result{$used_table . $tindex[$i]} ) ) * $$result{$alloc_units . $tindex[$i]} / $output_metric_val );
    # add a ' ' if some data exists in $perf_out
    $perf_out .= " " if (defined ($perf_out)) ;
    ##### Ouputs and checks
    # Keep complete description fot performance output (in MB)
    my $Pdescr=$descr[$i];
    $Pdescr =~ s/[`~!\$%\^&\*'"<>|\?,\(= )]/_/g; 
    ##### TODO : subs "," with something
    if (defined($o_shortL[2])) {
        if ($o_shortL[2] < 0) {$descr[$i]=substr($descr[$i],$o_shortL[2]);}
        else {$descr[$i]=substr($descr[$i],0,$o_shortL[2]);}   
    }
    if ($o_type eq "pu") { # Checks % used
        my $locstate=0;
        $p_warn=$o_warn*$to/100;$p_crit=$o_crit*$to/100; 
        (($pu >= $o_crit) && ($locstate=$crit_state=1))
            || (($pu >= $o_warn) && ($locstate=$warn_state=1));
        if (defined($o_shortL[2])) {}
        if (!defined($o_shortL[0]) || ($locstate==1)) { # print full output if warn or critical state
            $output.=sprintf ("%s: %.0f%%used(%.0f%sB/%.0f%sB) ",$descr[$i],$pu,$bu,$output_metric,$to,$output_metric);
        } elsif ($o_shortL[0] == 1) {
            $output.=sprintf ("%s: %.0f%% ",$descr[$i],$pu);
        }
    }

    if ($o_type eq 'bu') { # Checks MBytes used
        my $locstate=0;
        $p_warn=$o_warn;$p_crit=$o_crit;
        ( ($bu >= $o_crit) && ($locstate=$crit_state=1) ) 
            || ( ($bu >= $o_warn) && ($locstate=$warn_state=1) );
        if (!defined($o_shortL[0]) || ($locstate==1)) { # print full output if warn or critical state
            $output.=sprintf("%s: %.0f%sBused/%.0f%sB (%.0f%%) ",$descr[$i],$bu,$output_metric,$to,$output_metric,$pu);
        } elsif ($o_shortL[0] == 1) {
            $output.=sprintf("%s: %.0f%sB ",$descr[$i],$bu,$output_metric);
        } 
    }

    if ($o_type eq 'bl') {
        my $locstate=0;
        $p_warn=$to-$o_warn;$p_crit=$to-$o_crit;
        ( ($bl <= $o_crit) && ($locstate=$crit_state=1) ) 
            || ( ($bl <= $o_warn) && ($locstate=$warn_state=1) );
        if (!defined($o_shortL[0]) || ($locstate==1)) { # print full output if warn or critical state
            $output.=sprintf ("%s: %.0f%sBleft/%.0f%sB (%.0f%%) ",$descr[$i],$bl,$output_metric,$to,$output_metric,$pl);
        } elsif ($o_shortL[0] == 1) {
            $output.=sprintf ("%s: %.0f%sB ",$descr[$i],$bl,$output_metric);
        } 
    }

    if ($o_type eq 'pl') {
        my $locstate=0;
        $p_warn=(100-$o_warn)*$to/100;$p_crit=(100-$o_crit)*$to/100;
        ( ($pl <= $o_crit) && ($locstate=$crit_state=1) ) 
            || ( ($pl <= $o_warn) && ($locstate=$warn_state=1) );
        if (!defined($o_shortL[0]) || ($locstate==1)) { # print full output if warn or critical state
            $output.=sprintf ("%s: %.0f%%left(%.0f%sB/%.0f%sB) ",$descr[$i],$pl,$bl,$output_metric,$to,$output_metric);
        } elsif ($o_shortL[0] == 1) {
            $output.=sprintf ("%s: %.0f%% ",$descr[$i],$pl);
        } 
    }
    # Performance output (in MB)
    $perf_out .= "'".$Pdescr. "'=" . round($bu,0) . $output_metric ."B;" . round($p_warn,0) 
    . ";" . round($p_crit,0) . ";0;" . round($to,0);
}

verb ("Perf data : $perf_out");

my $comp_oper=undef;
my $comp_unit=undef;
($o_type eq "pu") && ($comp_oper ="<") && ($comp_unit ="%");
($o_type eq "pl") && ($comp_oper =">") && ($comp_unit ="%");
($o_type eq "bu") && ($comp_oper ="<") && ($comp_unit = $output_metric."B");
($o_type eq 'bl') && ($comp_oper =">") && ($comp_unit =$output_metric."B");

if (!defined ($output)) { $output="All selected storages "; }

if ( $crit_state == 1) {
    $comp_oper = ($comp_oper eq "<") ? ">" : "<";  # Inverse comp operator
    if (defined($o_shortL[1])) {
        print "CRITICAL : (",$comp_oper,$o_crit,$comp_unit,") ",$output;
    } else {
        print $output,"(",$comp_oper,$o_crit,$comp_unit,") : CRITICAL";
    }
    (defined($o_perf)) ?  print " | ",$perf_out,"\n" : print "\n";
    exit $ERRORS{"CRITICAL"};
}
if ( $warn_state == 1) {
    $comp_oper = ($comp_oper eq "<") ? ">" : "<";  # Inverse comp operator
    if (defined($o_shortL[1])) {
        print "WARNING : (",$comp_oper,$o_warn,$comp_unit,") ",$output;
    } else {
        print $output,"(",$comp_oper,$o_warn,$comp_unit,") : WARNING";
    }
    (defined($o_perf)) ?  print " | ",$perf_out,"\n" : print "\n";
    exit $ERRORS{"WARNING"};
}
if (defined($o_shortL[1])) {
    print "OK : (",$comp_oper,$o_warn,$comp_unit,") ",$output;
} else {
    print $output,"(",$comp_oper,$o_warn,$comp_unit,") : OK";
}
(defined($o_perf)) ? print " | ",$perf_out,"\n" : print "\n";

exit $ERRORS{"OK"};

