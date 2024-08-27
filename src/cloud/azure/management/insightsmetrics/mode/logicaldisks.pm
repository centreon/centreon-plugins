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

package cloud::azure::management::insightsmetrics::mode::logicaldisks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use JSON::XS;


sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{diskSize});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{UsedSpace});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{FreeSpace});
    return sprintf(
        'total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{UsedSpacePercentage},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{FreeSpacePercentage}
    );
}

sub computer_long_output {
    my ($self, %options) = @_;

    return "Computer '" . $options{instance_value}->{display} . "'";
}

sub prefix_logicaldisk_output {
    my ($self, %options) = @_;

    return "'" . $options{instance_value}->{display} . "' " ;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'computer', type => 3, cb_long_output => 'computer_long_output', indent_long_output => '    ', message_multiple => 'All computers disks are OK',
        group => [
                { name => 'logicaldisk', display_long => 1, cb_prefix_output => 'prefix_logicaldisk_output',  message_multiple => 'All logical disks are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{logicaldisk} = [
        { label => 'status', type => 2, critical_default => '%{status} eq "NOT OK"', set => {
                key_values => [ { name => 'Status' }, { name => 'display' } ],
                output_template => "status : %s",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'usage', nlabel => 'azure.insights.logicaldisk.used.bytes', set => {
                key_values      => [ { name => 'UsedSpace' }, { name => 'UsedSpacePercentage' }, { name => 'FreeSpacePercentage' }, { name => 'FreeSpace' }, { name => 'diskSize'} ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%.2f', unit => 'B', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-percentage', display_ok => 0, nlabel => 'azure.insights.logicaldisk.used.percentage', set => {
                key_values      => [ { name => 'UsedSpacePercentage' } ],
                output_template => "used : %.2f%%",
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'free-percentage', display_ok => 0, nlabel => 'azure.insights.logicaldisk.free.percentage', set => {
                key_values      => [ { name => 'FreeSpacePercentage' } ],
                output_template => "free : %.2f%%",
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'reads-persecond', nlabel => 'azure.insights.logicaldisks.io.readspersecond', set => {
                key_values      => [ { name => 'ReadsPerSecond' }  ],
                output_template => "reads per second : %.2f/s",
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'read-bytes-persecond', nlabel => 'azure.insights.logicaldisks.io.readbytespersecond', set => {
                key_values      => [ { name => 'ReadBytesPerSecond' }  ],
                output_change_bytes => 1,
                output_template => "read bytes per second : %.2f/s",
                perfdatas       => [
                    { template => '%.2f', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'writes-persecond', nlabel => 'azure.insights.logicaldisks.io.writespersecond', set => {
                key_values      => [ { name => 'WritesPerSecond' }  ],
                output_template => "write per second : %.2f/s",
                perfdatas       => [
                    { template => '%.2f', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write-bytes-persecond', nlabel => 'azure.insights.logicaldisks.io.writebytespersecond', set => {
                key_values      => [ { name => 'WriteBytesPerSecond' }  ],
                output_change_bytes => 1,
                output_template => "write bytes per second : %.2f/s",
                perfdatas       => [
                    { template => '%.2f', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'transfers-persecond', nlabel => 'azure.insights.logicaldisks.io.transferspersecond', set => {
                key_values      => [ { name => 'TransfersPerSecond' }  ],
                output_template => "transfers per second : %.2f/s",
                perfdatas       => [
                    { template => '%.2f', min => 0, label_extra_instance => 1 }
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
        'filter-computer:s'   => { name => 'filter_computer' },
        'filter-disk:s'       => { name => 'filter_disk' },
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

    my $query = 'InsightsMetrics | where Namespace == "LogicalDisk" | summarize arg_max(TimeGenerated, *) by Tags, Name, Computer';
    $query .= '| where Computer == "' . $self->{option_results}->{filter_computer} . '"' if defined $self->{option_results}->{filter_computer} && $self->{option_results}->{filter_computer} ne '';
    $query .= '| where _ResourceId == "' . $self->{option_results}->{filter_resourceid} . '"' if defined $self->{option_results}->{filter_resourceid} && $self->{option_results}->{filter_resourceid} ne '';

    my $results = $options{custom}->azure_get_insights_analytics(
        workspace_id => $self->{option_results}->{workspace_id},
        query => $query,
        timespan => $self->{option_results}->{timespan}
    );

    my $status_mapping = {
        0 => 'NOT OK',
        1 => 'OK'
    };

    my $decoded_tag;
    foreach my $entry (keys %{$results->{data}}) {
        $decoded_tag = $options{custom}->json_decode(content => $results->{data}->{$entry}->{tags});
        next if (defined($self->{option_results}->{filter_disk}) && $decoded_tag->{"vm.azm.ms\/mountId"} !~ m/$self->{option_results}->{filter_disk}/);

        if ($results->{data}->{$entry}->{tags} =~ m/\{"vm\.azm\.ms\/mountId":"(.*)"\}/) {
            $self->{computer}->{$results->{data}->{$entry}->{computer}}->{logicaldisk}->{$decoded_tag->{"vm.azm.ms/mountId"}}->{display} = $decoded_tag->{"vm.azm.ms/mountId"};
        }
        $self->{computer}->{$results->{data}->{$entry}->{computer}}->{display} = $results->{data}->{$entry}->{computer};
    }

    foreach my $computer (keys %{$self->{computer}}) {
        foreach my $disk (keys %{$self->{computer}->{$computer}->{logicaldisk}}) {
            foreach my $entry (keys %{$results->{data}}) {
                $decoded_tag = $options{custom}->json_decode(content => $results->{data}->{$entry}->{tags});
                my $mountid = $decoded_tag->{"vm.azm.ms/mountId"};
                next if ($mountid !~ m/$disk/);
                next if (defined($self->{option_results}->{filter_disk}) && $decoded_tag->{"vm.azm.ms\/mountId"} !~ m/$self->{option_results}->{filter_disk}/);

                if ($results->{data}->{$entry}->{name} =~ m/(.*Space)MB/) {
                    $self->{computer}->{$results->{data}->{$entry}->{computer}}->{logicaldisk}->{$mountid}->{$1} = $results->{data}->{$entry}->{value} * 1000000;
                } else {
                    $self->{computer}->{$results->{data}->{$entry}->{computer}}->{logicaldisk}->{$mountid}->{$results->{data}->{$entry}->{name}} = $results->{data}->{$entry}->{value};
                }
                if ($results->{data}->{$entry}->{name} =~ 'Status') {
                    $self->{computer}->{$results->{data}->{$entry}->{computer}}->{logicaldisk}->{$mountid}->{$results->{data}->{$entry}->{name}} = $status_mapping->{$results->{data}->{$entry}->{value}};
                }

                if (defined($decoded_tag->{"vm.azm.ms/diskSizeMB"})) {
                    $self->{computer}->{$results->{data}->{$entry}->{computer}}->{logicaldisk}->{$mountid}->{diskSize} = $decoded_tag->{"vm.azm.ms/diskSizeMB"} * 1000000;
                }
            }
            $self->{computer}->{$computer}->{logicaldisk}->{$disk}->{UsedSpace} = $self->{computer}->{$computer}->{logicaldisk}->{$disk}->{diskSize} - $self->{computer}->{$computer}->{logicaldisk}->{$disk}->{FreeSpace};
            $self->{computer}->{$computer}->{logicaldisk}->{$disk}->{UsedSpacePercentage} = 100 - $self->{computer}->{$computer}->{logicaldisk}->{$disk}->{FreeSpacePercentage};

            if (scalar(keys %{$self->{computer}->{$computer}->{logicaldisk}}) <= 0) {
                $self->{output}->add_option_msg(short_msg => "No logical disk found for computer " . $self->{computer}->{$computer}->{display});
                $self->{output}->option_exit();
            }
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

Check Aure VM logical disks using Insights metrics.

Example:

perl centreon_plugins.pl --plugin=cloud::azure::management::insightsmetrics::plugin --custommode=api --mode=logical-disks
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

=item B<--filter-disk>

Filter on specific logical(s) disk(s).

=item B<--warning-status>

Warning threshold on logical disk status (default: none).

=item B<--critical-status>

Critical threshold on logical disk status (default: '%{status} eq "NOT OK"').

=item B<--warning-*>

Warning threshold where '*' can be:
'usage', 'usage-percentage', 'free-percentage', 'reads-persecond', 'read-bytes-persecond', 'writes-persecond', 'write-bytes-persecond', 'transfers-persecond'

=item B<--critical-*>

Critical threshold where '*' can be:
'usage', 'usage-percentage', 'free-percentage', 'reads-persecond', 'read-bytes-persecond', 'writes-persecond', 'write-bytes-persecond', 'transfers-persecond'

=back

=cut
