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

package network::a10::ax::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPUs are ok' },
    ];
    
    $self->{maps_counters}->{cpu} = [
        { label => 'cpu-30s', nlabel => 'cpu.utilization.30s.percentage', set => {
                key_values => [ { name => 'cpu_30s' }, { name => 'display' } ],
                output_template => '30s : %s %%',
                perfdatas => [
                    { label => 'cpu_30s', value => 'cpu_30s',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'cpu-1m', nlabel => 'cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'cpu_1m' }, { name => 'display' } ],
                output_template => '1m : %s %%',
                perfdatas => [
                    { label => 'cpu_1m', value => 'cpu_1m',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_cpu_output {
    my ($self, %options) = @_;
    
    return "CPU '" . $options{instance_value}->{display} . "' ";
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

my $oid_axSysCpuUsageValueAtPeriod = '.1.3.6.1.4.1.22610.2.4.1.3.6.1.3';

sub manage_selection {
    my ($self, %options) = @_;
    
    my $results = $options{snmp}->get_table(oid => $oid_axSysCpuUsageValueAtPeriod,
                                            nothing_quit => 1);

    $self->{cpu} = {};
    foreach my $oid (keys %$results) {
        $oid =~ /\.(\d*?)\.\d*?$/;
        next if (defined($self->{cpu}->{$1}));
        my $instance = $1;
        
        $self->{cpu}->{$instance} = { display => $instance,
            cpu_1m => $results->{$oid_axSysCpuUsageValueAtPeriod . '.' . $instance . '.5'},
            cpu_30s => $results->{$oid_axSysCpuUsageValueAtPeriod . '.' . $instance . '.4'}
        };
    }
}

1;

__END__

=head1 MODE

Check CPU usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example : --filter-counters='^cpu-1m$'

=item B<--warning-*>

Threshold warning.
Can be: 'cpu-30s' (%), 'cpu-1m' (%).

=item B<--critical-*>

Threshold critical.
Can be: 'cpu-30s' (%), 'cpu-1m' (%).

=back

=cut
