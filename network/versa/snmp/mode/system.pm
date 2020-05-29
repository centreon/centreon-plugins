#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::versa::snmp::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'cpu', nlabel => 'appliance.cpu.load.percentage', set => {
                key_values => [ { name => 'cpu' } ],
                output_template => 'CPU Load: %s%%',
                perfdatas => [
                    { label => 'cpu_load', template => '%s', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'memory', nlabel => 'appliance.memory.load.percentage', set => {
                key_values => [ { name => 'memory' } ],
                output_template => 'Memory Load: %s%%',
                perfdatas => [
                    { label => 'memory_load', template => '%s', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'active-sessions', nlabel => 'appliance.sessions.active.count', set => {
                key_values => [ { name => 'sessions_active' } ],
                output_template => 'Active sessions: %s',
                perfdatas => [
                    { label => 'active_sessions', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'failed-sessions', nlabel => 'appliance.sessions.failed.count', set => {
                key_values => [ { name => 'sessions_failed' } ],
                output_template => 'Failed sessions : %s',
                perfdatas => [
                    { label => 'failed_sessions', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'sessions-used-prct', nlabel => 'appliance.sessions.usage.percentage', set => {
                key_values => [ { name => 'sessions_prct_used' } ],
                output_template => 'Sessions used (prct): %s%%',
                perfdatas => [
                    { label => 'active_sessions', template => '%s', min => 0, unit => '%' },
                ],
            }
        },
        { label => 'sessions-free-prct', nlabel => 'appliance.sessions.free.percentage', set => {
                key_values => [ { name => 'sessions_prct_free' } ],
                output_template => 'Sessions free (prct): %s%%',
                perfdatas => [
                    { label => 'free_sessions', template => '%s', min => 0, unit => '%' },
                ],
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_deviceTableEntry = '.1.3.6.1.4.1.42359.2.2.1.1.1.1';

    my $mapping_device = {
        deviceCPULoad           => { oid => '.1.3.6.1.4.1.42359.2.2.1.1.1.1.2' },
        deviceMemoryLoad        => { oid => '.1.3.6.1.4.1.42359.2.2.1.1.1.1.3' },
        deviceBuffer            => { oid => '.1.3.6.1.4.1.42359.2.2.1.1.1.1.4' }, # deprecated, ignoring
        deviceActiveSessions    => { oid => '.1.3.6.1.4.1.42359.2.2.1.1.1.1.5' },
        deviceFailedSessions    => { oid => '.1.3.6.1.4.1.42359.2.2.1.1.1.1.6' },
        deviceMaxSessions       => { oid => '.1.3.6.1.4.1.42359.2.2.1.1.1.1.7' }
    };
    
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_deviceTableEntry,
        start => $mapping_device->{deviceCPULoad}->{oid},
        end => $mapping_device->{deviceMaxSessions}->{oid},
        nothing_quit => 1
    );

    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping_device->{deviceCPULoad}->{oid}\.(.*)/);
        my $instance = $1;
        $self->{global} = { cpu => $snmp_result->{$mapping_device->{deviceCPULoad}->{oid} . "." . $instance},
                            memory => $snmp_result->{$mapping_device->{deviceMemoryLoad}->{oid} . "." . $instance},
                            sessions_active => $snmp_result->{$mapping_device->{deviceActiveSessions}->{oid} . "." . $instance},
                            sessions_failed => $snmp_result->{$mapping_device->{deviceFailedSessions}->{oid} . "." . $instance},
                        };
        $self->{global}->{sessions_prct_used} = ($self->{global}->{sessions_active} + $self->{global}->{sessions_failed}) * 100 / 
                                                $snmp_result->{$mapping_device->{deviceMaxSessions}->{oid} . "." . $instance};
        $self->{global}->{sessions_prct_free} = 100 - $self->{global}->{sessions_prct_used};
    }

}

1;

__END__

=head1 MODE

Check system statistics (cpu, memory, sessions)

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^(cpu)$'

=item B<--warning-*>

Threshold warning.
Can be: 'cpu', 'memory', 'active-sessions', 'failed-sessions', 'sessions-used-prct', 'sessions-free-prct'.

=item B<--critical-*>

Threshold critical.
Can be: 'cpu', 'memory', 'active-sessions', 'failed-sessions', 'sessions-used-prct', 'sessions-free-prct'.

=back

=cut
