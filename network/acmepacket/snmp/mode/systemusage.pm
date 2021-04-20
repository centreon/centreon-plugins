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

package network::acmepacket::snmp::mode::systemusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;
    
    return sprintf('replication state: %s', $self->{result_values}->{replication_state});
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
                { name => 'health', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'cpu', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'memory', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'license', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'sessions', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'calls', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'replication', type => 0, display_short => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{health} = [
        { label => 'health-score', nlabel => 'health.score.percentage', set => {
                key_values => [ { name => 'health_score' } ],
                output_template => 'health score: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
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

    $self->{maps_counters}->{license} = [
        { label => 'license-usage', nlabel => 'licence.usage.percentage', set => {
                key_values => [ { name => 'license_used' } ],
                output_template => 'license used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' },
                ]
            }
        }
    ];

    $self->{maps_counters}->{sessions} = [
        { label => 'current-sessions', nlabel => 'sessions.current.count', set => {
                key_values => [ { name => 'current_sessions' } ],
                output_template => 'current sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{calls} = [
        { label => 'current-calls', nlabel => 'calls.current.count', set => {
                key_values => [ { name => 'current_calls' } ],
                output_template => 'current calls: %s/s',
                perfdatas => [
                    { template => '%s', unit => '/s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{replication} = [
        { label => 'replication-status', type => 2, critical_default => '%{replication_state} =~ /outOfService/i', set => {
                key_values => [ { name => 'replication_state' }, ],
                closure_custom_output => $self->can('custom_status_output'),
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

    my $mapping_redundancy = {
        0 => 'unknown', 1 => 'initial', 2 => 'active', 3 => 'standby', 
        4 => 'outOfService', 5 => 'unassigned', 6 => 'activePending', 
        7 => 'standbyPending', 8 => 'outOfServicePending', 9 => 'recovery'
    };
    my $mapping = {
        cpu_load          => { oid => '.1.3.6.1.4.1.9148.3.2.1.1.1' }, # apSysCPUUtil
        memory_used       => { oid => '.1.3.6.1.4.1.9148.3.2.1.1.2' }, # apSysMemoryUtil
        health_score      => { oid => '.1.3.6.1.4.1.9148.3.2.1.1.3' }, # apSysHealthScore
        replication_state => { oid => '.1.3.6.1.4.1.9148.3.2.1.1.4', map => $mapping_redundancy }, # apSysRedundancy
        current_sessions  => { oid => '.1.3.6.1.4.1.9148.3.2.1.1.5' }, # apSysGlobalConSess
        current_calls     => { oid => '.1.3.6.1.4.1.9148.3.2.1.1.6' }, # apSysGlobalCPS
        license_used      => { oid => '.1.3.6.1.4.1.9148.3.2.1.1.10' } # apSysLicenseCapacity
    };

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);

    $self->{output}->output_add(short_msg => 'System usage is ok');

    $self->{system} = {
        global => {
            health => { health_score => $result->{health_score} },
            cpu => { cpu_load => $result->{cpu_load} },
            memory => { memory_used => $result->{memory_used} },
            license => { license_used => $result->{license_used} },
            sessions => { current_sessions => $result->{current_sessions} },
            calls => { current_calls => $result->{current_calls} },
            replication => { replication_state => $result->{replication_state} }
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

=item B<--warning-replication-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{replication_state}

=item B<--critical-replication-status>

Set critical threshold for status (Default: '%{replication_state} =~ /outOfService/i').
Can used special variables like: %{replication_state}

=item B<--warning-*>

Threshold warning.
Can be: 'license-usage' (%), 'memory-usage' (%), 'cpu-load' (%),
'health-score' (%), 'current-sessions', 'current-calls'.

=item B<--critical-*>

Threshold critical.
Can be: 'license-usage' (%), 'memory-usage' (%), 'cpu-load' (%),
'health-score' (%), 'current-sessions', 'current-calls'.

=back

=cut
