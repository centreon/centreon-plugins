#! /usr/bin/perl -w
################################################################################
# Copyright 2004-2011 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# 
# SVN : $URL: http://svn.centreon.com/trunk/plugins-2.x/src/check_centreon_snmp_value $
# SVN : $Id: check_centreon_snmp_value 11631 2011-02-08 17:02:51Z shotamchay $
#
####################################################################################
#
# Script init
#
#

use strict;
use Getopt::Long;

require "@NAGIOS_PLUGINS@/Centreon/SNMP/Utils.pm";

my $PROGNAME = "$0";

my %OPTION = ('host' => undef, 'help' => undef, 'warning' => '0', 'critical' => '0', 
			'snmpversion' => 1, 'display' => 0, 'snmpcomm' => 'public',	'min' => 0, 'max' => 0,
			'host' => undef,'username' => undef, 'authpassword' => undef, 'authprotocol' => undef,
			'privprotocol' => undef , 'privpassword' => undef, 'snmpport' => 161, 'type' => 'GAUGE', 'base' => 1000,
			'output' => '%.02f', 'metric' =>'value', 'unit' => 'nounit', 'divide' => 1);
my %ERRORS = ('OK' => 0, 'WARNING' => 1, 'CRITICAL' => 2, 'UNKNOWN' => 3);
my $prefix = "";



sub print_help ();
sub print_usage ();

Getopt::Long::Configure('bundling');
GetOptions
    ("h"   		=> \$OPTION{'help'}, 			"help"				=> \$OPTION{'help'},
	 "P=s" 		=> \$OPTION{'snmpport'}, 		"snmpport=s" 		=> \$OPTION{'snmpport'},
	 "V"   		=> \$OPTION{'pluginversion'},	"version"			=> \$OPTION{'pluginversion'},
     "u=s"   	=> \$OPTION{'username'}, 		"username=s"   		=> \$OPTION{'username'},
	 "a=s" 		=> \$OPTION{'authprotocol'}, 	"authprotocol=s"  	=> \$OPTION{'authprotocol'}, 
	 "A=s"   	=> \$OPTION{'authpassword'}, 	"authpassword=s"    => \$OPTION{'authpassword'},
	 "x=s" 		=> \$OPTION{'privprotocol'}, 	"privprotocol=s"   	=> \$OPTION{'privprotocol'}, 
	 "X=s" 		=> \$OPTION{'privpassword'}, 	"privpassword=s"   	=> \$OPTION{'privpassword'}, 
     "v=s" 		=> \$OPTION{'snmpversion'}, 	"snmp=s"  			=> \$OPTION{'snmpversion'},
     "C=s" 		=> \$OPTION{'snmpcomm'}, 		"community=s"  		=> \$OPTION{'snmpcomm'},
     "w=s" 		=> \$OPTION{'warning'}, 		"warning=s"  		=> \$OPTION{'warning'},
     "c=s" 		=> \$OPTION{'critical'}, 		"critical=s"  		=> \$OPTION{'critical'},
     "H=s" 		=> \$OPTION{'host'}, 			"host=s"   			=> \$OPTION{'host'}, 
	 "o=s" 		=> \$OPTION{'oid'}, 			"oid=s"   			=> \$OPTION{'oid'},
	 "t=s" 		=> \$OPTION{'type'}, 			"type=s"   			=> \$OPTION{'type'}, 
	 "U=s" 		=> \$OPTION{'unit'}, 			"unit=s"   			=> \$OPTION{'unit'},
	 "W=s" 		=> \$OPTION{'warning_table'}, 	"warning_table=s"   => \$OPTION{'warning_table'}, 
	 "T=s" 		=> \$OPTION{'critical_table'}, 	"critical_table=s"  => \$OPTION{'critical_table'}, 
	 "O=s" 		=> \$OPTION{'ok_table'}, 		"ok_table=s" 		=> \$OPTION{'ok_table'}, 
	 "convert"  => \$OPTION{'convert'},
	 "debug" 	=> \$OPTION{'debug'}, 
	 "min=s" 	=> \$OPTION{'min'}, 
	 "max=s"   	=> \$OPTION{'max'},
	 "base=s" 	=> \$OPTION{'base'}, 
	 "64-bits"	=> \$OPTION{'64-bits'},
	 "f=s" 		=> \$OPTION{'output'}, 			"output=s"   		=> \$OPTION{'output'},		
	 "m=s" 		=> \$OPTION{'metric'}, 			"metric=s"   		=> \$OPTION{'metric'});
 	 

