################################################################################
# Copyright 2005-2011 MERETHIS
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
# SVN : $URL
# SVN : $Id
#
####################################################################################

use strict;
use Net::SNMP qw(:snmp);
use warnings;

package Centreon::SNMP::Utils;

# This method  takes the version argument given by the user and 
# return true only if snmp version value is known
sub checkVersion{
	my $self = shift;
	my $snmpversion = shift;
	$snmpversion =~ s/^v//;
	
	if ($snmpversion !~ /1|2c|2|3/) {
		print "Wrong SNMP version\n";
		return 0;

	}
	return 1;
}


# This method take the v3 parameter (username,authprotocol,authpassword,privprotocol,privpassword) in argument and return the session type
# sesssion type = 1 si snmp v1 / v2
# session type = 2 si snmp v3 AuthNoPriv
# session type = 3 si snmp v3 AuthPriv
# session type = 0 si erreur;
sub checkSessiontype{
	my $self = shift;
	my $username = shift;
	my $authprotocol = shift;
	my $authpassword = shift;
	my $privprotocol = shift;
	my $privpassword = shift;
	my $sessionType = 1;

	if (defined($authprotocol) && defined($authpassword) && defined($username)) {
		if ($authprotocol ne "MD5" && $authprotocol ne "SHA1") {
			print "Wrong authentication protocol. Must be MD5 or SHA1 \n";
			return 0;
		}
		$sessionType = 2;
		if (defined($privpassword) && defined($privprotocol)) {
			if ($privprotocol ne "DES" && $privprotocol ne "AES") {
				print "Wrong encryption protocol. Must be DES or AES\n";
				return  0;
			}
			return 3;
		}
	} else{
		print "Missing parameter to open SNMPv3 session\n";
		return 0;
	}
	return $sessionType;
}

# Method to connect to the remote host
# This method take the hash table option as argument
# return $session if OK or 0 if not
sub connection
{
	my $self = shift;
	my $sessionType = shift;
	my $options = shift;
	my ($session, $error);
	
	if ($sessionType == 1) {
		if (!defined($options->{'host'}) || !defined($options->{'snmpport'}) || !defined($options->{'snmpcomm'}) || !defined($options->{'snmpversion'})) {
			print("Error when trying to connect - mission argument(s)\n");
			return 0;
		}
		($session, $error) = Net::SNMP->session(-hostname => $options->{'host'}, 
												-community => $options->{'snmpcomm'}, 
												-version => $options->{'snmpversion'},
												-port => $options->{'snmpport'});

	} elsif ($sessionType == 2) {
		($session, $error) = Net::SNMP->session(-hostname => $options->{'host'}, 
												-version => $options->{'snmpversion'},
												-username => $options->{'username'},
												-authpassword => $options->{'authpassword'},
												-authprotocol => $options->{'authprotocol'},
												-port => $options->{'snmpport'});
	} else {
		($session, $error) = Net::SNMP->session(-hostname => $options->{'host'}, 
												-version => $options->{'snmpversion'},
												-username => $options->{'username'},
												-authpassword => $options->{'authpassword'},
												-authprotocol => $options->{'authprotocol'},
												-privpassword   => $options->{'privpassword'},
												-privprotocol => $options->{'privprotocol'},
												-port => $options->{'snmpport'});

	}
	if (defined($error) && $error ne "") {
		print("SESSION ERROR: ".$error."\n");
		return 0;
	}
	return $session;
}

# Test if OID passed in 2nd parameter exists
sub testOID{
	my $self = shift;
	my $sess = $_[0];
    my $OID_toTest = $_[1];
    my $result = $sess->get_table(Baseoid => $OID_toTest);
    if (!defined($result)) {
    	return 0;
    } else{
		return 1;
	}
}

1;