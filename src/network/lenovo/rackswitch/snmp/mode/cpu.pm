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

package network::lenovo::rackswitch::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use network::lenovo::rackswitch::snmp::mode::resources;

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return 'mp cpu average usage: ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_cpu_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'cpu-utilization-5s', nlabel => 'cpu.utilization.5s.percentage', set => {
                key_values => [ { name => 'cpu5s' } ],
                output_template => '%.2f %% (5s)',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ]
            }
        },
        { label => 'cpu-utilization-1m', nlabel => 'cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'cpu1m' } ],
                output_template => '%.2f %% (1m)',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ]
            }
        },
        { label => 'cpu-utilization-5m', nlabel => 'cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'cpu5m' } ],
                output_template => '%.2f %% (5m)',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $branch = network::lenovo::rackswitch::snmp::mode::resources::find_rackswitch_branch(
        output => $self->{output}, snmp => $options{snmp}
    );
    my $oid_cpu5s = $branch . '.1.2.2.8.0'; # mpCpuStatsUtil5SecondsRev
    my $oid_cpu1m = $branch . '.1.2.2.9.0'; # mpCpuStatsUtil1MinuteRev
    my $oid_cpu5m = $branch . '.1.2.2.10.0'; # mpCpuStatsUtil5MinutesRev
    my $snmp_result = $options{snmp}->get_leef(
        oids => [$oid_cpu5s, $oid_cpu1m, $oid_cpu5m],
        nothing_quit => 1
    );

    $self->{global} = {
        cpu5s => $snmp_result->{$oid_cpu5s},
        cpu1m => $snmp_result->{$oid_cpu1m},
        cpu5m => $snmp_result->{$oid_cpu5m}
    };
}

1;

__END__

=head1 MODE

Check management processor cpu.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-utilization-5s', 'cpu-utilization-1m', 'cpu-utilization-5m'.

=back

=cut