my $metricsname = undef;
my $unit = undef;
my $output = undef;
my $min = undef;
my $max = undef;
my $cache = undef;
my $divide = undef;

#used for counter type metric
my $previousValue = undef;
my $previousTime = undef;
my $currentTime = time();
my $currentValue =  undef;

#Table used when personnal threshold are set
my @critical_table = ();
my @warning_table = ();
my @ok_table = ();

#Table used when personnal threshold are set
if($OPTION{'critical_table'}){
	@critical_table = split(/\,/, $OPTION{'critical_table'});
}
if($OPTION{'warning_table'}){
	@warning_table = split(/\,/, $OPTION{'warning_table'});
}
if($OPTION{'ok_table'}){
	@ok_table = split(/\,/, $OPTION{'ok_table'});
}
if (!$OPTION{'oid'}) {
	print "Option -o needed.\n \n";
	print_usage();
    	exit $ERRORS{'UNKNOWN'};
} elsif (!($OPTION{'oid'} =~ /^[0-9\.]+$/)) {
	print "Wrong OID format\n";
	exit $ERRORS{'UNKNOWN'};
}


if (defined($OPTION{'pluginversion'})) {
	print("$PROGNAME  1.2");
	exit $ERRORS{'UNKNOWN'};
}
if (defined($OPTION{'help'})) {
    	print_help();
    	exit $ERRORS{'UNKNOWN'};
}
if (!$OPTION{'host'}) {
	print_usage();
	exit $ERRORS{'UNKNOWN'};
}

my $cacheFile = "@CENTPLUGINS_TMP@/snmp_value_table".$OPTION{'host'}."-".$OPTION{'oid'};

#Store option values in simpler variables
if($OPTION{'divide'} ne "" && $OPTION{'metric'} ne "" &&  $OPTION{'unit'} ne "" && $OPTION{'output'} ne "" && $OPTION{'min'} ne "" && $OPTION{'max'} ne "" ){
	$metricsname = $OPTION{'metric'};
	$unit = $OPTION{'unit'};
	
	#Output Verification?
	$output = $OPTION{'output'};
	
	#check parameter format
	
	if ($OPTION{'base'} !~ /^[0-9]*\.?[0-9]*$/) {
		print(" Base option should be a numerical \n");
		exit $ERRORS{'UNKNOWN'};
	}
	
	if ($OPTION{'min'} !~ /^[0-9]*\.?[0-9]*$/) {
		print(" Min option should be a numerical \n");
		exit $ERRORS{'UNKNOWN'};
	}
	if ($OPTION{'max'} !~ /^[0-9]*\.?[0-9]*$/){
		print(" Max option should be a numerical \n");
		exit $ERRORS{'UNKNOWN'};
	}

	if ($OPTION{'warning'} !~ /^[0-9]*\.?[0-9]*$/ || $OPTION{'critical'} !~ /^[0-9]*\.?[0-9]*$/) {
		print(" Option warning &/or critical should be numerical \n");
		exit $ERRORS{'UNKNOWN'};
	}
	
	$min = $OPTION{'min'};
	$max = $OPTION{'max'};
	$divide = $OPTION{'divide'};
	
}else{
	print("One or more arguments are not set \n");
	exit $ERRORS{'UNKNOWN'};
}

#Check if version passed in option exists
$OPTION{'snmpversion'} =~ s/v//g;
exit $ERRORS{'UNKNOWN'} if (!Centreon::SNMP::Utils->checkVersion($OPTION{'snmpversion'}));

