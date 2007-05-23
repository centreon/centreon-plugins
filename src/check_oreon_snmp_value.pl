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
use Net::SNMP qw(:snmp);
use FindBin;
use lib "$FindBin::Bin";
use lib "/srv/nagios/libexec";
use utils qw($TIMEOUT %ERRORS &print_revision &support);

use vars qw($PROGNAME);
use Getopt::Long;
use vars qw($opt_h $opt_V $opt_H $opt_C $opt_v $opt_o $opt_c $opt_w $opt_t $opt_p $opt_k $opt_u);

$PROGNAME = $0;
sub print_help ();
sub print_usage ();

Getopt::Long::Configure('bundling');
GetOptions
    ("h"   => \$opt_h, "help"         => \$opt_h,
     "u=s" => \$opt_u, "username=s"   => \$opt_u,
     "p=s" => \$opt_p, "password=s"   => \$opt_p,
     "k=s" => \$opt_k, "key=s"        => \$opt_k,
     "V"   => \$opt_V, "version"      => \$opt_V,
     "v=s" => \$opt_v, "snmp=s"       => \$opt_v,
     "C=s" => \$opt_C, "community=s"  => \$opt_C,
     "o=s" => \$opt_o, "oid=s"        => \$opt_o,
     "t=s" => \$opt_t, "type=s"       => \$opt_t,
     "w=s" => \$opt_w, "warning=s"    => \$opt_w,
     "c=s" => \$opt_c, "critical=s"   => \$opt_c,
     "H=s" => \$opt_H, "hostname=s"   => \$opt_H);

if ($opt_V) {
    print_revision($PROGNAME,'$Revision: 1.0');
    exit $ERRORS{'OK'};
}

if ($opt_h) {
    print_help();
    exit $ERRORS{'OK'};
}

$opt_H = shift unless ($opt_H);
(print_usage() && exit $ERRORS{'OK'}) unless ($opt_H);

my $snmp = "1";
if ($opt_v && $opt_v =~ /^[0-9]$/) {
$snmp = $opt_v;
}

if ($snmp eq "3") {
if (!$opt_u) {
print "Option -u (--username) is required for snmpV3\n";
exit $ERRORS{'OK'};
}
if (!$opt_p && !$opt_k) {
print "Option -k (--key) or -p (--password) is required for snmpV3\n";
exit $ERRORS{'OK'};
}elsif ($opt_p && $opt_k) {
print "Only option -k (--key) or -p (--password) is needed for snmpV3\n";
exit $ERRORS{'OK'};
}
}

($opt_C) || ($opt_C = shift) || ($opt_C = "public");

my $DS_type = "GAUGE";
($opt_t) || ($opt_t = shift) || ($opt_t = "GAUGE");
$DS_type = $1 if ($opt_t =~ /(GAUGE)/ || $opt_t =~ /(COUNTER)/);

if (!$opt_c || !$opt_w) {
    print "You must specify -c and -w options\n";
    exit $ERRORS{'OK'};
}

($opt_c) || ($opt_c = shift);
my $critical = $1 if ($opt_c =~ /([0-9]+)/);

($opt_w) || ($opt_w = shift);
my $warning = $1 if ($opt_w =~ /([0-9]+)/);
if ($critical <= $warning){
    print "(--critical) must be superior to (--warning)";
    print_usage();
    exit $ERRORS{'OK'};
}

if (!$opt_o) {
    print "Option -o needed.\n";
    exit $ERRORS{'OK'};
}elsif (!($opt_o =~ /^[0-9\.]+$/)) {
    print "Wrong OID format\n";
    exit $ERRORS{'OK'};
}

my $name = $0;
$name =~ s/\.pl.*//g;
my $day = 0;

#===  create a SNMP session ====

my ($session, $error);
if ($snmp eq "1" || $snmp eq "2") {
($session, $error) = Net::SNMP->session(-hostname => $opt_H, -community => $opt_C, -version => $snmp);
if (!defined($session)) {
    print("UNKNOWN: SNMP Session : $error\n");
    exit $ERRORS{'UNKNOWN'};
}
}elsif ($opt_k) {
    ($session, $error) = Net::SNMP->session(-hostname => $opt_H, -version => $snmp, -username => $opt_u, -authkey => $opt_k);
if (!defined($session)) {
    print("UNKNOWN: SNMP Session : $error\n");
    exit $ERRORS{'UNKNOWN'};
}
}elsif ($opt_p) {
    ($session, $error) = Net::SNMP->session(-hostname => $opt_H, -version => $snmp,  -username => $opt_u, -authpassword => $opt_p);
if (!defined($session)) {
    print("UNKNOWN: SNMP Session : $error\n");
    exit $ERRORS{'UNKNOWN'};
}
}

my $result = $session->get_request(-varbindlist => [$opt_o]);
if (!defined($result)) {
    printf("UNKNOWN: %s.\n", $session->error);
    $session->close;
    exit $ERRORS{'UNKNOWN'};
}

my $return_result =  $result->{$opt_o};

#===  Plugin return code  ====

if (defined($return_result)){
    if ($return_result !~ /^[0-9]$/) {
	print "Snmp return value isn't numeric.\n";
	exit $ERRORS{'OK'};
    }
    if ($opt_w && $opt_c && $return_result < $opt_w){
    	print "Ok value : " . $return_result . "|value=".$return_result.";".$opt_w.";".$opt_c.";;\n";
	exit $ERRORS{'OK'};
    } elsif ($opt_w && $opt_c && $return_result >= $opt_w && $return_result < $opt_c){
	print "Warning value : " . $return_result . "|value=$return_result;".$opt_w.";".$opt_c.";;\n";
	exit $ERRORS{'WARNING'};
    } elsif ($opt_w && $opt_c && $return_result >= $opt_c){
    	print "Critical value : " . $return_result."|value=".$return_result.";".$opt_w.";".$opt_c.";;\n";
	exit $ERRORS{'CRITICAL'};
    }
} else {
    print "CRITICAL Host unavailable\n";
    exit $ERRORS{'CRITICAL'};
}


sub print_usage () {
    print "\nUsage:\n";
    print "$PROGNAME\n";
    print "   -H (--hostname)   Hostname to query - (required)\n";
    print "   -C (--community)  SNMP read community (defaults to public,\n";
    print "                     used with SNMP v1 and v2c\n";
    print "   -v (--snmp_version)  1 for SNMP v1 (default)\n";
    print "                        2 for SNMP v2c\n";
    print "   -t (--type)       Data Source Type (GAUGE or COUNTER) (GAUGE by default)\n";
    print "   -o (--oid)        OID to check\n";
    print "   -w (--warning)    Warning level\n";
    print "   -c (--critical)   Critical level\n";
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
