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

package hardware::kvm::adder::aim::snmp::mode::serverusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'cpu-load', set => {
                key_values => [ { name => 'cpu_load' } ],
                output_template => 'CPU Load : %s',
                perfdatas => [
                    { label => 'cpu_load', value => 'cpu_load', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'memory', set => {
                key_values => [ { name => 'memory_used' } ],
                output_template => 'Memory Used : %s %%',
                perfdatas => [
                    { label => 'memory_used', value => 'memory_used', template => '%s',
                      unit => '%', min => 0, max => 100 },
                ],
            }
        },
        { label => 'disk', set => {
                key_values => [ { name => 'disk_used' } ],
                output_template => 'Disk Used : %s %%',
                perfdatas => [
                    { label => 'disk_used', value => 'disk_used', template => '%s',
                      unit => '%', min => 0, max => 100 },
                ],
            }
        },
        { label => 'num-active-con', set => {
                key_values => [ { name => 'num_active_con' } ],
                output_template => 'Current Connected Rx : %s',
                perfdatas => [
                    { label => 'num_active_con', value => 'num_active_con', template => '%s', min => 0},
                ],
            }
        },
        { label => 'num-rx', set => {
                key_values => [ { name => 'num_rx' } ],
                output_template => 'Number Rx : %s',
                perfdatas => [
                    { label => 'num_rx', value => 'num_rx', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'num-tx', set => {
                key_values => [ { name => 'num_tx' } ],
                output_template => 'Numbre Tx : %s',
                perfdatas => [
                    { label => 'num_tx', value => 'num_tx', template => '%s', min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                });
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
                                                           
    my $oid_numRx = '.1.3.6.1.4.1.25119.1.2.1.0';
    my $oid_numTx = '.1.3.6.1.4.1.25119.1.2.2.0';
    my $oid_numActiveConnexions = '.1.3.6.1.4.1.25119.1.2.3.0';
    my $oid_serverCPULoad = '.1.3.6.1.4.1.25119.1.3.1.0';
    my $oid_serverMemoryUsage = '.1.3.6.1.4.1.25119.1.3.2.0';
    my $oid_serverDiskSpace = '.1.3.6.1.4.1.25119.1.3.4.0';
    my $result = $options{snmp}->get_leef(oids => [
            $oid_numRx, $oid_numTx, $oid_numActiveConnexions, 
            $oid_serverCPULoad, $oid_serverMemoryUsage, $oid_serverDiskSpace
        ], 
        nothing_quit => 1);
    $result->{$oid_serverMemoryUsage} =~ s/%//g;
    $result->{$oid_serverDiskSpace} =~ s/%//g;
    
    $self->{global} = {
        num_rx => $result->{$oid_numRx}, num_tx => $result->{$oid_numTx},
        num_active_con => $result->{$oid_numActiveConnexions},
        cpu_load => $result->{$oid_serverCPULoad},
        memory_used => $result->{$oid_serverMemoryUsage},
        disk_used => $result->{$oid_serverDiskSpace},
    };
}

1;

__END__

=head1 MODE

Check server usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^cpu-load$'

=item B<--warning-*>

Threshold warning.
Can be: 'cpu-load', 'memory', 'disk', 'num-rx', 
'num-tx', 'num-active-con'.

=item B<--critical-*>

Threshold critical.
Can be: 'cpu-load', 'memory', 'disk', 'num-rx', 
'num-tx', 'num-active-con'.

=back

=cut
