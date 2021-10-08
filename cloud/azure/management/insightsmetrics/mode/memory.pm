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

package cloud::azure::management::insightsmetrics::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use POSIX qw(strftime);

sub computer_long_output {
    my ($self, %options) = @_;

    return "Computer '" . $options{instance_value}->{display} . "'";
}

sub prefix_memory_output {
    my ($self, %options) = @_;

    return " Memory utilization: "  ;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'computer', type => 3, cb_long_output => 'computer_long_output', indent_long_output => '    ', message_multiple => 'All computers CPUs are OK',
        group => [
                { name => 'memory', display_long => 1, cb_prefix_output => 'prefix_memory_output', type => 0, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'usage', nlabel => 'azure.insights.memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'used-prct' }, { name => 'available' }, { name => 'available-prct' }, ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%.2f', unit => 'B', min => 0, label_extra_instance => 1 }
                ]
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-computer:s' => { name => 'filter_computer' },
        'workspace-id:s'    => { name => 'workspace_id' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}


sub manage_selection {
    my ($self, %options) = @_;

    my $query = 'InsightsMetrics | where Namespace == "Memory" | summarize arg_max(TimeGenerated, *) by Tags, Name, Computer'; 
    $query .= '| where Computer == "' . $self->{option_results}->{filter_computer} . '"' if defined $self->{option_results}->{filter_computer} && $self->{option_results}->{filter_computer} ne '';

    my $results = $options{custom}->azure_get_insights_analytics(
        workspace_id => $self->{option_results}->{workspace_id},
        query => $query,
        timespan => $self->{option_results}->{timespan}
    );

    foreach my $entry (keys %{$results->{data}}) {
        $self->{computer}->{$results->{data}->{$entry}->{computer}}->{display} = $results->{data}->{$entry}->{computer};
    }

    my $decoded_tag;
    foreach my $computer (keys %{$self->{computer}}) {
        foreach my $entry (keys %{$results->{data}}) {
            $decoded_tag = $options{custom}->json_decode(content => $results->{data}->{$entry}->{tags});
            $self->{computer}->{$results->{data}->{$entry}->{computer}}->{memory}->{available} = $results->{data}->{$entry}->{value} * 1000000;
            $self->{computer}->{$results->{data}->{$entry}->{computer}}->{memory}->{total} = defined($decoded_tag->{"vm.azm.ms/memorySizeMB"}) ? $decoded_tag->{"vm.azm.ms/memorySizeMB"} * 1000000 : 0;
        }
        $self->{computer}->{$computer}->{memory}->{used} = $self->{computer}->{$computer}->{memory}->{total} -
            $self->{computer}->{$computer}->{memory}->{available};

        if (scalar(keys %{$self->{computer}->{$computer}->{memory}}) <= 0) {
            $self->{output}->add_option_msg(short_msg => "No memory found for computer " . $self->{computer}->{$computer}->{display});
            $self->{output}->option_exit();
        }
        use Data::Dumper; print Dumper($self->{computer});
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

=item B<--filter-computer>

Filter on a specific Azure "computer".

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