#Check which connection mode is used
my $sessionType = 1;
if ($OPTION{'snmpversion'} =~ /3/) {
	$sessionType = Centreon::SNMP::Utils->checkSessiontype($OPTION{'username'},$OPTION{'authprotocol'},$OPTION{'authpassword'},$OPTION{'privprotocol'},$OPTION{'privpassword'});
	exit $ERRORS{'UNKNOWN'} if(!$sessionType);
}



my $DS_type = "GAUGE";
if ($OPTION{'type'} =~ m/GAUGE/i) {
	$DS_type = "GAUGE";
} elsif ($OPTION{'type'} =~ m/COUNTER/i) {
	$DS_type = "COUNTER";
}

my $critical = $1 if ($OPTION{'critical'} =~ /([0-9]+)/);
my $warning = $1 if ($OPTION{'warning'} =~ /([0-9]+)/);

if ($critical < $warning){
	print "(--critical) must be superior or equal to (--warning)";
	print_usage();
	exit $ERRORS{'UNKNOWN'};
}



# Plugin snmp connection
my ($session);
if (!($session = Centreon::SNMP::Utils->connection($sessionType,\%OPTION))){
	exit $ERRORS{'UNKNOWN'};
}

my @oid_walk; #will contain each path to the final part of OID 
my @oid_list; #Will contain all final OID of the get_table request
my @cache; #Will contain cache file values
my %previousValues;
my %currentValues;
my $i =0;

#Get the different finals OID returned by OID
my $result = $session->get_table(Baseoid => $OPTION{'oid'});
$currentTime = time();

if (!defined($result)) {
	printf("UNKNOWN: %s.\n", $session->error);
	$session->close;
	exit $ERRORS{'UNKNOWN'};
}

foreach my $key (oid_lex_sort(keys %$result)) {
   	@oid_walk = split (/\./,$key);
	$oid_list[$i] = pop(@oid_walk);
	$i++;
}

if ($OPTION{'debug'}) {
	my $size= scalar(@oid_list);
	print(" OID received :  \n");
	for ($i = 0; $i < $size ; $i++) {
		print("oid_list[$i] : $oid_list[$i] \n");
	}
}


#If metric type = counter, use the cache file to get the last value (or create cache file)
if ($DS_type eq 'COUNTER') {
	print("COUNTER \n") if($OPTION{'debug'});

	#If file exist
	if (-e $cacheFile) {
		open(FILE,"<".$cacheFile);
		my $row = <FILE>;
		@cache = split(/;/, $row);
		my $size= scalar(@cache);

		print("File exist \n") if($OPTION{'debug'});
		$previousTime= $cache[0];

		#Get the previous values stored in cachefile
		for ($i = 1; $i < $size ; $i=$i+2) {
			print("OID : $cache[$i] ; Last Value : $cache[$i+1] ; \n") if($OPTION{'debug'});
			$previousValues{$cache[$i]} = $cache[$i+1];
		}

		close(FILE);
		
		#Set new values in cache file
		open(FILE,">".$cacheFile);
		$size= scalar(@oid_list);
		print FILE $currentTime.";";

		for ($i = 0; $i < $size ; $i++) {
			#Get current value for all oid at i position in table of all oid 
			my $result = $session->get_request(-varbindlist => [$OPTION{'oid'}.".".$oid_list[$i]]);
			$currentValue = $result->{$OPTION{'oid'}.".".$oid_list[$i]};

			$currentValues{$oid_list[$i]} = $currentValue;
			print FILE $oid_list[$i].";".$currentValue.";";
			print("oid_list[$i] : $oid_list[$i] ; Current Value : $currentValue ; \n") if($OPTION{'debug'});
		}
		close(FILE);		
	} else {
		my $size= scalar(@oid_list);
		print("File doesn't exist \n") if($OPTION{'debug'});
		#If the file doesnt exist, a new file is created and values are inserted 
		unless (open(FILE,">".$cacheFile)) {
			print "Check temporary file's or existence rights : ".$cacheFile."...\n";
			exit $ERRORS{"UNKNOWN"};
		}
		
		$i = 0;
		print FILE $currentTime.";";
		for ($i = 0; $i < $size ; $i++) {
			my $result = $session->get_request(-varbindlist => [$OPTION{'oid'}.".".$oid_list[$i]]);
			$currentValue = $result->{$OPTION{'oid'}.".".$oid_list[$i]};
			print FILE $oid_list[$i].";".$currentValue.";";
			print("OID : $oid_list[$i] ; Current Value : $currentValue ; \n") if($OPTION{'debug'});
		}

		print("Buffer in creation . . . please wait \n");
		close(FILE);
		exit $ERRORS{"OK"};
	}
} else {
	#Get values for each OID stored in table oid_list[] if not a counter type
	my $size= scalar(@oid_list);
	print("Values for each OID : \n") if($OPTION{'debug'});
	for ($i = 0; $i < $size ; $i++) {
		my $result = $session->get_request(-varbindlist => [$OPTION{'oid'}.".".$oid_list[$i]]);
		$currentValue = $result->{$OPTION{'oid'}.".".$oid_list[$i]};

		$currentValues{$oid_list[$i]} = $currentValue;
		print("oid_list[$i] : $oid_list[$i] ; Current Value : $currentValue ; \n") if($OPTION{'debug'});
	}
}

