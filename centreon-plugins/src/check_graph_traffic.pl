#! /usr/bin/perl -w
#
# $Id: check_graph_traffic.pl,v 1.2 2005/07/27 22:21:49 Julio $
#
# Oreon's plugins are developped with GPL Licence :
# http://www.fsf.org/licenses/gpl.txt
# Developped by : Julien Mathis - Romain Le Merlus
#
# Modified for Oreon Project by : Mathieu Chateau - Christophe Coraboeuf
# Modified By Julien Mathis For Merethis Company
#
# The Software is provided to you AS IS and WITH ALL FAULTS.
# OREON makes no representation and gives no warranty whatsoever,
# whether express or implied, and without limitation, with regard to the quality,
# safety, contents, performance, merchantability, non-infringement or suitability for
# any particular or intended purpose of the Software found on the OREON web site.
# In no event will OREON be liable for any direct, indirect, punitive, special,
# incidental or consequential damages however they may arise and even if OREON has
# been previously advised of the possibility of such damages.

#
# Plugin init
#

use strict;
use Net::SNMP qw(:snmp oid_lex_sort);
use FindBin;
use lib "$FindBin::Bin";
use lib "/srv/nagios/libexec";
use utils qw($TIMEOUT %ERRORS &print_revision &support);

if (eval "require oreon" ) {
	use oreon qw(get_parameters create_rrd update_rrd &is_valid_serviceid);
	use vars qw($VERSION %oreon);
	%oreon=get_parameters();
} else {
    print "Unable to load oreon perl module\n";
    exit $ERRORS{'UNKNOWN'};
}

use vars qw($VERSION %oreon);
use vars qw(%oreon);
$VERSION = '$Revision: 1.2 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

use vars qw($PROGNAME);
use Getopt::Long;
use vars qw($opt_V $opt_h $opt_g $opt_v $opt_C $opt_b $opt_H $opt_D $opt_i $opt_n $opt_w $opt_c $opt_s $opt_S $opt_T $opt_step $step);

my $pathtorrdbase = $oreon{GLOBAL}{DIR_RRDTOOL};

#
# Plugin var init
#

my($proc, $proc_run, @test, $row, @laste_values, $last_check_time, $last_in_bits, $last_out_bits, @last_values, $update_time, $db_file, $in_traffic, $out_traffic, $in_usage, $out_usage);
my $pathtolibexecnt = $oreon{NAGIOS_LIBEXEC};

$PROGNAME = "check_graph_traffic";
sub print_help ();
sub print_usage ();

Getopt::Long::Configure('bundling');
GetOptions
    ("h"   => \$opt_h, "help"         => \$opt_h,
     "s"   => \$opt_s, "show"         => \$opt_s,
     "V"   => \$opt_V, "version"      => \$opt_V,
     "g"   => \$opt_g, "rrdgraph"     => \$opt_g,
     "rrd_step=s" => \$opt_step,
     "i=s" => \$opt_i, "interface=s"  => \$opt_i,
     "n"   => \$opt_n, "name"         => \$opt_n,
     "v=s" => \$opt_v, "snmp=s"       => \$opt_v,
     "C=s" => \$opt_C, "community=s"  => \$opt_C,
     "b=s" => \$opt_b, "bps=s"        => \$opt_b,
     "w=s" => \$opt_w, "warning=s"    => \$opt_w,
     "c=s" => \$opt_c, "critical=s"   => \$opt_c,
     "S=s" => \$opt_S, "ServiceId=s"  => \$opt_S,
     "T=s" => \$opt_T,
     "H=s" => \$opt_H, "hostname=s"   => \$opt_H);

if ($opt_V) {
    print_revision($PROGNAME,'$Revision: 1.2 $');
    exit $ERRORS{'OK'};
}

if ($opt_h) {
    print_help();
    exit $ERRORS{'OK'};
}

##################################################
#####      Verify Options
##

$opt_H = shift unless ($opt_H);
(print_usage() && exit $ERRORS{'OK'}) unless ($opt_H);

($opt_v) || ($opt_v = shift) || ($opt_v = "1");
my $snmp = $1 if ($opt_v =~ /(\d)/);

