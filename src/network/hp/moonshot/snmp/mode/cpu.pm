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

package network::hp::moonshot::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return 'cpu average usage: ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_cpu_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'cpu-utilization-5s', nlabel => 'cpu.utilization.5s.percentage', set => {
                key_values => [ { name => 'cpu_load5s' } ],
                output_template => '%.2f %% (5s)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'cpu-utilization-1m', nlabel => 'cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'cpu_load1m' } ],
                output_template => '%.2f %% (1m)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'cpu-utilization-15m', nlabel => 'cpu.utilization.15m.percentage', set => {
                key_values => [ { name => 'cpu_load15m' } ],
                output_template => '%.2f %% (15m)',
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

    my $oid_cpu = '.1.3.6.1.4.1.11.5.7.5.7.1.1.1.1.4.9.0'; # agentSwitchCpuProcessTotalUtilization
    my $snmp_result = $options{snmp}->get_leef(
        oids => [$oid_cpu],
        nothing_quit => 1
    );
    #"    5 Secs ( 27.1303%)   60 Secs ( 22.3437%)  300 Secs ( 17.9758%)"
    if ($snmp_result->{$oid_cpu} =~ /([0-9\.]+)%.*?([0-9\.]+)%.*?([0-9\.]+)%/) {
        $self->{global} = {
            cpu_load5s => $1,
            cpu_load1m => $2,
            cpu_load15m => $3
        };
    }
}

1;

__END__

=head1 MODE

Check cpu.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-utilization-5s', 'cpu-utilization-1m', 'cpu-utilization-15m'.

=back

=cut
