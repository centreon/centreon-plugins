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
use lib "@NAGIOS_PLUGINS@";
use utils qw($TIMEOUT %ERRORS &print_revision &support);

use vars qw($PROGNAME);
use Getopt::Long;
use vars qw($opt_h $opt_V $opt_D $opt_H $opt_C $opt_v $opt_o $opt_c $opt_w $opt_t);

$PROGNAME = $0;
sub print_help ();
sub print_usage ();

Getopt::Long::Configure('bundling');
GetOptions
    ("h"   => \$opt_h, "help"         => \$opt_h,
     "V"   => \$opt_V, "version"      => \$opt_V,
     "v=s" => \$opt_v, "snmp=s"       => \$opt_v,
     "C=s" => \$opt_C, "community=s"  => \$opt_C,
     "o=s"   => \$opt_o, "oid=s"          => \$opt_o,
     "t=s"   => \$opt_t, "type=s"          => \$opt_t,
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

($opt_v) || ($opt_v = shift) || ($opt_v = "1");
my $snmp = $1 if ($opt_v =~ /(\d)/);

($opt_C) || ($opt_C = shift) || ($opt_C = "public");
my $rrd = $pathtorrdbase.$ServiceId.".rrd";

($opt_t) || ($opt_t = shift) || ($opt_t = "GAUGE");
my $DS_type = $1 if ($opt_t =~ /(GAUGE)/ || $opt_t =~ /(COUNTER)/);

($opt_c) || ($opt_c = shift);
my $critical = $1 if ($opt_c =~ /([0-9]+)/);

($opt_w) || ($opt_w = shift);
my $warning = $1 if ($opt_w =~ /([0-9]+)/);
if ($critical <= $warning){
    print "(--critical) must be superior to (--warning)";
    print_usage();
    exit $ERRORS{'OK'};
}

my $name = $0;
$name =~ s/\.pl.*//g;
my $day = 0;

#===  create a SNMP session ====

my ($session, $error) = Net::SNMP->session(-hostname  => $opt_H,-community => $opt_C, -version  => $snmp);
if (!defined($session)) {
    print("CRITICAL: $error");
    exit $ERRORS{'CRITICAL'};
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
    if ($opt_w && $opt_c && $return_result < $opt_w){
    	print "Ok value : " . $return_result . "|value=".$return_result.";".$opt_w.";".$opt_c.";;\n";
		exit $ERRORS{'OK'};
    } elsif ($opt_w && $opt_c && $return_result >= $opt_w && $return_result < $opt_c){
		print "Warning value : " . $return_result . "|value=$return_result;".$opt_w.";".$opt_c.";;\n";}
		exit $ERRORS{'WARNING'};
    } elsif ($opt_w && $opt_c && $return_result >= $opt_c){
    	print "Critical value : " . $return_result."|value=".$return_result.";".$opt_w.";".$opt_c.";;\n";}
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