if ($opt_n && !$opt_i) {
    print "Option -n (--name) need option -i (--interface)\n";
    exit $ERRORS{'UNKNOWN'};
}

($opt_C) || ($opt_C = shift) || ($opt_C = "public");
($opt_i) || ($opt_i = shift) || ($opt_i = 2);
($opt_S) || ($opt_S = shift) || ($opt_S = 1);
my $ServiceId = is_valid_serviceid($opt_S);

($opt_b) || ($opt_b = shift) || ($opt_b = 95);
my $bps = $1 if ($opt_b =~ /([0-9]+)/);

($opt_c) || ($opt_c = shift) || ($opt_c = 95);
my $critical = $1 if ($opt_c =~ /([0-9]+)/);

($opt_w) || ($opt_w = shift) || ($opt_w = 80);
my $warning = $1 if ($opt_w =~ /([0-9]+)/);

my $interface = 0;
if ($opt_i =~ /([0-9]+)/ && !$opt_n){
    $interface = $1;
} elsif (!$opt_n) {
    print "Unknown -i number expected... or it doesn't exist, try another interface - number\n";
    exit $ERRORS{'UNKNOWN'};
}

if ($critical <= $warning){
    print "(--crit) must be superior to (--warn)";
    print_usage();
    exit $ERRORS{'OK'};
}

($opt_step) || ($opt_step = shift) || ($opt_step = "300");
$step = $1 if ($opt_step =~ /(\d+)/);

##################################################
#####           RRDTool var init
##

my $rrd = $pathtorrdbase.$ServiceId.".rrd";
my $start=time;

##################################################
#####           RRDTool create rrd
##

if ($opt_g) {
    if (! -e $rrd) {
         create_rrd ($rrd,2,$start,$step,"U","U","GAUGE");
    }
}

#################################################
#####            Plugin snmp requests
##

my $OID_DESC =$oreon{MIB2}{IF_DESC};

# create a SNMP session

my ($session, $error) = Net::SNMP->session(-hostname => $opt_H, -community => $opt_C, -version => $snmp);
if (!defined($session)) {
    print("UNKNOWN: SNMP Session : $error");
    exit $ERRORS{'UNKNOWN'};
}

#getting interface using its name instead of its oid index

if ($opt_n) {
    my $result = $session->get_table(Baseoid => $OID_DESC);
    if (!defined($result)) {
        printf("ERROR: Description Table : %s.\n", $session->error);
        $session->close;
        exit $ERRORS{'UNKNOWN'};
    }
    foreach my $key ( oid_lex_sort(keys %$result)) {
        if ($result->{$key} =~ m/$opt_i/) {
	    my @oid_list = split (/\./,$key);
	    $interface = pop (@oid_list) ;
	}
    }
}

my $OID_IN =$oreon{MIB2}{IF_IN_OCTET}.".".$interface;
my $OID_OUT = $oreon{MIB2}{IF_OUT_OCTET}.".".$interface;
my $OID_SPEED = $oreon{MIB2}{IF_SPEED}.".".$interface;

# Get desctiption table

if ($opt_s) {
    my $result = $session->get_table(Baseoid => $OID_DESC);
    if (!defined($result)) {
        printf("ERROR: Description Table : %s.\n", $session->error);
        $session->close;
        exit $ERRORS{'UNKNOWN'};
    }
    foreach my $key ( oid_lex_sort(keys %$result)) {
        my @oid_list = split (/\./,$key);
        my $index = pop (@oid_list) ;
        print "Interface $index :: $$result{$key}\n";
    }
    exit $ERRORS{'OK'};
}


#######  Get IN bytes

my $in_bits;
my $result = $session->get_request(-varbindlist => [$OID_IN]);
if (!defined($result)) {
    printf("ERROR: IN Bits :  %s", $session->error);
    if ($opt_n) { print " - You must specify interface name when option -n is used";}
    print ".\n";
    $session->close;
    exit $ERRORS{'UNKNOWN'};
}
$in_bits =  $result->{$OID_IN} * 8;


#######  Get OUT bytes

