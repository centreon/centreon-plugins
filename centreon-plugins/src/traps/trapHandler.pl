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

###############################
## GET HOSTNAME FROM IP ADDRESS
#
sub get_hostinfos($$)
{
    my $requete = "SELECT host_name FROM host WHERE host_address='$_[1]' ";
    my $sth = $_[0]->prepare($requete);
    $sth->execute();
    my @host;
    while (my $temp = $sth -> fetchrow_array) {
	$host[scalar(@host)] = $temp;
    }
    $sth -> finish;
    return @host;
}

##########################
## GET SERVICE DESCRIPTION
#
sub get_servicename($$$)
{
    my $query_host = "SELECT host_id from host WHERE host_name ='$_[2]'";
    my $sth = $_[0]->prepare($query_host);
    $sth->execute();
    my $host_id = $sth -> fetchrow_array;
    if (!defined $host_id) {
	exit;
    }
    $sth->finish;
    my $query_trap = "SELECT traps_id, traps_args, traps_status from traps where traps_oid='$_[1]'";
    $sth = $_[0]->prepare($query_trap);
    $sth->execute();
    my ($trap_id,$argument, $trap_status)  =  $sth -> fetchrow_array;
    if (!defined $trap_id) {
	exit;
    }
    my $query_services = "SELECT service_description FROM service s, host_service_relation h, traps_service_relation t";
    $query_services .= " where s.service_id = t.service_id and t.traps_id='$trap_id' and s.service_id=h.service_service_id";
    $query_services .= " and h.host_host_id='$host_id'";
    $sth = $_[0]->prepare($query_services);
    $sth->execute();
    my @service;
    while (my $temp = $sth -> fetchrow_array) {
	$service[scalar(@service)] = $temp;
    }
    my $query_hostgroup_services = "SELECT service_description FROM hostgroup_relation hgr, traps_service_relation t, service s, host_service_relation hsr";
    $query_hostgroup_services .= " WHERE hgr.host_host_id = '".$host_id."' AND hsr.hostgroup_hg_id = hgr.hostgroup_hg_id";
    $query_hostgroup_services .= " AND s.service_id = hsr.service_service_id and s.service_id=t.service_id and t.traps_id='$trap_id'";
    $sth -> finish;
    $sth = $_[0]->prepare($query_hostgroup_services);
    $sth->execute();
    my @new_service;
    while (my $temp = $sth -> fetchrow_array){
	$new_service[scalar(@new_service)] = $temp;
    }
    $sth -> finish;
    return $trap_status, $argument, (@service,@new_service);
}

#######################################
## GET HOSTNAME AND SERVICE DESCRIPTION
#
sub getTrapsInfos($$$)
{
    my $ip = shift;
    my $oid = shift;
    my $arguments_line = shift;
    my @db = set_db();
    my $dbh = DBI->connect($db[0], $db[1], $db[2]) or die "Echec de la connexion\n";
    my @host = get_hostinfos($dbh, $ip);
    foreach(@host) {
	my $this_host = $_;
	my ($status, $argument, @servicename) = get_servicename($dbh, $oid, $_);
	foreach (@servicename) {
	    my $this_service = $_;
	    my $datetime=`date +%s`;
	    my @vars = split /\ /,$arguments_line;
	    $argument =~ s/\$([0-9]+)/$vars[$1-1]/g;
	    chomp($datetime);
	    my $submit = `/usr/bin/printf "[$datetime] PROCESS_SERVICE_CHECK_RESULT;$this_host;$this_service;$status;$argument" >> /srv/nagios/var/rw/nagios.cmd`;
	}
    }
    $dbh -> disconnect;
    exit;
}

##########################
## PARSE TRAP INFORMATIONS
#
if (scalar(@ARGV)) {
    my $ip = $ARGV[0];
    my $oid = $ARGV[1];
    my $arguments = $ARGV[2];
    getTrapsInfos($ip, $oid, $arguments);
}
