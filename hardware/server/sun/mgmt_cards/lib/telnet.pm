#
# Copyright 2021 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package hardware::server::sun::mgmt_cards::lib::telnet;

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

