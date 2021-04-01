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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf('replication state : %s', $self->{result_values}->{replication_state});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{replication_state} = $options{new_datas}->{$self->{instance} . '_replication_state'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'health-score', nlabel => 'health.score.percentage', set => {
                key_values => [ { name => 'health_score' } ],
                output_template => 'Health Score : %.2f %%',
                perfdatas => [
                    { label => 'health_score', value => 'health_score', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'cpu-load', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_load' } ],
                output_template => 'Cpu Load : %.2f %%',
                perfdatas => [
                    { label => 'cpu_load', value => 'cpu_load', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'memory-usage', nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'memory_used' } ],
                output_template => 'Memory Used : %.2f %%',
                perfdatas => [
                    { label => 'memory_used', value => 'memory_used', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'license-usage', nlabel => 'licence.usage.percentage', set => {
                key_values => [ { name => 'license_used' } ],
                output_template => 'License Used : %.2f %%',
                perfdatas => [
                    { label => 'license_used', value => 'license_used', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'current-sessions', nlabel => 'sessions.current.count', set => {
                key_values => [ { name => 'current_sessions' } ],
                output_template => 'Current Sessions : %s',
                perfdatas => [
                    { label => 'current_sessions', value => 'current_sessions', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'current-calls', nlabel => 'calls.current.count', set => {
                key_values => [ { name => 'current_calls' } ],
                output_template => 'Current Calls : %s/s',
                perfdatas => [
                    { label => 'current_calls', value => 'current_calls', template => '%s',
                      unit => '/s', min => 0 },
                ],
            }
        },
        { label => 'replication-status', threshold => 0, set => {
                key_values => [ { name => 'replication_state' }, ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
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
                                "warning-replication-status:s"    => { name => 'warning_replication_status', default => '' },
                                "critical-replication-status:s"   => { name => 'critical_replication_status', default => '%{replication_state} =~ /outOfService/i' },
                                });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_replication_status', 'critical_replication_status']);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my %mapping_redundancy = (
        0 => 'unknown', 1 => 'initial', 2 => 'active', 3 => 'standby', 
        4 => 'outOfService', 5 => 'unassigned', 6 => 'activePending', 
        7 => 'standbyPending', 8 => 'outOfServicePending', 9 => 'recovery',
    );

    my $oid_apSysCPUUtil = '.1.3.6.1.4.1.9148.3.2.1.1.1.0';
    my $oid_apSysMemoryUtil = '.1.3.6.1.4.1.9148.3.2.1.1.2.0';
    my $oid_apSysHealthScore = '.1.3.6.1.4.1.9148.3.2.1.1.3.0';
    my $oid_apSysRedundancy = '.1.3.6.1.4.1.9148.3.2.1.1.4.0';
    my $oid_apSysGlobalConSess = '.1.3.6.1.4.1.9148.3.2.1.1.5.0';
    my $oid_apSysGlobalCPS = '.1.3.6.1.4.1.9148.3.2.1.1.6.0';
    my $oid_apSysLicenseCapacity = '.1.3.6.1.4.1.9148.3.2.1.1.10.0';
    my $result = $options{snmp}->get_leef(oids => [
            $oid_apSysCPUUtil, $oid_apSysMemoryUtil, $oid_apSysHealthScore, $oid_apSysRedundancy,
            $oid_apSysLicenseCapacity, $oid_apSysGlobalConSess, $oid_apSysGlobalCPS
        ], 
        nothing_quit => 1);

    $self->{global} = { 
        cpu_load => $result->{$oid_apSysCPUUtil},
        memory_used => $result->{$oid_apSysMemoryUtil},
        replication_state => $mapping_redundancy{$result->{$oid_apSysRedundancy}},
        license_used => $result->{$oid_apSysLicenseCapacity},
        health_score => $result->{$oid_apSysHealthScore},
        current_sessions => $result->{$oid_apSysGlobalConSess},
        current_calls => $result->{$oid_apSysGlobalCPS},
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
