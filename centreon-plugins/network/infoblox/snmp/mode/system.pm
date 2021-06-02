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

package network::infoblox::snmp::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_ha_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "high-availablity status is '%s'",
        $self->{result_values}->{ha_status}
    );
}

sub system_long_output {
    my ($self, %options) = @_;

    return "checking system '" .  $options{instance_value}->{hw_type} . "'";
}

sub set_counters {
    my ($self, %options) = @_;
    
     $self->{maps_counters_type} = [
        { name => 'system', type => 3, cb_long_output => 'system_long_output', indent_long_output => '    ',
            group => [
                { name => 'cpu', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'memory', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'swap', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'temperature', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'ha', type => 0, display_short => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'cpu-load', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_load' } ],
                output_template => 'cpu load: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'memory-usage', nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'memory_used' } ],
                output_template => 'memory used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{swap} = [
        { label => 'swap-usage', nlabel => 'swap.usage.percentage', set => {
                key_values => [ { name => 'swap_used' } ],
                output_template => 'swap used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{temperature} = [
        { label => 'cpu1-temperature', nlabel => 'system.cpu1.temperature.celsius', set => {
                key_values => [ { name => 'cpu1_temp' } ],
                output_template => 'cpu1 temperature: %.2f C',
                perfdatas => [
                    { template => '%.2f', unit => 'C' }
                ]
            }
        },
        { label => 'cpu2-temperature', nlabel => 'system.cpu2.temperature.celsius', set => {
                key_values => [ { name => 'cpu2_temp' } ],
                output_template => 'cpu2 temperature: %.2f C',
                perfdatas => [
                    { template => '%.2f', unit => 'C' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{ha} = [
        { label => 'ha-status', type => 2, set => {
                key_values => [ { name => 'ha_status' }, ],
                closure_custom_output => $self->can('custom_ha_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
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

    my $mapping = {
        hw_type     => { oid => '.1.3.6.1.4.1.7779.3.1.1.2.1.4' }, # ibHardwareType
        cpu_load    => { oid => '.1.3.6.1.4.1.7779.3.1.1.2.1.8.1.1' }, # ibSystemMonitorCpuUsage
        memory_used => { oid => '.1.3.6.1.4.1.7779.3.1.1.2.1.8.2.1' }, # ibSystemMonitorMemUsage
        swap_used   => { oid => '.1.3.6.1.4.1.7779.3.1.1.2.1.8.3.1' }, # ibSystemMonitorSwapUsage
        ha_status   => { oid => '.1.3.6.1.4.1.7779.3.1.1.2.1.13' }, # ibHaStatus
        cpu1_temp   => { oid => '.1.3.6.1.4.1.7779.3.1.1.2.1.17' }, # ibCPU1Temperature
        cpu2_temp   => { oid => '.1.3.6.1.4.1.7779.3.1.1.2.1.18' }  # ibCPU2Temperature
    };

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);

    $self->{output}->output_add(short_msg => "System '" . $result->{hw_type} . "' is ok");
    $result->{cpu1_temp} = defined($result->{cpu1_temp}) && $result->{cpu1_temp} > 0 ? sprintf('%.2f', $result->{cpu1_temp}) : undef;
    $result->{cpu2_temp} = defined($result->{cpu2_temp}) && $result->{cpu2_temp} > 0 ? sprintf('%.2f', $result->{cpu2_temp}) : undef;

    $self->{system} = {
        global => {
            hw_type => $result->{hw_type},
            cpu => { cpu_load => $result->{cpu_load} },
            memory => { memory_used => $result->{memory_used} },
            swap => { swap_used => $result->{swap_used} },
            temperature => {
                cpu1_temp => $result->{cpu1_temp},
                cpu2_temp => $result->{cpu2_temp}
            },
            ha => { ha_status => $result->{ha_status} }
        }
    };
}

1;

__END__

=head1 MODE

Check system usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^memory-usage$'

=item B<--warning-ha-status>

Set warning threshold for status.
Can used special variables like: %{ha_status}

=item B<--critical-ha-status>

Set critical threshold for status.
Can used special variables like: %{ha_status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-load' (%), 'cpu1-temperature', 'cpu2-temperature', 'swap-usage' (%), 'memory-usage' (%).

=back

=cut