my $out_bits;
$result = $session->get_request(-varbindlist => [$OID_OUT]);
if (!defined($result)) {
    printf("ERROR: Out Bits : %s", $session->error);
    if ($opt_n) { print " - You must specify interface name when option -n is used";}
    print ".\n";
    $session->close;
    exit $ERRORS{'UNKNOWN'};
}
$out_bits = $result->{$OID_OUT} * 8;


#######  Get SPEED of interface

my $speed_card;
$result = $session->get_request(-varbindlist => [$OID_SPEED]);
if (!defined($result)) {
    printf("ERROR: Interface Speed : %s", $session->error);
    if ($opt_n) { print " - You must specify interface name when option -n is used";}
    print ".\n";
    $session->close;
    exit $ERRORS{'UNKNOWN'};
}

if (defined($opt_T)){
	$speed_card = $opt_T * 1000000;
} else {
	$speed_card = $result->{$OID_SPEED};
}
#############################################
#####          Plugin return code
##

$last_in_bits = 0;
$last_out_bits  = 0;

my $flg_created;

if (-e "/tmp/traffic_if".$interface."_".$opt_H) {
    open(FILE,"<"."/tmp/traffic_if".$interface."_".$opt_H);
    while($row = <FILE>){
	@last_values = split(":",$row);
	$last_check_time = $last_values[0];
	$last_in_bits = $last_values[1];
	$last_out_bits = $last_values[2];
	$flg_created = 1;
    }
    close(FILE);
} else {
    $flg_created = 0;
}

$update_time = time;

unless (open(FILE,">"."/tmp/traffic_if".$interface."_".$opt_H)){
    print "Unknown - /tmp/traffic_if".$interface."_".$opt_H. " !\n";
    exit $ERRORS{"UNKNOWN"};
}
print FILE "$update_time:$in_bits:$out_bits";
close(FILE);

if ($flg_created eq 0){
    print "First execution : Buffer in creation.... \n";
    exit($ERRORS{"UNKNOWN"});
}


## Bandwith = IN + OUT / Delta(T) = 6 Mb/s
## (100 * Bandwith) / (2(si full duplex) * Ispeed)
## Count must round at 4294967296 
##

if (($in_bits - $last_in_bits > 0) && defined($last_in_bits)) {
	my $total = 0;
	if ($in_bits - $last_in_bits < 0){
		$total = 4294967296 - $last_in_bits + $in_bits;
	} else {
		$total = $in_bits - $last_in_bits;
	}
    my $pct_in_traffic = $in_traffic = abs($total / (time - $last_check_time));
} else {
    $in_traffic = 0;
} 

if ($out_bits - $last_out_bits > 0 && defined($last_out_bits)) {
    my $total = 0;
    if ($out_bits - $last_out_bits < 0){
	$total = 4294967296 - $last_out_bits + $out_bits;
    } else {
	$total = $out_bits - $last_out_bits;
    }
    my $pct_out_traffic = $out_traffic = abs($total / (time - $last_check_time));
} else {
    $out_traffic = 0;
}

if ( $speed_card != 0 ) {
    $in_usage = sprintf("%.1f",($in_traffic*100) / $speed_card);
    $out_usage = sprintf("%.1f",($out_traffic*100) / $speed_card);
    ## RRDtools update
    if ($opt_g) {
        $start = time;
    	update_rrd($rrd,$start, sprintf("%.1f",abs($in_traffic)), sprintf("%.1f",abs($out_traffic)));
    }
}

my $in_prefix = "";
my $out_prefix = "";

my $in_perfparse_traffic = $in_traffic;
my $out_perfparse_traffic = $out_traffic;

if ($in_traffic > 1000) {
    $in_traffic = $in_traffic / 1000;
    $in_prefix = "k";
    if($in_traffic > 1000){
		$in_traffic = $in_traffic / 1000;
		$in_prefix = "M";
    }
    if($in_traffic > 1000){
		$in_traffic = $in_traffic / 1000;
		$in_prefix = "G";
    }
}

