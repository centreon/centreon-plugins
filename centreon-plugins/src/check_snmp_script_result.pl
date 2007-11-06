#! /usr/bin/perl 

#
# $Id: check_graph_remote_storage.pl,v 1.2 2005/07/27 22:21:49 wistof Exp $
#
# centreon's plugins are developped with GPL Licence :
# http://www.fsf.org/licenses/gpl.txt
# Developped by : Julien Mathis - Mathieu Mettre - Romain Le Merlus - Yohann Lecarpentier
#
# Modified for centreon Project by : Mathieu Chateau - Christophe Coraboeuf
#
# The Software is provided to you AS IS and WITH ALL FAULTS.
# centreon makes no representation and gives no warranty whatsoever,
# whether express or implied, and without limitation, with regard to the quality,
# safety, contents, performance, merchantability, non-infringement or suitability for
# any particular or intended purpose of the Software found on the centreon web site.
# In no event will centreon be liable for any direct, indirect, punitive, special,
# incidental or consequential damages however they may arise and even if centreon has
# been previously advised of the possibility of such damages.

# Plugin init

use strict;
use Net::SNMP qw(:snmp);
use FindBin;
use lib "$FindBin::Bin";
use lib "/usr/local/nagios/libexec";
use utils qw($TIMEOUT %ERRORS &print_revision &support);

if (eval "require centreon" ) {
	use centreon qw(get_parameters create_rrd update_rrd &is_valid_serviceid);
	use vars qw($VERSION %centreon);
	%centreon=get_parameters();
} else {
	print "Unable to load centreon perl module\n";
    exit $ERRORS{'UNKNOWN'};
}

use vars qw($PROGNAME);
use Getopt::Long;
use vars qw($opt_V $opt_h $opt_g $opt_v $opt_C $opt_d $opt_n $opt_w $opt_c $opt_H $opt_S $opt_D $opt_s $opt_step $step @test $opt_f);

# Plugin var init

my ($hrStorageDescr, $hrStorageAllocationUnits, $hrStorageSize, $hrStorageUsed);
my ($AllocationUnits, $Size, $Used);
my ($tot, $used, $pourcent, $return_code);

$PROGNAME = "check_snmp_remote_storage";
sub print_help ();
sub print_usage ();
Getopt::Long::Configure('bundling');
GetOptions
    ("h"   => \$opt_h, "help"         => \$opt_h,
     "V"   => \$opt_V, "version"      => \$opt_V,
     "v=s" => \$opt_v,
     "s"   => \$opt_s, "show"         => \$opt_s,
     "C=s" => \$opt_C, "community=s"  => \$opt_C,
     "n=s"   => \$opt_n, "name=s"         => \$opt_n,
     "w=s" => \$opt_w, "warning=s"    => \$opt_w,
     "c=s" => \$opt_c, "critical=s"   => \$opt_c,
     "H=s" => \$opt_H, "hostname=s"   => \$opt_H);


if ($opt_V) {
    print_revision($PROGNAME,'$Revision: 1.2 $');
    exit $ERRORS{'OK'};
}

if ($opt_h) {
	print_help();
	exit $ERRORS{'OK'};
}

$opt_H = shift unless ($opt_H);
(print_usage() && exit $ERRORS{'OK'}) unless ($opt_H);

($opt_v) || ($opt_v = shift) || ($opt_v = "2");
my $snmp = $1 if ($opt_v =~ /(\d)/);

($opt_C) || ($opt_C = shift) || ($opt_C = "public");

($opt_c) || ($opt_c = shift) || ($opt_c = 95);
my $critical = $1 if ($opt_c =~ /([0-9]+)/);

($opt_w) || ($opt_w = shift) || ($opt_w = 80);
my $warning = $1 if ($opt_w =~ /([0-9]+)/);
if ($critical <= $warning){
    print "(--crit) must be superior to (--warn)";
    print_usage();
    exit $ERRORS{'OK'};
}

