#! /usr/bin/perl -w
###################################################################
# Oreon is developped with GPL Licence 2.0 
#
# GPL License: http://www.gnu.org/licenses/gpl.txt
#
# Developped by : Julien Mathis - Romain Le Merlus 
#                 Christophe Coraboeuf
#
###################################################################
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
#    For information : contact@merethis.com
####################################################################
#
# Script init
#

use strict;
use Net::SNMP qw(:snmp oid_lex_sort);
use FindBin;
use lib "$FindBin::Bin";
use lib "/srv/nagios/libexec";
use utils qw($TIMEOUT %ERRORS &print_revision &support);
if (eval "require oreon" ) {
    use oreon qw(get_parameters);
    use vars qw(%oreon);
    %oreon=get_parameters();
} else {
	print "Unable to load oreon perl module\n";
    exit $ERRORS{'UNKNOWN'};
}
use vars qw($PROGNAME);
use Getopt::Long;
use vars qw($opt_V $opt_h $opt_v $opt_C $opt_b $opt_H $opt_D $opt_i $opt_n $opt_w $opt_c $opt_s $opt_T);

# Plugin var init

my($proc, $proc_run, @test, $row, @laste_values, $last_check_time, $last_in_bits, $last_out_bits, @last_values, $update_time, $db_file, $in_traffic, $out_traffic, $in_usage, $out_usage);

$PROGNAME = "check_graph_traffic";
sub print_help ();
sub print_usage ();

Getopt::Long::Configure('bundling');
GetOptions
    ("h"   => \$opt_h, "help"         => \$opt_h,
     "s"   => \$opt_s, "show"         => \$opt_s,
     "V"   => \$opt_V, "version"      => \$opt_V,
     "i=s" => \$opt_i, "interface=s"  => \$opt_i,
     "n"   => \$opt_n, "name"         => \$opt_n,
     "v=s" => \$opt_v, "snmp=s"       => \$opt_v,
     "C=s" => \$opt_C, "community=s"  => \$opt_C,
     "b=s" => \$opt_b, "bps=s"        => \$opt_b,
     "w=s" => \$opt_w, "warning=s"    => \$opt_w,
     "c=s" => \$opt_c, "critical=s"   => \$opt_c,
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

if (!$opt_H) {
print_usage();
exit $ERRORS{'OK'};
}
my $snmp = "1";
if ($opt_v && $opt_v =~ /(\d)/) {
$snmp = $opt_v;
}

if ($opt_n && !$opt_i) {
    print "Option -n (--name) need option -i (--interface)\n";
    exit $ERRORS{'UNKNOWN'};
}

if (!$opt_C) {
$opt_C = "public";
}

if (!$opt_i) {
$opt_i = 2;
}

if (!$opt_b) {
$opt_b = 95;
}

if ($opt_b =~ /([0-9]+)/) {
my $bps = $1;
}
my $critical = 95;
if ($opt_c && $opt_c =~ /[0-9]+/) {
$critical = $opt_c;
}
my $warning = 80;
if ($opt_w && $opt_w =~ /[0-9]+/) {
$warning = $opt_w;
}
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

my $flg_created = 0;

if (-e "/tmp/oreon_traffic_if".$interface."_".$opt_H) {
    open(FILE,"<"."/tmp/oreon_traffic_if".$interface."_".$opt_H);
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

$update_time = time();

unless (open(FILE,">"."/tmp/oreon_traffic_if".$interface."_".$opt_H)){
    print "Unknown - /tmp/oreon_traffic_if".$interface."_".$opt_H. " !\n";
    exit $ERRORS{"UNKNOWN"};
}
print FILE "$update_time:$in_bits:$out_bits";
close(FILE);

if ($flg_created == 0){
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
	my $diff = time() - $last_check_time;
	if ($diff == 0){$diff = 1;}
    my $pct_in_traffic = $in_traffic = abs($total / $diff);
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
    my $diff =  time() - $last_check_time;
    if ($diff == 0){$diff = 1;}
    my $pct_out_traffic = $out_traffic = abs($total / $diff);
} else {
    $out_traffic = 0;
}

if ( $speed_card != 0 ) {
    $in_usage = sprintf("%.1f",($in_traffic*100) / $speed_card);
    $out_usage = sprintf("%.1f",($out_traffic*100) / $speed_card);
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

if(($in_usage > $warning) or ($out_usage > $warning)){
	$status = "WARNING";
}

if (($in_usage > $critical) or ($out_usage > $critical)){
	$status = "CRITICAL";
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
    print "   -V (--version)    Plugin version\n";
    print "   -h (--help)       usage help\n";
}

sub print_help () {
    print "######################################################\n";
    print "#      Copyright (c) 2004-2007 Oreon-project         #\n";
	print "#      Bugs to http://www.oreon-project.org/         #\n";
	print "######################################################\n";
    print_usage();
    print "\n";
}
