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

#########################################
## TEST IF OID ALREADY EXISTS IN DATABASE
#
sub existsInDB($$) {
    my ($dbh, $oid,$manuf) = @_;
    my $query = "SELECT traps_id from traps where traps_oid='$oid'";
    my $sth = $dbh->prepare($query);
    $sth->execute;
    if (defined($sth->fetchrow_array)) {
	$sth->finish;
	return 1;
    }
    $sth->finish;
    return 0;
}

#####################################
## RETURN ENUM FROM STRING FOR STATUS
#
sub getStatus($$) {
    my ($val, $type) = @_;
    if ($val =~ /[I|i][N|n][F|f][O|o][R|r][M|m][A|a][T|t][I|i][O|o][N|n][A|a][L|l]|[N|n][O|o][R|r][M|m][A|a][L|l]/) {
	return 0;
    }elsif ($val =~ /^[W|w][A|a][R|r][N|n][I|i][N|n][G|g]|[M|m][I|i][N|n][O|o][R|r]$/) {
	return 1;
    }elsif ($val =~ /^[C|c][R|r][I|i][T|t][I|i][C|c][A|a][L|l]|[M|m][A|a][J|j][O|o][R|r]$/) {
	return 2;
    }
    return 3;
}

##########################
## INSERT TRAP IN DATABASE
#

################
## MAIN FUNCTION
#
sub main($$) {
    my $manuf = $_[1];
    my @db = set_db();
    my $dbh = DBI->connect($db[0], $db[1], $db[2]) or die "Echec de la connexion mysql\n";
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
	    }else {
		$val = getStatus($val,$type);
		my $query = "INSERT INTO `traps` (traps_name, traps_oid, traps_status, manufacturer_id) values ('$name', '$oid', '$val', '$manuf')";
		my $sth = $dbh->prepare($query);
		$sth->execute;
		$sth->finish;
		$last_oid = $oid;
	    }
	}elsif ($_ =~/^FORMAT\ (.*)/ && $last_oid ne "") {
	    my $query = "UPDATE `traps` set traps_args='$1' where traps_oid='$last_oid'";
	    my $sth = $dbh->prepare($query);
	    $sth->execute;
	    $sth->finish;
	}elsif ($_ =~ /^SDESC(.*)/ && $last_oid ne "") {	    
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
		}else {
		    $line =~ s/\"/\\\"/g;
		    $line =~ s/\'/\\\'/g;
		    $desc .= $line;
		}
	    }
	    if ($desc ne "") {
		my $query = "UPDATE `traps` set traps_comments='$desc' where traps_oid='$last_oid'";
		my $sth = $dbh->prepare($query);
		$sth->execute;
		$sth->finish;
	    }
	}
    }
    $dbh->disconnect;
}

Getopt::Long::Configure('bundling');
my ($opt_f, $opt_m);
GetOptions(
	   "f|file=s" => \$opt_f,
	   "m|man=s"  => \$opt_m);
if (!$opt_f || !$opt_m) {
    print "fill_trapDB.pl : Usage : ./fill_trapDB.pl -f configuration_file -m manufacturer_id\n";
    exit;
}
    main($opt_f,$opt_m);
