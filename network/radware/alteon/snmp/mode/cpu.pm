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

package network::radware::alteon::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_cpu_output' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => '1s', set => {
                key_values => [ { name => '1s' } ],
                output_template => '%.2f%% (1sec)',
                perfdatas => [
                    { label => 'cpu_1s', value => '1s_absolute', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => '4s', set => {
                key_values => [ { name => '4s' } ],
                output_template => '%.2f%% (4sec)',
                perfdatas => [
                    { label => 'cpu_4s', value => '4s_absolute', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => '64s', set => {
                key_values => [ { name => '64s' } ],
                output_template => '%.2f%% (64sec)',
                perfdatas => [
                    { label => 'cpu_64s', value => '64s_absolute', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
}

sub prefix_cpu_output {
    my ($self, %options) = @_;
    
    return "MP CPU Usage: ";
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

    my $oid_mpCpuStatsUtil1Second = '.1.3.6.1.4.1.1872.2.5.1.2.2.1.0';
    my $oid_mpCpuStatsUtil4Seconds = '.1.3.6.1.4.1.1872.2.5.1.2.2.2.0';
    my $oid_mpCpuStatsUtil64Seconds = '.1.3.6.1.4.1.1872.2.5.1.2.2.3.0';
    my $snmp_result = $options{snmp}->get_leef(oids => [
        $oid_mpCpuStatsUtil1Second, $oid_mpCpuStatsUtil4Seconds,
        $oid_mpCpuStatsUtil64Seconds], nothing_quit => 1);

    $self->{global} = { '1s' => $snmp_result->{$oid_mpCpuStatsUtil1Second}, '4s' => $snmp_result->{$oid_mpCpuStatsUtil4Seconds},
        '64s' => $snmp_result->{$oid_mpCpuStatsUtil64Seconds} };
}

1;

__END__

=head1 MODE

Check MP cpu usage (ALTEON-CHEETAH-SWITCH-MIB).

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^(64s)$'

=item B<--warning-*>

Threshold warning.
Can be: '1s', '4s', '64s'.

=item B<--critical-*>

Threshold critical.
Can be: '1s', '4s', '64s'.

=back

=cut
    