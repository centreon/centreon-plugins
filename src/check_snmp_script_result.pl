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
require "@NAGIOS_PLUGINS@/Centreon/SNMP/Utils.pm";
my %ERRORS = ('OK' => 0, 'WARNING' => 1, 'CRITICAL' => 2, 'UNKNOWN' => 3);

use vars qw($PROGNAME);
use Getopt::Long;
use vars qw($opt_V $opt_h $opt_n);

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
    "command-exit" => undef,
    "no-regexp" => undef,
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
    "command-exit"              => \$OPTION{'command-exit'},
    "no-regexp"                 => \$OPTION{'no-regexp'},
    "h"     => \$opt_h, "help"      => \$opt_h,
    "V"     => \$opt_V, "version"   => \$opt_V,
    "n=s"   => \$opt_n, "name=s"    => \$opt_n);


if ($opt_V) {
    print_revision($PROGNAME,'$Revision: 1.2 $');
    exit $ERRORS{'OK'};
}

if ($opt_h) {
    print_help();
    exit $ERRORS{'OK'};
}

if (!defined($opt_n) || $opt_n eq '') {
    print "Option -n (--name) needed\n";
    exit $ERRORS{'UNKNOWN'};
}

my ($session_params) = Centreon::SNMP::Utils::check_snmp_options($ERRORS{'UNKNOWN'}, \%OPTION);

# Plugin snmp requests   
my $OID_ExecResult = ".1.3.6.1.4.1.2021.8.1.100";
my $OID_ExecDescr = ".1.3.6.1.4.1.2021.8.1.2";
my $OID_ExecOutput = ".1.3.6.1.4.1.2021.8.1.101";

# create a SNMP session
my $session = Centreon::SNMP::Utils::connection($ERRORS{'UNKNOWN'}, $session_params);

my $scriptname;

my $result = Centreon::SNMP::Utils::get_snmp_table($OID_ExecDescr, $session, $ERRORS{'UNKNOWN'}, \%OPTION);
foreach my $key ( oid_lex_sort(keys %$result)) {
    if (defined($OPTION{'no-regexp'})) {
        if ($result->{$key} eq $opt_n) {
            my @oid_list = split(/\./, $key);
            $scriptname = pop(@oid_list);
        }
    } elsif ($result->{$key} =~ /$opt_n/) {
        my @oid_list = split(/\./, $key);
        $scriptname = pop(@oid_list);
    }
}

if (!defined($scriptname)) {
    print "Can't find a command name '$opt_n'\n";
    exit $ERRORS{'UNKNOWN'};
}

my $result = Centreon::SNMP::Utils::get_snmp_leef([$OID_ExecOutput.".".$scriptname, $OID_ExecResult.".".$scriptname], $session, $ERRORS{'UNKNOWN'});
my $ExecOutput  =  $result->{$OID_ExecOutput.".".$scriptname };

print $ExecOutput . "\n";

if (defined($OPTION{'command-exit'})) {
    exit($result->{$OID_ExecResult . "." . $scriptname});
}
exit($ERRORS{'OK'});

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
    print "   -n (--name)       SNMP Command name to call\n";
    print "                     Example in snmpd.conf: exec echotest /bin/echo hello world\n";
    print "                     So we specify: -n 'echotest'\n";
    print "   --command-exit    Use command exit code\n";
    print "   --no-regexp       Don't use regexp to check command name\n";
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
