################################################################################
# Copyright 2005-2013 MERETHIS
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

sub load_oids {
    my ($exit_status, $oid_file) = @_;
    eval 'require Config::IniFiles;';

    if ($@) {
        print "Could not load the Perl module 'Config::IniFiles' $@";
        exit($exit_status);
    }
    require Config::IniFiles;

    unless (-e $oid_file) {
        print "Unknown - In centreon.pm :: $oid_file :: $!\n";
        exit($exit_status);
    }

    my %centreon;
    tie %centreon, 'Config::IniFiles', ( -file => $oid_file );
    return %centreon;
}


sub check_snmp_options {
    my ($exit_status, $OPTION) = @_;
    my %session_params;

    if (!defined($OPTION->{host})) {
        print "Missing parameter -H (--host).\n";
        exit $exit_status;
    }

    $OPTION->{'snmp-version'} =~ s/^v//;
    if ($OPTION->{'snmp-version'} !~ /1|2c|2|3/) {
        print "Unknown snmp version\n";
        exit $exit_status;
    }

    if ($OPTION->{'snmp-version'} eq "3") {
        %session_params = (-hostname => $OPTION->{host}, -version => $OPTION->{'snmp-version'}, -port => $OPTION->{'snmp-port'});

        if (defined($OPTION->{'snmp-auth-password'}) && defined($OPTION->{'snmp-auth-key'})) {
            print "Only option -k (--authkey) or -p (--password) is needed for snmp v3\n";
            exit $exit_status;
        }

        if (!(defined($OPTION->{'snmp-auth-protocol'}) && (defined($OPTION->{'snmp-auth-password'}) || defined($OPTION->{'snmp-auth-key'})) && defined($OPTION->{'snmp-auth-user'}))) {
            print "Missing parameter to open SNMPv3 session\n";
            exit $exit_status;
        }
        $OPTION->{'snmp-auth-protocol'} = lc($OPTION->{'snmp-auth-protocol'});
        if ($OPTION->{'snmp-auth-protocol'} ne "md5" && $OPTION->{'snmp-auth-protocol'} ne "sha") {
            print "Wrong authentication protocol. Must be MD5 or SHA\n";
            exit $exit_status;
        }
        $session_params{-username} = $OPTION->{'snmp-auth-user'};
        $session_params{-authprotocol} = $OPTION->{'snmp-auth-protocol'};
        if (defined($OPTION->{'snmp-auth-password'})) {
            $session_params{-authpassword} = $OPTION->{'snmp-auth-password'};
        } else {
            $session_params{-authkey} = $OPTION->{'snmp-auth-key'};
        }

        if ((defined($OPTION->{'snmp-priv-password'}) || defined($OPTION->{'snmp-priv-key'})) && defined($OPTION->{'snmp-priv-protocol'})) {
            $OPTION->{'snmp-priv-protocol'} = lc($OPTION->{'snmp-priv-protocol'});
            if ($OPTION->{'snmp-priv-protocol'} ne "des" && $OPTION->{'snmp-priv-protocol'} ne "aes" && $OPTION->{'snmp-priv-protocol'} ne "aes128") {
                print "Wrong encryption protocol. Must be DES, AES or AES128\n";
                exit $exit_status;
            }

            if (defined($OPTION->{'snmp-priv-password'}) && defined($OPTION->{'snmp-priv-key'})) {
                print "Only option --privpassword  or --privkey is needed for snmp v3\n";
                exit $exit_status;
            }

            $session_params{-privprotocol} = $OPTION->{'snmp-priv-protocol'};
            if (defined($OPTION->{'snmp-priv-password'})) {
                $session_params{-privpassword} = $OPTION->{'snmp-priv-password'};
            } else {
                $session_params{-privkey} = $OPTION->{'snmp-priv-key'};
            }
        }
    } else {
        %session_params = (-hostname => $OPTION->{'host'},
                           -community => $OPTION->{'snmp-community'},
                           -version => $OPTION->{'snmp-version'},
                           -port => $OPTION->{'snmp-port'});
    }

    if (defined($OPTION->{'64-bits'})) {
        if ($OPTION->{'snmp-version'} =~ /1/) {
            print "Error : Usage : SNMP v2/v3 is required with option --64-bits\n";
            exit $exit_status;
        }

        eval 'require bigint';
        if ($@) {
            print "Could not load the Perl module 'bigint' $@";
            exit($exit_status);
        }
        require bigint;
    }
    
    if (defined($OPTION->{snmptimeout}) && $OPTION->{snmptimeout} =~ /^[0-9]+$/) {
        $session_params{-timeout} = $OPTION->{snmptimeout};
    }

    return (\%session_params);
}

# Method to connect to the remote host
# This method take the hash table option as argument
sub connection {
    my ($exit_status, $session_params) = @_;
    my ($session, $error);

    ($session, $error) = Net::SNMP->session(%$session_params);
    if (!defined($session)) {
        print "UNKNOWN: SNMP Session : $error\n";
        exit $exit_status;
    }

    $session->translate(Net::SNMP->TRANSLATE_NONE);
    return $session;
}

sub get_snmp_table {
    my ($oid, $session, $exit_status, $OPTION) = @_;
    my $result;

    if (defined($OPTION) && defined($OPTION->{'maxrepetitions'})) {
        $result = $session->get_table(Baseoid => $oid, -maxrepetitions => $OPTION->{'maxrepetitions'});
    } else {
        $result = $session->get_table(Baseoid => $oid);
    }
    if (!defined($result)) {
        printf("SNMP TABLE ERROR : %s.\n", $session->error);
        $session->close;
        exit $exit_status;
    }
    return $result;
}

sub get_snmp_leef {
    my ($oids, $session, $exit_status, $extra_msg) = @_;
    my $result = $session->get_request(-varbindlist => $oids);
    if (!defined($result)) {
        printf("SNMP REQUEST ERROR : %s.", $session->error);
        if (defined($extra_msg)) {
            print $extra_msg;
        }
        print "\n";
        $session->close;
        exit $exit_status;
    }
    return $result;
}

1;
