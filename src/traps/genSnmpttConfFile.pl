#! /usr/bin/perl -w
###################################################################
# Oreon is developped with GPL Licence 2.0 
#
# GPL License: http://www.gnu.org/licenses/gpl.txt
#
# Developped by : Mathavarajan Sugumaran - msugumaran@merethis.com
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
use Getopt::Long;
use DBI;

#############################
## SET DATABASE CONFIGURATION
#

sub set_db	{
	require "@OREON_PATH@/ODS/etc/conf.pm"
    my $dsn   = "dbi:mysql:$mysql_database_oreon";
    return $dsn, $mysql_user, $mysql_passwd;
}

######################################
## Get snmptt configuration files path
#

sub getPath($) {
    my $dbh = shift;
    my $sth = $dbh->prepare("Select snmp_trapd_path_conf from general_opt");
    $sth->execute();
    my $path = $sth->fetchrow_array();
    $path .= "/" if (!($path =~ /\/$/));
    $path = "/etc/snmp/" if (!$path);
    return $path;
}

sub main() {
    print "Generating SNMPTT configuration files...\n";
    my ($nbMan, $nbTraps) = (0,0);
    my @db = set_db();
    my $dbh = DBI->connect($db[0], $db[1], $db[2]) or die "Echec de la connexion mysql\n";
    my $confFiles_path = getPath($dbh);
    
	my $sth = $_[0]->prepare("SELECT nagios_path_plugins FROM general_opt LIMIT 1");
	$sth->execute();
	my $conf = $sth->fetchrow_array();
	$sth->finish();
	my $NAGIOS_TRAPS = $conf->{'nagios_path_plugins'}."traps/";
    
    my $sth = $dbh->prepare("SELECT id, name from inventory_manufacturer");
    $sth->execute();
    my $snmpttIni = "";
    while (my ($man_id, $man_name) = $sth->fetchrow_array()) {
		my $sth2 = $dbh->prepare("SELECT traps_name, traps_oid, traps_status, traps_args, traps_comments FROM traps WHERE manufacturer_id = '$man_id'");
		$sth2->execute();
		if (!open(FILE, "> ".$confFiles_path."snmptt-".$man_name.".conf")) {
		    print "Cannot open ".$confFiles_path."snmptt-".$man_name.".conf in write mode - Export aborded\n";
		    exit;
		}
		$nbMan++ if ($sth2->rows);
		while (my @values = $sth2->fetchrow_array()) {
		    $nbTraps++;
		    print FILE "EVENT ".$values[0]." ".$values[1]." \"Status Event\" ".$values[2]."\n";
		    print FILE "FORMAT ".$values[3]."\n" if (defined($values[3]));
		    print FILE "EXEC ".$NAGIOS_TRAPS."/trapHandler.pl \$aA \$o \"\$*\"\n";
		    if (defined($values[4])) {
				print FILE "SDESC\n".$values[4];
				if ($values[4] =~ /\n$/) {
				    print FILE "EDESC\n\n";
				} else {
				    print FILE "\nEDESC\n\n";
				}
		    } else {
				print FILE "\n";
		    }
		}
		close FILE;
		$snmpttIni .= $confFiles_path."snmptt-".$man_name.".conf\n";
		$sth2->finish();
    }
    print "$nbTraps traps for $nbMan manufacturers are defined.\n";
    $sth->finish();
    $dbh->disconnect();
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
	    	} else {
				$continue = 0;
	    	}
		} else {
	    	$continue = -1;
		}
    }
    if (!$continue) {
		print TEMP "snmptt_conf_files = <<END\n";
		print TEMP $snmpttIni."END\n";
		my $command = "mv /tmp/snmptt.ini.tmp ".$confFiles_path."snmptt.ini";
		my $mv = `$command`;
		print "SNMPTT configuration files generated.\n";
    } else {
		print "Couldn't export ".$confFiles_path."snmptt.ini, please put these lines at the end of file snmptt.ini :\n";
		print "snmptt_conf_files = <<END\n".$snmpttIni."END\n";
    }
}

main();