print("Taille \%currentValues : ".keys(%currentValues)."\n") if($OPTION{'debug'});

#===  Plugin returned value treatments  ====
if (keys(%currentValues) > 0) {
	my $status = "UNKNOWN";
	my $state= "unknownState";
	my %returnValues = %currentValues;
	my %state;
	my $returnValue;
	my $size= keys(%currentValues);
	my $output_message="";
	my $output_warning=""; 
	my $output_critical="";
	my $perf_output_message = "|";
	
	#If personnal tresholds are set
	if($OPTION{'warning_table'} || $OPTION{'critical_table'} || $OPTION{'ok_table'}) {
		print "Mode personal threshold ON \n" if($OPTION{'debug'});
		
		if($OPTION{'ok_table'}) {
			my $max_ok= scalar(@ok_table);
			my $i = 0;
			
			while($i < $max_ok) {
				for(my $u=0; $u < $size;$u++) {
					print "OK[$i]:  $ok_table[$i] / returnValue = $returnValues{$oid_list[$i]} \n" if($OPTION{'debug'});
					if($ok_table[$i] == $returnValues{$oid_list[$u]}) {
						$status =  "OK";
						$state{$oid_list[$i]} = $ok_table[$i+1];
					}
				}
				$i = $i+2;
			}
		}
		if($OPTION{'warning_table'}) {
			my $max_warn= scalar(@warning_table);
			my $i = 0;
			while($i < $max_warn) {
				for(my $u=0; $u < $size;$u++) {
					print "Warning[$i]:  $warning_table[$i] / returnValue = $returnValues{$oid_list[$u]} \n" if($OPTION{'debug'});
					if($warning_table[$i] == $returnValues{$oid_list[$u]}) {
						print("Warning match \n") if($OPTION{'debug'});
						$status =  "WARNING";
						$state{$oid_list[$u]} = $warning_table[$i+1];
						$output_warning .= "OID.".$oid_list[$u].": ".$warning_table[$i+1]."; ";
					}
				}					
				$i = $i+2;
			}	
			$output_warning = "(Warning)".$output_warning if($status eq "WARNING");
		}
		if($OPTION{'critical_table'}) {
			my $i = 0;
			my $max_crit= scalar(@critical_table);
			while($i < $max_crit){
				
				for(my $u=0; $u < $size;$u++){
				print "Critical[$i] = $critical_table[$i] / returnValue = $returnValues{$oid_list[$u]} \n" if($OPTION{'debug'});
					if($critical_table[$i] == $returnValues{$oid_list[$u]}) {
						print("Critical match \n") if($OPTION{'debug'});
						$status =  "CRITICAL";
						$state{$oid_list[$u]} = $critical_table[$i+1];
						$output_critical .= "OID.".$oid_list[$u].": ".$critical_table[$i+1]."; ";
					}
				}
				$i = $i + 2;
			}
			$output_critical = "(Critical) ".$output_critical if($status eq "CRITICAL");
		}
		if($status eq "OK") {
			print("All values of table $OPTION{'oid'} are OK \n");
			exit $ERRORS{"OK"};
		} elsif($status eq "UNKNOWN") {
			print("Unknown : None of the values given in argument match with OID values \n");
			exit $ERRORS{$status};
		} else {
			print($output_critical." ".$output_warning."\n");
			exit $ERRORS{$status};	
		}
	}

	#calculate value for counter metric type
	#if counter has been reseted between 2 checks 
	if ($DS_type eq 'COUNTER') {
		for (my $i = 0; $i < $size ; $i++) {
			if ($currentValues{$oid_list[$i]} - $previousValues{$oid_list[$i]} < 0) {
				if (defined($OPTION{'64-bits'})) {
					$returnValues{$oid_list[$i]} = ((18446744073709551616) - $previousValues{$oid_list[$i]} + $currentValues{$oid_list[$i]})/($currentTime - $previousTime);
				} else {
					$returnValues{$oid_list[$i]} = ((4294967296) - $previousValues{$oid_list[$i]} + $currentValues{$oid_list[$i]})/( $currentTime - $previousTime );
				}
			} else {
				$returnValues{$oid_list[$i]} = ($currentValues{$oid_list[$i]} - $previousValues{$oid_list[$i]}) / ( $currentTime - $previousTime );
			}
		}
	}
	
	if($OPTION{'debug'}) {
		for ( my $i = 0; $i < $size ; $i++) {
			print(" ValuetoReturn OiD: $oid_list[$i] : $returnValues{$oid_list[$i]} \n"); 
		}
	}
	
	#Set in Ok Critical and Warning hashes the value corresponding to the different status.
	#Finally, if Critical and Warning are empty, the plugin return OK, else , the plugin returns the value in Critical and Warning hashes
	my %Ok;
	my %Critical;
	my %Warning;
	my %perfdata;
	
	if(defined($OPTION{'convert'})) {
		$warning = ($OPTION{'warning'} * $max)/100;
		$critical = ($OPTION{'critical'} * $max)/100;
	} else {
		$warning = $OPTION{'warning'};
		$critical = $OPTION{'critical'};
	}
		
	#Test for each OID if the value returned is warning / critical or ok
	for (my $i = 0; $i < $size ; $i++) {
		if ($returnValues{$oid_list[$i]} < $warning) {
			$Ok{$oid_list[$i]} = $returnValues{$oid_list[$i]};
		} elsif ($warning != 0 && $warning <= $returnValues{$oid_list[$i]}  &&  $returnValues{$oid_list[$i]} < $critical) {
			$Warning{$oid_list[$i]} = $returnValues{$oid_list[$i]};
		}elsif($critical != 0 && $returnValues{$oid_list[$i]}  >= $critical){
			$Critical{$oid_list[$i]} = $returnValues{$oid_list[$i]};
		}
	}
	
	if($OPTION{'debug'}){
		print("%Ok size : ".keys(%Ok)." \t %Warning size : ".keys(%Warning)." \t %Critical size : ".keys(%Critical)." \n");
	}
	
	if(keys(%Critical) == 0 && keys(%Warning) == 0) {
		$output_message = "All values of table $OPTION{'oid'} are OK";
		$state = "OK";
	}

	$i = 0;
	%perfdata = %returnValues;
	#Formating the data for the output message
	for (my $i = 0; $i < $size ; $i++){
		my $u = 0;
		$prefix = "";
		if($warning != 0 && $returnValues{$oid_list[$i]}  > $warning){
			while($returnValues{$oid_list[$i]} > $OPTION{'base'})
			{
				$returnValues{$oid_list[$i]} = $returnValues{$oid_list[$i]} / $OPTION{'base'};
				$u++;
			}
			if ($OPTION{'base'} == 1024) {
				$prefix = "ki" if($u == 1);
				$prefix = "Mi" if($u == 2);
				$prefix = "Gi" if($u == 3);
				$prefix = "Ti" if($u == 4);
			} elsif($OPTION{'base'} == 1000){
				$prefix = "k" if($u == 1);
				$prefix = "M" if($u == 2);
				$prefix = "G" if($u == 3);
				$prefix = "T" if($u == 4);
			}
			$output_message.=sprintf("OID.".$oid_list[$i]."=".$output." ".$prefix.$unit." ",$returnValues{$oid_list[$i]});
		}
	}

	for (my $i = 0; $i < $size ; $i++){
		$perf_output_message .=$metricsname.".".$oid_list[$i]."=".$perfdata{$oid_list[$i]}.$unit.";".$warning.";".$critical.";".$min.";".$max." ";
	}
	
	if(keys(%Critical)!=0) {
		$state = "CRITICAL";
	}elsif(keys(%Warning)!=0) {
		$state = "WARNING";
	}
	print($output_message.$perf_output_message."\n");
	exit $ERRORS{$state};
} else {
	print "CRITICAL Host unavailable\n";
	exit $ERRORS{'CRITICAL'};
}