if ($out_traffic > 1000){
    $out_traffic = $out_traffic / 1000;
    $out_prefix = "k";
    if ($out_traffic > 1000){
		$out_traffic = $out_traffic / 1000;
		$out_prefix = "M";
	}
    if ($out_traffic > 1000){
		$out_traffic = $out_traffic / 1000;
		$out_prefix = "G";
    }
}

my $in_bits_unit = "";
$in_bits = $in_bits/1048576;
if ($in_bits > 1000){
    $in_bits = $in_bits / 1000;
    $in_bits_unit = "G";
} else { 
    $in_bits_unit = "M";
}

my $out_bits_unit = "";
$out_bits = $out_bits/1048576;
if ($out_bits > 1000){
    $out_bits = $out_bits / 1000;
    $out_bits_unit = "G";
} else {
    $out_bits_unit = "M";
}


if ( $speed_card == 0 ) {
    print "CRITICAL: Interface speed equal 0! Interface must be down.|traffic_in=0B/s traffic_out=0B/s\n";
    exit($ERRORS{"CRITICAL"});
}

#####################################
#####        Display result
##


my $in_perfparse_traffic_str = sprintf("%.1f",abs($in_perfparse_traffic));
my $out_perfparse_traffic_str = sprintf("%.1f",abs($out_perfparse_traffic));

$in_perfparse_traffic_str =~ s/\./,/g;
$out_perfparse_traffic_str =~ s/\./,/g;

my $status = "OK";

if (($in_usage > $critical) or ($out_usage > $critical)){
	$status = "CRITICAL";
}

if(($in_usage > $warning) or ($out_usage > $warning)){
	$status = "WARNING";
}

		
printf("Traffic In : %.2f ".$in_prefix."b/s (".$in_usage." %%), Out : %.2f ".$out_prefix."b/s (".$out_usage." %%) - ", $in_traffic, $out_traffic);
printf("Total RX Bits In : %.2f ".$in_bits_unit."B, Out : %.2f ".$out_bits_unit."b", $in_bits, $out_bits);
printf("|traffic_in=".$in_perfparse_traffic_str."Bits/s traffic_out=".$out_perfparse_traffic_str."Bits/s\n");
exit($ERRORS{$status});




sub print_usage () {
    print "\nUsage:\n";
    print "$PROGNAME\n";
    print "   -H (--hostname)   Hostname to query - (required)\n";
    print "   -C (--community)  SNMP read community (defaults to public,\n";
    print "                     used with SNMP v1 and v2c\n";
    print "   -v (--snmp_version)  1 for SNMP v1 (default)\n";
    print "                        2 for SNMP v2c\n";
    print "   -g (--rrdgraph)   create a rrd base and add datas into this one\n";
    print "   --rrd_step	    Specifies the base interval in seconds with which data will be fed into the RRD (300 by default)\n";
    print "   -D (--directory)  Path to rrdatabase (or create the .rrd in this directory)\n";
    print "                     by default: ".$pathtorrdbase."\n";
    print "                     (The path is valid with spaces '/my\ path/...')\n";
    print "                     (The path is valid with spaces '/my\ path/...')\n";
    print "   -s (--show)       Describes all interfaces number (debug mode)\n";
    print "   -i (--interface)  Set the interface number (2 by default)\n";
    print "   -n (--name)       Allows to use interface name with option -d instead of interface oid index\n";
    print "                     (ex: -i \"eth0\" -n, -i \"VMware Virtual Ethernet Adapter for VMnet8\" -n\n";
    print "                     (choose an unique expression for each interface)\n";
    print "   -w (--warn)       Signal strength at which a warning message will be generated\n";
    print "                     (default 80)\n";
    print "   -c (--crit)       Signal strength at which a critical message will be generated\n";
    print "   -T                Max Banwidth\n";
    print "                     (default 95)\n";
    print "   -S (--ServiceId)  Oreon Service Id\n";
    print "   -V (--version)    Plugin version\n";
    print "   -h (--help)       usage help\n";
}

sub print_help () {
    print "##########################################\n";
    print "#  Copyright (c) 2004-2006 Oreon         #\n";
    print "#  Bugs to http://www.oreon-project.org/ #\n";
    print "##########################################\n";
    print_usage();
    print "\n";
}
