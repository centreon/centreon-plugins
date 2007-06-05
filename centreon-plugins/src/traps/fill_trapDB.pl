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

#########################################
## TEST IF OID ALREADY EXISTS IN DATABASE
#

sub existsInDB($$) {
    my ($dbh, $oid,$manuf) = @_;
    my $sth = $dbh->prepare("SELECT traps_id from traps where traps_oid='$oid'");
    $sth->execute();
    if (defined($sth->fetchrow_array)) {
		$sth->finish();
		return 1;
    }
    $sth->finish();
    return 0;
}

#####################################
## RETURN ENUM FROM STRING FOR STATUS
#

sub getStatus($$) {
    my ($val, $type) = @_;
    if ($val =~ /[I|i][N|n][F|f][O|o][R|r][M|m][A|a][T|t][I|i][O|o][N|n][A|a][L|l]|[N|n][O|o][R|r][M|m][A|a][L|l]/) {
		return 0;
    } elsif ($val =~ /^[W|w][A|a][R|r][N|n][I|i][N|n][G|g]|[M|m][I|i][N|n][O|o][R|r]$/) {
		return 1;
    } elsif ($val =~ /^[C|c][R|r][I|i][T|t][I|i][C|c][A|a][L|l]|[M|m][A|a][J|j][O|o][R|r]$/) {
		return 2;
    }
    return 3;
}

################
## MAIN FUNCTION
#
sub main($$) {
    my $manuf = $_[1];
    my @db = set_db();
    my $dbh = DBI->connect($db[0], $db[1], $db[2]) or die "DB connexion error\n";
    if (!open(FILE, $_[0])) {
		print "Cannot open configuration file : $_[0]\n";
		exit;
    }
    my $last_oid = "";
    while (<FILE>) {	
		if ($_ =~ /^EVENT\ ([a-zA-Z0-9]+)\ ([0-9\.]+)\ (\"[A-Za-z\ ]+\")\ ([a-zA-Z]+)/) {
		    my ($name,$oid,$type,$val) = ($1,$2,$3,$4);
		    if (existsInDB($dbh, $oid)) {
				print "Trap oid : $name => $oid already exists in database\n";
				$last_oid = $oid;
		    } else {
				$val = getStatus($val,$type);
				my $sth = $dbh->prepare("INSERT INTO `traps` (traps_name, traps_oid, traps_status, manufacturer_id) values ('$name', '$oid', '$val', '$manuf')");
				$sth->execute();
				$sth->finish();
				$last_oid = $oid;
		    }
		} elsif ($_ =~/^FORMAT\ (.*)/ && $last_oid ne "") {
		    my $query = "UPDATE `traps` set traps_args='$1' where traps_oid='$last_oid'";
		    my $sth = $dbh->prepare($query);
		    $sth->execute();
		    $sth->finish();
		} elsif ($_ =~ /^SDESC(.*)/ && $last_oid ne "") {	    
		    my $temp_val = $1;
		    my $desc = "";
		    if (! ($temp_val =~ /\s+/)){
				$temp_val =~ s/\"/\\\"/g;
				$temp_val =~ s/\'/\\\'/g;
				$desc .= $temp_val;
		    }
		    my $found = 0;
		    while (!$found) {
				my $line = <FILE>;
				if ($line =~ /^EDESC/) {
				    $found = 1;
				} else {
					$line =~ s/\"/\\\"/g;
					$line =~ s/\'/\\\'/g;
				 	$desc .= $line;
				}
		    }
		    if ($desc ne "") {
				my $sth = $dbh->prepare("UPDATE `traps` set traps_comments='$desc' where traps_oid='$last_oid'");
				$sth->execute();
				$sth->finish();
		    }
		}
    }
    $dbh->disconnect();
}

	Getopt::Long::Configure('bundling');
	my ($opt_f, $opt_m);
	GetOptions("f|file=s" => \$opt_f, "m|man=s"  => \$opt_m);

if (!$opt_f || !$opt_m) {
    print "fill_trapDB.pl : Usage : ./fill_trapDB.pl -f configuration_file -m manufacturer_id\n";
    exit;
}

main($opt_f,$opt_m);

exit();