sub print_usage () {
	print "Usage:";
	print "$PROGNAME\n";
	print "   -H (--hostname)   \t Hostname to query - (required)\n";
	print "   -C (--community)  \t SNMP read community (defaults to public,\n";
	print "               \t \t used with SNMP v1 and v2c\n";
	print "   -v (--snmp_version) \t 1 for SNMP v1 (default)\n";
	print "                       \t 2 for SNMP v2c\n";
	print "   -t (--type)       \t Data Source Type (GAUGE or COUNTER) (GAUGE by default)\n";
	print "   -o (--oid)        \t OID to check\n";
   	print "   -u (--username)     \t snmp v3 username \n";
	print "   -a (--authprotocol) \t protocol MD5/SHA1  (v3)\n";
	print "   -A (--authpassword) \t password (v3) \n";
	print "   -x (--privprotocol) \t encryption system (DES/AES)(v3) \n";
	print "   -X (--privpassword)\t passphrase (v3) \n";
	print "   -w (--warning)    \t Warning level \n";
	print "   -c (--critical) \t Critical level \n";
	print "   -W (--wtreshold)    \t Personal warning threshold : -W 1,normal,... \n";
	print "   -T (--ctreshold)    \t Personal critical threshold : -T 3,notResponding,4,NotFunctionning,... \n";
	print "   --convert \t \t If critical and warning, given in %tages, have to be converted regarding to the max value \n";
	print "   -m (--metric)   \t Metric Name\n";
	print "   --64-bits \t \t  If counter type to use = 64-bits \n";
	print "   -U (--unit)   \t Metric's unit ( /!\\ for % write %% ) \n";
	print "   -f (--output)  \t Output format (ex : -f \"%0.2f \" \n";
	print "   --min  \t \t min value for the metric (default = 0) \n";
	print "   --max  \t \t max value for the metric (default = 0)\n";
	print "   --base  \t \t will divide the returned number by \"base\" until it's inferior to it. \n";
	print "            \t \t ex: 2000000 in base 1000 will be transformed to 2M (default 1000) \n";
	print "   -V (--version)  \t Plugin version\n";
	print "   -h (--help)      \t usage help\n";
}

sub print_help () {
	print "##############################################\n";
	print "#    Copyright (c) 2004-2011 Centreon        #\n";
	print "#    Bugs to http://forge.centreon.com/      #\n";
	print "##############################################\n";
	print_usage();
	print "\n";
}