# Plugin snmp requests   

my $OID_ExecDescr = ".1.3.6.1.4.1.2021.8.1.2";
my $OID_ExecOutput = ".1.3.6.1.4.1.2021.8.1.101";

# create a SNMP session

my ( $session, $error ) = Net::SNMP->session(-hostname  => $opt_H,-community => $opt_C, -version  => $snmp);
if ( !defined($session) ) {
    print("CRITICAL: SNMP Session : $error");
    exit $ERRORS{'CRITICAL'};
}

my $scriptname = "";

# getting partition using its name instead of its oid index

if ($opt_n) {
    my $result = $session->get_table(Baseoid => $OID_ExecDescr);
    if (!defined($result)) {
        printf("ERROR: hr Exec Descr Table : %s.\n", $session->error);
        $session->close;
        exit $ERRORS{'UNKNOWN'};
    }
    foreach my $key ( oid_lex_sort(keys %$result)) {
        if ($result->{$key} =~ m/$opt_n/) {
	    my @oid_list = split (/\./,$key);
	    $scriptname = pop (@oid_list) ;
	}
    }
}


my $result = $session->get_request(-varbindlist => [$OID_ExecDescr.".".$scriptname, $OID_ExecOutput.".".$scriptname]);

if (!defined($result)) {
    printf("ERROR:  %s", $session->error);
    if ($opt_n) { print(" - You must specify the disk name when option -n is used");}
    print ".\n";
    $session->close;
    exit $ERRORS{'UNKNOWN'};
}

my $ExecDescr  =  $result->{$OID_ExecDescr.".".$scriptname };
my $ExecOutput  =  $result->{$OID_ExecOutput.".".$scriptname };

print "|" . $ExecOutput . "\n";

my $return = 5;

if (!defined($opt_w) && !defined($opt_c)){
	$ExecOutput =~ /([0-9]*)/;
	if ($1 eq 1){
		print "OK : Process runnable \n";
		$return = 0; 
	} else {
		print "CRITICAL : Process runnable \n";
		$return = 2;
	}
} else {
	if ($ExecOutput =~ /([0-9]*)/){
		if ($1 >= $opt_w && $1 < $opt_c){
			print "OK : $1 Process runnable \n";
			$return = 1;	
		} elsif ($1 > $opt_c) {
			print "WARNING : $1 Process runnable \n";
			$return = 2;
		} elsif ($1 < $opt_w) {
			print "CRITICAL : Process runnable \n";	
			$return = 0;
	 	}
	}
}	
exit($return);

sub print_usage () {
    print "\nUsage:\n";
    print "$PROGNAME\n";
    print "   -H (--hostname)   Hostname to query - (required)\n";
    print "   -C (--community)  SNMP read community (defaults to public,\n";
    print "                     used with SNMP v1 and v2c\n";
    print "   -v (--snmp_version)  1 for SNMP v1 (default)\n";
    print "                        2 for SNMP v2c\n";
    print "   -n (--name)       Allows to use disk name with option -d instead of disk oid index\n";
    print "                     (ex: -d \"C:\" -n, -d \"E:\" -n, -d \"Swap Memory\" -n, -d \"Real Memory\" -n\n";
    print "                     (choose an unique expression for each disk)\n";
    print "   -w (--warn)       Signal strength at which a warning message will be generated\n";
    print "                     (default 80)\n";
    print "   -c (--crit)       Signal strength at which a critical message will be generated\n";
    print "                     (default 95)\n";
    print "   -V (--version)    Plugin version\n";
    print "   -h (--help)       usage help\n";

}

sub print_help () {
    print "##########################################\n";
    print "#  Copyright (c) 2004-2006 centreon      #\n";
    print "#  Bugs to http://www.oreon-project.org/ #\n";
    print "##########################################\n";
    print_usage();
    print "\n";
}
