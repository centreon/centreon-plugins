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
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package hardware::server::sun::mgmtcards::lib::telnet;

use strict;
use warnings;
use Net::Telnet;

sub telnet_error {
    my ($output, $msg) = @_;
    
    $output->output_add(severity => 'UNKNOWN',
                        short_msg => $msg);
    $output->display();
    $output->exit();
}

sub connect {
    my (%options) = @_;
    my $telnet_connection = new Net::Telnet(Timeout => $options{timeout});
   
    $telnet_connection->open(Host => $options{hostname},
                             Port => $options{port},
                             Errmode => 'return') or telnet_error($options{output}, $telnet_connection->errmsg);
    
    if (defined($options{closure})) {
        &{$options{closure}}($telnet_connection);
    }
    
    
    if (defined($options{username}) && $options{username} ne "") {
        $telnet_connection->waitfor(Match => '/login: $/i', Errmode => "return") or telnet_error($options{output}, $telnet_connection->errmsg);
        $telnet_connection->print($options{username});
    }

    if (defined($options{password}) && $options{password} ne "") {
        $telnet_connection->waitfor(Match => '/password: $/i', Errmode => "return") or telnet_error($options{output}, $telnet_connection->errmsg);
        $telnet_connection->print($options{password});

        # Check if successful
        my ($prematch, $match);
        
        if (defined($options{special_wait})) {
            ($prematch, $match) = $telnet_connection->waitfor(Match => '/login[: ]*$/i',
                                                              Match => '/username[: ]*$/i',
                                                              Match => '/password[: ]*$/i',
                                                              Match => '/' . $options{special_wait} . '/i',
                                                              Match => $telnet_connection->prompt,
                                                              Errmode => "return") or
                                            telnet_error($options{output}, $telnet_connection->errmsg);
        } else {
            ($prematch, $match) = $telnet_connection->waitfor(Match => '/login[: ]*$/i',
                                                              Match => '/username[: ]*$/i',
                                                              Match => '/password[: ]*$/i',
                                                              Match => $telnet_connection->prompt,
                                                              Errmode => "return") or
                                            telnet_error($options{output}, $telnet_connection->errmsg);
        }
        if ($match =~ /login[: ]*$/i or $match =~ /username[: ]*$/i or $match =~ /password[: ]*$/i) {
            $options{output}->output_add(severity => 'UNKNOWN',
                                         short_msg => 'Login failed: bad name or password');
            $options{output}->display();
            $options{output}->exit();
        }
    }
    
    # Sometimes need special characters
    if (defined($options{noprompt})) {
        return $telnet_connection;
    }
    
    if (!(defined($options{password}) && $options{password} ne "")) {
        $telnet_connection->waitfor(Match => $telnet_connection->prompt,
                                    Errmode => "return") or telnet_error($options{output}, $telnet_connection->errmsg);
    }
    
    return $telnet_connection;
}

1;

__END__

