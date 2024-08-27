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

package cloud::azure::management::insightsmetrics::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub computer_long_output {
    my ($self, %options) = @_;

    return "Computer '" . $options{instance_value}->{display} . "'";
}

sub prefix_core_output {
    my ($self, %options) = @_;

    return "CPU #" . $options{instance_value}->{display} . " " ;
}

sub prefix_avg_output {
    my ($self, %options) = @_;

    return $options{instance_value}->{count} . " CPU(s) average utilization: "  ;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'computer', type => 3, cb_long_output => 'computer_long_output', indent_long_output => '    ', message_multiple => 'All computers CPUs are OK',
        group => [
                { name => 'cpu_avg', display_long => 1, cb_prefix_output => 'prefix_avg_output', type => 0, skipped_code => { -10 => 1 } },
                { name => 'cpu_core', display_long => 1, cb_prefix_output => 'prefix_core_output', message_multiple => 'All CPUs are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{cpu_avg} = [
        { label => 'average-utilization-percentage', nlabel => 'azure.insights.cpu.average.utilization.percentage', set => {
                key_values => [ { name => 'average' }, { name => 'count' } ],
                output_template => '%.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{cpu_core} = [
        { label => 'core-utilization-percentage', nlabel => 'azure.insights.cpu.core.utilization.percentage', set => {
                key_values => [ { name => 'utilizationpercentage' }, { name => 'display' } ],
                output_template => 'usage : %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-computer:s'   => { name => 'filter_computer' },
        'filter-cpu:s'        => { name => 'filter_cpu' },
        'filter-resourceid:s' => { name => 'filter_resourceid' },
        'workspace-id:s'      => { name => 'workspace_id' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}


sub manage_selection {
    my ($self, %options) = @_;

    my $query = 'InsightsMetrics | where Namespace == "Processor" | summarize arg_max(TimeGenerated, *) by Tags, Name, Computer';
    $query .= '| where Computer == "' . $self->{option_results}->{filter_computer} . '"' if defined $self->{option_results}->{filter_computer} && $self->{option_results}->{filter_computer} ne '';
    $query .= '| where _ResourceId == "' . $self->{option_results}->{filter_resourceid} . '"' if defined $self->{option_results}->{filter_resourceid} && $self->{option_results}->{filter_resourceid} ne '';

    my $results = $options{custom}->azure_get_insights_analytics(
        workspace_id => $self->{option_results}->{workspace_id},
        query => $query,
        timespan => $self->{option_results}->{timespan}
    );

    my $decoded_tag;
    foreach my $entry (keys %{$results->{data}}) {
        $decoded_tag = $options{custom}->json_decode(content => $results->{data}->{$entry}->{tags});
        next if (defined($self->{option_results}->{filter_cpu}) && $decoded_tag->{"vm.azm.ms\/totalCpus"} !~ m/$self->{option_results}->{filter_cpu}/);

        $self->{computer}->{$results->{data}->{$entry}->{computer}}->{display} = $results->{data}->{$entry}->{computer};
        $self->{computer}->{$results->{data}->{$entry}->{computer}}->{cpu_core}->{$decoded_tag->{"vm.azm.ms/totalCpus"}}->{display} = $decoded_tag->{"vm.azm.ms/totalCpus"};

    }

    foreach my $computer (keys %{$self->{computer}}) {
        my $cpu_avg;
        foreach my $cpu (keys %{$self->{computer}->{$computer}->{cpu_core}}) {
            foreach my $entry (keys %{$results->{data}}) {
                $decoded_tag = $options{custom}->json_decode(content => $results->{data}->{$entry}->{tags});
                my $cpu_id = $decoded_tag->{"vm.azm.ms/totalCpus"};
                next if ($cpu_id !~ m/$cpu/);

                $self->{computer}->{$results->{data}->{$entry}->{computer}}->{cpu_core}->{$cpu_id}->{utilizationpercentage} = $results->{data}->{$entry}->{value};
                $cpu_avg += $results->{data}->{$entry}->{value};
            }

            if (scalar(keys %{$self->{computer}->{$computer}->{cpu_core}}) <= 0) {
                $self->{output}->add_option_msg(short_msg => "No CPU found for computer " . $self->{computer}->{$computer}->{display});
                $self->{output}->option_exit();
            }
        }
        if (!defined($self->{option_results}->{filter_cpu}) || $self->{option_results}->{filter_cpu} eq '') {
            $self->{computer}->{$computer}->{cpu_avg}->{count} = scalar(keys %{$self->{computer}->{$computer}});
            $self->{computer}->{$computer}->{cpu_avg}->{average} = $cpu_avg / $self->{computer}->{$computer}->{cpu_avg}->{count};
        }
    }

    if (scalar(keys %{$self->{computer}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No computer found. Can be: filters, cache file.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Aure VM CPUs using Insights metrics.

Example:

perl centreon_plugins.pl --plugin=cloud::azure::management::insightsmetrics::plugin --custommode=api --mode=cpu
--subscription=1111 --tenant=2222 --client-id=3333 --client-secret=4444 --workspace-id=5555 --verbose

=over 8

=item B<--workspace-id>
(mandatory)
Specify the Azure Log Analytics Workspace ID.

=item B<--filter-computer>

Filter on a specific Azure "computer" name.
Example: --filter-name='azure-vm1'

=item B<--filter-resourceid>

Filter on a specific Azure "computer" based on the full resource ID.
Example: --filter-resourceid='/subscriptions/1234abcd-5678-defg-9012-3456789abcde/resourcegroups/my_resourcegroup/providers/microsoft.compute/virtualmachines/azure-vm1'

=item B<--filter-cpu>

Filter on specific CPU ID.

=item B<--warning-*>

Warning threshold where '*' can be:
'average-utilization-percentage', 'core-utilization-percentage'

=item B<--critical-*>

Critical threshold where '*' can be:
'average-utilization-percentage', 'core-utilization-percentage'

=back

=cut
