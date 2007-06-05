#! /usr/bin/perl -w
#
# $Id: genSnmpttConfFile.pl,v 1.0 2007/05/15 17:21:49 Sugumaran Mat $
#
# Oreon's plugins are developped with GPL Licence :
# http://www.fsf.org/licenses/gpl.txt
# Developped by : Sugumaran Mathavarajan
#
# The Software is provided to you AS IS and WITH ALL FAULTS.
# OREON makes no representation and gives no warranty whatsoever,
# whether express or implied, and without limitation, with regard to the quality,
# safety, contents, performance, merchantability, non-infringement or suitability for
# any particular or intended purpose of the Software found on the OREON web site.
# In no event will OREON be liable for any direct, indirect, punitive, special,
# incidental or consequential damages however they may arise and even if OREON has
# been previously advised of the possibility of such damages.

use strict;
use Getopt::Long;
use DBI;
my $NAGIOS_TRAPS = "/srv/nagios/libexec/traps";

#############################
## SET DATABASE CONFIGURATION
#
sub set_db
{
    my $db_name = "oreon";	## name of your database for oreon
    my $login = "root";		## user of your database
    my $mdp   = "mysql-password";	## password for this user
    my $dsn   = "dbi:mysql:$db_name";
    return $dsn, $login, $mdp;
}

######################################
## Get snmptt configuration files path
#
sub getPath($) {
    my $dbh = shift;
    my $query = "Select snmp_trapd_path_conf from general_opt";
    my $sth = $dbh->prepare($query);
    $sth->execute;
    my $path = $sth->fetchrow_array;
    if (!($path =~ /\/$/)) {
	$path .= "/";
    }
    if (!$path) {
	$path = "/etc/snmp/";
    }
    return $path;
}


sub main() {
    print "Generating SNMPTT configuration files...\n";
    my ($nbMan, $nbTraps) = (0,0);
    my @db = set_db();
    my $dbh = DBI->connect($db[0], $db[1], $db[2]) or die "Echec de la connexion mysql\n";
    my $confFiles_path = getPath($dbh);
    my $query = "SELECT id, name from inventory_manufacturer";
    my $sth = $dbh->prepare($query);
    $sth->execute;
    my $snmpttIni = "";
    while (my ($man_id, $man_name) = $sth->fetchrow_array) {
	my $query2 = "SELECT traps_name, traps_oid, traps_status, traps_args, traps_comments";
	$query2 .= " from traps where manufacturer_id='$man_id'";
	my $sth2 = $dbh->prepare($query2);
	$sth2->execute;
	if (!open(FILE, "> ".$confFiles_path."snmptt-".$man_name.".conf")) {
	    print "Cannot open ".$confFiles_path."snmptt-".$man_name.".conf in write mode - Export aborded\n";
	    exit;
	}
	if ($sth2->rows) {
	    $nbMan++;
	}
	while (my @values = $sth2->fetchrow_array) {
	    $nbTraps++;
	    print FILE "EVENT ".$values[0]." ".$values[1]." \"Status Event\" ".$values[2]."\n";
	    if (defined($values[3])) {
		print FILE "FORMAT ".$values[3]."\n";
	    }
	    print FILE "EXEC ".$NAGIOS_TRAPS."/trapHandler.pl \$aA \$o \"\$*\"\n";
	    if (defined($values[4])) {
		print FILE "SDESC\n";
		print FILE $values[4];
		if ($values[4] =~ /\n$/) {
		    print FILE "EDESC\n\n";
		}else {
		    print FILE "\nEDESC\n\n";
		}
	    }else {
		print FILE "\n";
	    }
	}
	close FILE;
	$snmpttIni .= $confFiles_path."snmptt-".$man_name.".conf\n";
	$sth2->finish;
    }
    print "$nbTraps traps for $nbMan manufacturers are defined.\n";
    $sth->finish;
    $dbh->disconnect;
    if (!open(FILE, $confFiles_path."snmptt.ini")) {
	print "Cannot open ".$confFiles_path."snmptt.ini - Export Aborded\n";
	exit;
    }
    if (!open(TEMP, "> /tmp/snmptt.ini.tmp")) {
	print "Cannot open /tmp/snmptt.ini.tmp in write mode - Export Aborded\n";
	exit;
    }
    my $continue = 1;
    while ($continue == 1) {
	my $line = <FILE>;
	if ($line) {
	    if (!($line =~ /^snmptt\_conf\_files/)) {
		print TEMP $line;
	    }else {
		$continue = 0;
	    }
	}else {
	    $continue = -1;
	}
    }
    if (!$continue) {
	print TEMP "snmptt_conf_files = <<END\n";
	print TEMP $snmpttIni."END\n";
	my $command = "mv /tmp/snmptt.ini.tmp ".$confFiles_path."snmptt.ini";
	my $mv = `$command`;
	print "SNMPTT configuration files generated.\n";
    }else {
	print "Couldn't export ".$confFiles_path."snmptt.ini, please put these lines at the end of file snmptt.ini :\n";
	print "snmptt_conf_files = <<END\n".$snmpttIni."END\n";
    }
}
main;
