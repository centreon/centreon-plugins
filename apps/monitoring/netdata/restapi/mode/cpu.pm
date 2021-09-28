#
# Copyright 2021 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and alarm monitoring for
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

package apps::monitoring::netdata::restapi::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu_avg', type => 0, cb_prefix_output => 'prefix_cpu_avg_output' },
        { name => 'cpu_results', type => 1, cb_prefix_output => 'prefix_cpu_core_output' }
    ];

    $self->{maps_counters}->{cpu_avg} = [
        { label => 'average', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'average' }, { name => 'count' } ],
                output_template => '%.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{cpu_results} = [
        { label => 'core', nlabel => 'core.cpu.utilization.percentage', set => {
                key_values => [ { name => 'usage' }, { name => 'display' } ],
                output_template => 'usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_cpu_avg_output {
    my ($self, %options) = @_;

    return $self->{cpu_avg}->{count} . " CPU(s) average usage is ";
}

sub prefix_cpu_core_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'chart-period:s'      => { name => 'chart_period', default => '300' },
        'chart-statistics:s'  => { name => 'chart_statistics', default => 'average' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $cpu_total_usage;
    my $cpu_number = $options{custom}->get_info(filter_info => 'cores_total');
    foreach (my $i = 0; $i < $cpu_number; $i++) {
        my $cpu_core = 'cpu.cpu' . $i;
        my $result = $options{custom}->get_data(
            chart => $cpu_core,
            after_period => $self->{option_results}->{chart_period},
            group => $self->{option_results}->{chart_statistics}
        );

        my ($usage, $count) = (0, 0);
        foreach my $data (@{$result->{data}}) {
            while (my ($index, $label) = each(@{$result->{labels}})) {
                next if ($label eq 'time');

                $usage += $data->[$index];
            }
            $count++;
        }

        if ($count > 0) {
            $self->{cpu_results}->{$i} = {
                display => $i,
                usage => $usage / $count
            };

            $cpu_total_usage += ($usage / $count);
        }
    }

    my $avg_cpu = $cpu_total_usage / $cpu_number;
    $self->{cpu_avg} = {
        average => $avg_cpu,
        count => $cpu_number
    };
};

1;

__END__

=head1 MODE

Check *nix based servers CPU using the Netdata agent RestAPI.

Example:
perl centreon_plugins.pl --plugin=apps::monitoring::netdata::restapi::plugin
--mode=cpu --hostname=10.0.0.1 --chart-period=300 --warning-average=70 --critical-average=80 --verbose

More information on 'https://learn.netdata.cloud/docs/agent/web/api'.

=over 8

=item B<--chart-period>

The period in seconds on which the values are calculated
Default: 300

=item B<--chart-statistic>

The statistic calculation method used to parse the collected data.
Can be : average, sum, min, max
Default: average

=item B<--warning-average>

Warning threshold on average CPU utilization.

=item B<--critical-average>

Critical threshold on average CPU utilization.

=item B<--warning-core>

Warning threshold for each CPU core

=item B<--critical-core>

Critical threshold for each CPU core

=back

=cut
