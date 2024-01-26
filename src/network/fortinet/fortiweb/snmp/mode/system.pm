#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::fortinet::fortiweb::snmp::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_ha_status_output {
    my ($self, %options) = @_;
    
    return sprintf('high-availability mode: %s', $self->{result_values}->{ha_mode});
}

sub system_long_output {
    my ($self, %options) = @_;

    return 'checking system';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'system', type => 3, cb_long_output => 'system_long_output', indent_long_output => '    ',
            group => [
                { name => 'ha', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'cpu', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'memory', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'disk', type => 0, display_short => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{ha} = [
        { label => 'ha-status', type => 2, set => {
                key_values => [ { name => 'ha_mode' }, ],
                closure_custom_output => $self->can('custom_ha_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
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

    $self->{maps_counters}->{disk} = [
        { label => 'disk-usage', nlabel => 'disk.log.space.usage.percentage', set => {
                key_values => [ { name => 'disk_used' } ],
                output_template => 'disk log space used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
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

    my $mapping_ha_mode = {
        1 => 'standalone', 2 => 'master', 3 => 'slave'
    };
    my $mapping = {
        ha_mode     => { oid => '.1.3.6.1.4.1.12356.107.2.1.3', map => $mapping_ha_mode }, # fwSysHaMode
        cpu_load    => { oid => '.1.3.6.1.4.1.12356.107.2.1.5' }, # fwSysCpuUsage
        memory_used => { oid => '.1.3.6.1.4.1.12356.107.2.1.7' }, # fwSysMemUsage
        disk_used   => { oid => '.1.3.6.1.4.1.12356.107.2.1.9' } # fwSysDiskUsage
    };

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);

    $self->{output}->output_add(short_msg => 'system usage is ok');

    $self->{system} = {
        global => {
            ha => { ha_mode => $result->{ha_mode} },
            cpu => { cpu_load => $result->{cpu_load} },
            memory => { memory_used => $result->{memory_used} },
            disk => { disk_used => $result->{disk_used} }
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
Example: --filter-counters='memory-usage'

=item B<--warning-ha-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{ha_mode}

=item B<--critical-ha-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{ha_mode}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'disk-usage' (%), 'memory-usage' (%), 'cpu-load' (%).

=back

=cut
