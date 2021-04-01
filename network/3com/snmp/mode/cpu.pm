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

package network::3com::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPU usages are ok' }
    ];
    $self->{maps_counters}->{cpu} = [
        { label => '5s', nlabel => 'cpu.utilization.5s.percentage', set => {
                key_values => [ { name => 'usage_5s' }, { name => 'display' } ],
                output_template => '%s %% (5sec)', output_error_template => "%s (5sec)",
                perfdatas => [
                    { label => 'cpu_5s', value => 'usage_5s', template => '%d',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => '1m', nlabel => 'cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'usage_1m' }, { name => 'display' } ],
                output_template => '%s %% (1m)', output_error_template => "%s (1min)",
                perfdatas => [
                    { label => 'cpu_1m', value => 'usage_1m', template => '%d',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => '5m', nlabel => 'cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'usage_5m' }, { name => 'display' } ],
                output_template => '%s %% (5min)', output_error_template => "%s (5min)",
                perfdatas => [
                    { label => 'cpu_5m', value => 'usage_5m', template => '%d',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_cpu_output {
    my ($self, %options) = @_;
    
    if ($self->{multiple} == 1) {
        return "CPU '" . $options{instance_value}->{display} . "' Usage "; 
    }
    return "CPU Usage ";
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

my $mapping = {
    hwCpuCostRate           => { oid => '.1.3.6.1.4.1.43.45.1.6.1.1.1.2' },
    hwCpuCostRatePer1Min    => { oid => '.1.3.6.1.4.1.43.45.1.6.1.1.1.3' },
    hwCpuCostRatePer5Min    => { oid => '.1.3.6.1.4.1.43.45.1.6.1.1.1.4' },
};

sub manage_selection {
    my ($self, %options) = @_;
    
    # a3com-huawei-splat-devm.mib
    my $oid_hwCpuEntry = '.1.3.6.1.4.1.43.45.1.6.1.1.1';
    my $results = $options{snmp}->get_table(oid => $oid_hwCpuEntry, nothing_quit => 1);
    $self->{cpu} = {};
    foreach my $oid (keys %{$results}) {
        next if ($oid !~ /^$mapping->{hwCpuCostRatePer5Min}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);
        
        $self->{cpu}->{$instance} = { display => $instance, 
                                      usage_5s => $result->{hwCpuCostRate},
                                      usage_1m => $result->{hwCpuCostRatePer1Min},
                                      usage_5m => $result->{hwCpuCostRatePer5Min},
                                    }; 
    }
    
    if (scalar(keys %{$self->{cpu}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check cpu usages.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='5m'

=item B<--warning-*>

Threshold warning.
Can be: '5s', '1m', '5m'.

=item B<--critical-*>

Threshold critical.
Can be: '5s', '1m', '5m'.

=back

=cut
