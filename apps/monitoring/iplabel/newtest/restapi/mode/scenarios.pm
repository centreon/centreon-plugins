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

package apps::monitoring::iplabel::newtest::restapi::mode::scenarios;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use POSIX;
use DateTime;

sub robot_long_output {
    my ($self, %options) = @_;

    return "checking robot '" . $options{instance_value}->{display} . "'";
}

sub prefix_robot_output {
    my ($self, %options) = @_;

    return "Robot '" . $options{instance_value}->{display} . "' ";
}


sub prefix_scenario_output {
    my ($self, %options) = @_;

    return "scenario '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'robots', type => 3, cb_prefix_output => 'prefix_robot_output', cb_long_output => 'robot_long_output', indent_long_output => '    ', message_multiple => 'All robots are ok',
            group => [
                { name => 'scenarios', display_long => 1, cb_prefix_output => 'prefix_scenario_output',  message_multiple => 'all scenarios are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{scenarios} = [
        { label => 'dummy', threshold => 0, display_ok => 0, set => {
                key_values => [ { name => 'last_exec' } ],
                output_template => 'none',
                perfdatas => []
            }
        },
        { label => 'status-green', nlabel => 'scenario.status.green.percentage', set => {
                key_values => [ { name => 'green_prct' }, { name => 'display' } ],
                output_template => 'green status: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'status-red', nlabel => 'scenario.status.red.percentage', set => {
                key_values => [ { name => 'red_prct' }, { name => 'display' } ],
                output_template => 'red status: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'status-orange', nlabel => 'scenario.status.orange.percentage', set => {
                key_values => [ { name => 'orange_prct' }, { name => 'display' } ],
                output_template => 'orange status: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'status-grey', nlabel => 'scenario.status.grey.percentage', set => {
                key_values => [ { name => 'grey_prct' }, { name => 'display' } ],
                output_template => 'grey status: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'execution-time', nlabel => 'scenario.execution.time.milliseconds', set => {
                key_values => [ { name => 'execution_time' }, { name => 'display' } ],
                output_template => 'execution time: %s ms',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'ms', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-robot-name:s'    => { name => 'filter_robot_name' },
        'filter-scenario-name:s' => { name => 'filter_scenario_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'iplabel_newtest_' . $self->{mode} . '_' . $options{custom}->get_hostname()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_robot_name}) ? md5_hex($self->{option_results}->{filter_robot_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_scenario_name}) ? md5_hex($self->{option_results}->{filter_scenario_name}) : md5_hex('all'));
    my $last_timestamp = $self->read_statefile_key(key => 'last_timestamp');
    my $timespan = 5;
    if (defined($last_timestamp)) {
        $timespan = POSIX::ceil((time() - $last_timestamp) / 60);
    } else {
        $last_timestamp = time() - (60 * 5);
    }

    my $instances = $options{custom}->request_api(endpoint => '/api/instances');
    $self->{robots} = {};
    my $scenarios_last_exec = {};
    my $query_filter = [];
    foreach (@$instances) {
        if (defined($self->{option_results}->{filter_robot_name}) && $self->{option_results}->{filter_robot_name} ne '' &&
            $_->{Robot}->{Name} !~ /$self->{option_results}->{filter_robot_name}/i) {
            $self->{output}->output_add(long_msg => "skipping scenario '" . $_->{Scenario}->{Name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_scenario_name}) && $self->{option_results}->{filter_scenario_name} ne '' &&
            $_->{Scenario}->{Name} !~ /$self->{option_results}->{filter_scenario_name}/i) {
            $self->{output}->output_add(long_msg => "skipping scenario '" . $_->{Scenario}->{Name} . "': no matching filter.", debug => 1);
            next;
        }

        if (!defined($self->{robots}->{ $_->{Robot}->{Name} })) {
            push @$query_filter, 'robot=' . $_->{Robot}->{Id};
            $self->{robots}->{ $_->{Robot}->{Name} } = {
                display => $_->{Robot}->{Name},
                scenarios => {}
            };
        }
        if (!defined($self->{robots}->{ $_->{Robot}->{Name} }->{scenarios}->{ $_->{Scenario}->{Name} })) {
            push @$query_filter, 'scenario=' . $_->{Scenario}->{Id};
            $self->{robots}->{ $_->{Robot}->{Name}}->{scenarios}->{ $_->{Scenario}->{Name} } = {
                display => $_->{Scenario}->{Name},
                red_seconds => 0,
                orange_seconds => 0,
                grey_seconds => 0,
                green_seconds => 0,
                execution_time_total => 0,
                execution_count => 0
            };
        }

        my $uuid = $_->{Robot}->{Name} . '~' . $_->{Scenario}->{Name};
        if (!defined($scenarios_last_exec->{$uuid})) {
            $scenarios_last_exec->{$uuid} = $self->read_statefile_key(key => $uuid . '_last_exec');
        }
    }

    my $query_filter_string = '';
    my $query_filter_num = scalar(@$query_filter);
    # if it's too big, we request everything
    if ($query_filter_num > 0 && $query_filter_num < 50) {
        $query_filter_string = '&' . join('&', @$query_filter);
    }
    my $results = [];
    if ($query_filter_num > 0) {
        $results = $options{custom}->request_api(endpoint => '/api/results?range=' . $timespan . $query_filter_string);
    }

    my $mapping_status = {
        completed => 'green',
        failed => 'red',
        warning => 'orange',
        available => 'green',
        suspended => 'grey',
        outofrange => 'grey',
        canceled => 'grey',
        notrunning => 'grey',
        unknown => 'grey'
    };

    # {
    #    "Id": 54411512,
    #    "ExecutionDate": "2020-06-24T15:01:39",
    #    "ExecutionDateUtc": "2020-06-24T13:01:39",
    #    "Status": "Warning",
    #    "Value": 45000,
    #    "ExclusionState": "None",
    #    "Measure": {
    #      "Id": 9,
    #      "Name": "Sugar"
    #    },
    #    "Robot": {
    #      "Id": 12,
    #      "Name": "STOCKHOLM"
    #    },
    #    "ErrorMessage": ""
    #}

    my $i = scalar(@$results) - 1;
    for (; $i >= 0; $i--) {
        next if (!defined($self->{robots}->{ $results->[$i]->{Robot}->{Name} }) || !defined($self->{robots}->{ $results->[$i]->{Robot}->{Name} }->{scenarios}->{ $results->[$i]->{Measure}->{Name} }));

        next if ($results->[$i]->{ExecutionDateUtc} !~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)$/);
        my $exec_time = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6, time_zone => 'UTC');
        my $exec_epoch = $exec_time->epoch();

        my $uuid = $results->[$i]->{Robot}->{Name} . '~' . $results->[$i]->{Measure}->{Name};
        if (!defined($scenarios_last_exec->{$uuid})) {
            $scenarios_last_exec->{$uuid} = { time => $last_timestamp, status => lc($results->[$i]->{Status}) };
            $self->{robots}->{ $results->[$i]->{Robot}->{Name} }->{scenarios}->{ $results->[$i]->{Measure}->{Name} }->{execution_time_total} += $results->[$i]->{Value};
            $self->{robots}->{ $results->[$i]->{Robot}->{Name} }->{scenarios}->{ $results->[$i]->{Measure}->{Name} }->{execution_count}++;
            next;
        }

        next if ($exec_epoch < $last_timestamp);

        $self->{robots}->{ $results->[$i]->{Robot}->{Name} }->{scenarios}->{ $results->[$i]->{Measure}->{Name} }->{ $mapping_status->{ $scenarios_last_exec->{$uuid}->{status} } . '_seconds' } += $exec_epoch - $scenarios_last_exec->{$uuid}->{time};
        $self->{robots}->{ $results->[$i]->{Robot}->{Name} }->{scenarios}->{ $results->[$i]->{Measure}->{Name} }->{execution_time_total} += $results->[$i]->{Value};
        $self->{robots}->{ $results->[$i]->{Robot}->{Name} }->{scenarios}->{ $results->[$i]->{Measure}->{Name} }->{execution_count}++;

        $scenarios_last_exec->{$uuid}->{time} = $exec_epoch;
        $scenarios_last_exec->{$uuid}->{status} = lc($results->[$i]->{Status});
    }

    my $current_timestamp = time();
    # we add current timestamp gap
    foreach my $robot_name (keys %{$self->{robots}}) {
        foreach my $scenario_name (keys %{$self->{robots}->{$robot_name}->{scenarios}}) {
            my $uuid = $robot_name . '~' . $scenario_name;
            next if (!defined($scenarios_last_exec->{$uuid}->{time}));

            $self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{ $mapping_status->{ $scenarios_last_exec->{$uuid}->{status} } . '_seconds' } += $current_timestamp - $scenarios_last_exec->{$uuid}->{time};
            $self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{last_exec} = $scenarios_last_exec->{$uuid};

            if ($self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{execution_count} > 0) {
                $self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{execution_time} =
                    int($self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{execution_time_total} /
                        $self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{execution_count});
                $self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{last_exec}->{execution_time} = $self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{execution_time};
            } elsif (defined($scenarios_last_exec->{$uuid}->{execution_time})) {
                $self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{execution_time} = $scenarios_last_exec->{$uuid}->{execution_time};
                $self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{last_exec}->{execution_time} = $scenarios_last_exec->{$uuid}->{execution_time};
            }

            my $total_time = $self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{green_seconds} +
                $self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{red_seconds} +
                $self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{orange_seconds} +
                $self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{grey_seconds};
            $self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{green_prct} =
               $self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{green_seconds} * 100 / $total_time;
            $self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{red_prct} =
               $self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{red_seconds} * 100 / $total_time;
            $self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{orange_prct} =
               $self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{orange_seconds} * 100 / $total_time;
            $self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{grey_prct} =
               $self->{robots}->{ $robot_name }->{scenarios}->{ $scenario_name }->{grey_seconds} * 100 / $total_time;
        }
    }
}

1;

__END__

=head1 MODE

Check scenarios.

=over 8

=item B<--filter-node-id>

Filter nodes (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'ping-received-lasttime' (s).

=back

=cut
