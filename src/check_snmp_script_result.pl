#! /usr/bin/perl 

#
# $Id$
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
require "/usr/lib/nagios/plugins/Centreon/SNMP/Utils.pm";
my %ERRORS = ('OK' => 0, 'WARNING' => 1, 'CRITICAL' => 2, 'UNKNOWN' => 3);

use vars qw($PROGNAME);
use Getopt::Long;
use vars qw($opt_V $opt_h $opt_n $opt_w $opt_c $opt_s);

# Plugin var init

$PROGNAME = $0;
sub print_help ();
sub print_usage ();
Getopt::Long::Configure('bundling');

my %OPTION = (
    "host" => undef,
    "snmp-community" => "public", "snmp-version" => 1, "snmp-port" => 161, 
    "snmp-auth-key" => undef, "snmp-auth-user" => undef, "snmp-auth-password" => undef, "snmp-auth-protocol" => "MD5",
    "snmp-priv-key" => undef, "snmp-priv-password" => undef, "snmp-priv-protocol" => "DES",
    "maxrepetitions" => undef,
    "64-bits" => undef,
);

GetOptions
    (
     "H|hostname|host=s"         => \$OPTION{'host'},
    "C|community=s"             => \$OPTION{'snmp-community'},
    "v|snmp|snmp-version=s"     => \$OPTION{'snmp-version'},
    "P|snmpport|snmp-port=i"    => \$OPTION{'snmp-port'},
    "u|username=s"              => \$OPTION{'snmp-auth-user'},
    "p|authpassword|password=s" => \$OPTION{'snmp-auth-password'},
    "k|authkey=s"               => \$OPTION{'snmp-auth-key'},
    "authprotocol=s"            => \$OPTION{'snmp-auth-protocol'},
    "privpassword=s"            => \$OPTION{'snmp-priv-password'},
    "privkey=s"                 => \$OPTION{'snmp-priv-key'},
    "privprotocol=s"            => \$OPTION{'snmp-priv-protocol'},
    "maxrepetitions=s"          => \$OPTION{'maxrepetitions'},
    "64-bits"                   => \$OPTION{'64-bits'},
    "h"   => \$opt_h, "help"         => \$opt_h,
    "V"   => \$opt_V, "version"      => \$opt_V,
    "s"   => \$opt_s, "show"         => \$opt_s,
    "n=s"   => \$opt_n, "name=s"         => \$opt_n,
    "w=s" => \$opt_w, "warning=s"    => \$opt_w,
    "c=s" => \$opt_c, "critical=s"   => \$opt_c);


if ($opt_V) {
    print_revision($PROGNAME,'$Revision: 1.2 $');
    exit $ERRORS{'OK'};
}

if ($opt_h) {
    print_help();
    exit $ERRORS{'OK'};
}

my ($session_params) = Centreon::SNMP::Utils::check_snmp_options($ERRORS{'UNKNOWN'}, \%OPTION);

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
my $session = Centreon::SNMP::Utils::connection($ERRORS{'UNKNOWN'}, $session_params);

my $scriptname = "";

# getting partition using its name instead of its oid index

if ($opt_n) {
    my $result = Centreon::SNMP::Utils::get_snmp_table($OID_ExecDescr, $session, $ERRORS{'UNKNOWN'}, \%OPTION);
    foreach my $key ( oid_lex_sort(keys %$result)) {
        if ($result->{$key} =~ m/$opt_n/) {
            my @oid_list = split (/\./,$key);
            $scriptname = pop (@oid_list) ;
        }
    }
}

my $result = Centreon::SNMP::Utils::get_snmp_leef([$OID_ExecDescr.".".$scriptname, $OID_ExecOutput.".".$scriptname], $session, $ERRORS{'UNKNOWN'});

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
    print "   -H (--hostname)   Hostname to query (required)\n";
    print "   -C (--community)  SNMP read community (defaults to public)\n";
    print "                     used with SNMP v1 and v2c\n";
    print "   -v (--snmp-version)  1 for SNMP v1 (default)\n";
    print "                        2 for SNMP v2c\n";
    print "                        3 for SNMP v3\n";
    print "   -P (--snmp-port)  SNMP port (default: 161)\n";
    print "   -k (--key)        snmp V3 key\n";
    print "   -u (--username)   snmp V3 username \n";
    print "   -p (--password)   snmp V3 password\n";
    print "   --authprotocol    protocol MD5/SHA1  (v3)\n";
    print "   --privprotocol    encryption system (DES/AES)(v3) \n";
    print "   --privpassword    passphrase (v3) \n";
    print "   --64-bits         Use 64 bits OID\n";
    print "   --maxrepetitions  To use when you have the error: 'Message size exceeded buffer maxMsgSize'\n";
    print "                     Work only with SNMP v2c and v3 (Example: --maxrepetitions=1)\n";
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
    print "#  Copyright (c) 2004-2013 centreon      #\n";
    print "#  Bugs to http://forge.centreon.com/    #\n";
    print "##########################################\n";
    print_usage();
    print "\n";
}
