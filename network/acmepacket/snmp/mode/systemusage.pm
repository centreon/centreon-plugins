#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'health-score', set => {
                key_values => [ { name => 'health_score' } ],
                output_template => 'Health Score : %.2f %%',
                perfdatas => [
                    { label => 'health_score', value => 'health_score_absolute', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'cpu-load', set => {
                key_values => [ { name => 'cpu_load' } ],
                output_template => 'Cpu Load : %.2f %%',
                perfdatas => [
                    { label => 'cpu_load', value => 'cpu_load_absolute', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'memory-usage', set => {
                key_values => [ { name => 'memory_used' } ],
                output_template => 'Memory Used : %.2f %%',
                perfdatas => [
                    { label => 'memory_used', value => 'memory_used_absolute', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'license-usage', set => {
                key_values => [ { name => 'license_used' } ],
                output_template => 'License Used : %.2f %%',
                perfdatas => [
                    { label => 'license_used', value => 'license_used_absolute', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'current-sessions', set => {
                key_values => [ { name => 'current_sessions' } ],
                output_template => 'Current Sessions : %s',
                perfdatas => [
                    { label => 'current_sessions', value => 'current_sessions_absolute', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'current-calls', set => {
                key_values => [ { name => 'current_calls' } ],
                output_template => 'Current Calls : %s/s',
                perfdatas => [
                    { label => 'current_calls', value => 'current_calls_absolute', template => '%s',
                      unit => '/s', min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
                                                           
    my $oid_apSysCPUUtil = '.1.3.6.1.4.1.9148.3.2.1.1.1.0';
    my $oid_apSysMemoryUtil = '.1.3.6.1.4.1.9148.3.2.1.1.2.0';
    my $oid_apSysHealthScore = '.1.3.6.1.4.1.9148.3.2.1.1.3.0';
    my $oid_apSysGlobalConSess = '.1.3.6.1.4.1.9148.3.2.1.1.5.0';
    my $oid_apSysGlobalCPS = '.1.3.6.1.4.1.9148.3.2.1.1.6.0';
    my $oid_apSysLicenseCapacity = '.1.3.6.1.4.1.9148.3.2.1.1.10.0';
    my $result = $options{snmp}->get_leef(oids => [
            $oid_apSysCPUUtil, $oid_apSysMemoryUtil, $oid_apSysHealthScore,
            $oid_apSysLicenseCapacity, $oid_apSysGlobalConSess, $oid_apSysGlobalCPS
        ], 
        nothing_quit => 1);
    $self->{global} = { cpu_load => $result->{$oid_apSysCPUUtil},
        memory_used => $result->{$oid_apSysMemoryUtil},
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
