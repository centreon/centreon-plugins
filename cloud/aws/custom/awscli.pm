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

package cloud::aws::custom::awscli;

use strict;
use warnings;
use DateTime;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'aws-secret-key:s'    => { name => 'aws_secret_key' },
            'aws-access-key:s'    => { name => 'aws_access_key' },
            'aws-session-token:s' => { name => 'aws_session_token' },
            'aws-profile:s'       => { name => 'aws_profile' },
            'endpoint-url:s'      => { name => 'endpoint_url' },
            'region:s'            => { name => 'region' },
            'timeframe:s'         => { name => 'timeframe' },
            'period:s'            => { name => 'period' },
            'statistic:s@'        => { name => 'statistic' },
            'zeroed'              => { name => 'zeroed' },
            'timeout:s'           => { name => 'timeout', default => 50 },
            'sudo'                => { name => 'sudo' },
            'command:s'           => { name => 'command', default => 'aws' },
            'command-path:s'      => { name => 'command_path' },
            'command-options:s'   => { name => 'command_options', default => '' },
            'proxyurl:s'          => { name => 'proxyurl' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'AWSCLI OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{custommode_name} = $options{custommode_name};

    return $self;
}

sub get_region {
    my ($self, %options) = @_;

    return $self->{option_results}->{region};
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {
    my ($self, %options) = @_;

    foreach (keys %{$options{default}}) {
        if ($_ eq $self->{custommode_name}) {
            if (ref($options{default}->{$_}) eq 'ARRAY') {
                for (my $i = 0; $i < scalar(@{$options{default}->{$_}}); $i++) {
                    foreach my $opt (keys %{$options{default}->{$_}[$i]}) {
                        if (!defined($self->{option_results}->{$opt}[$i])) {
                            $self->{option_results}->{$opt}[$i] = $options{default}->{$_}[$i]->{$opt};
                        }
                    }
                }
            }
            
            if (ref($options{default}->{$_}) eq 'HASH') {
                foreach my $opt (keys %{$options{default}->{$_}}) {
                    if (!defined($self->{option_results}->{$opt})) {
                        $self->{option_results}->{$opt} = $options{default}->{$_}->{$opt};
                    }
                }
            }
        }
    }  
}

sub check_options {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{proxyurl}) && $self->{option_results}->{proxyurl} ne '') {
        $ENV{HTTP_PROXY} = $self->{option_results}->{proxyurl};
        $ENV{HTTPS_PROXY} = $self->{option_results}->{proxyurl};
    }

    if (defined($self->{option_results}->{aws_secret_key}) && $self->{option_results}->{aws_secret_key} ne '') {
        $ENV{AWS_SECRET_ACCESS_KEY} = $self->{option_results}->{aws_secret_key};
    }
    if (defined($self->{option_results}->{aws_access_key}) && $self->{option_results}->{aws_access_key} ne '') {
        $ENV{AWS_ACCESS_KEY_ID} = $self->{option_results}->{aws_access_key};
    }
    if (defined($self->{option_results}->{aws_session_token}) && $self->{option_results}->{aws_session_token} ne '') {
        $ENV{AWS_SESSION_TOKEN} = $self->{option_results}->{aws_session_token};
    }
    if (defined($self->{option_results}->{aws_profile}) && $self->{option_results}->{aws_profile} ne '') {
        $ENV{AWS_PROFILE} = $self->{option_results}->{aws_profile};
    }

    if (!defined($self->{option_results}->{region}) || $self->{option_results}->{region} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --region option.");
        $self->{output}->option_exit();
    }

    if (defined($self->{option_results}->{statistic})) {
        foreach my $statistic (@{$self->{option_results}->{statistic}}) {
            if ($statistic !~ /minimum|maximum|average|sum/) {
                $self->{output}->add_option_msg(short_msg => "Statistic '" . $statistic . "' is not handled");
                $self->{output}->option_exit();
            }
        }
    }

    $self->{endpoint_url} = (defined($self->{option_results}->{endpoint_url})) ? $self->{option_results}->{endpoint_url} : undef;

    return 0;
}

sub execute {
    my ($self, %options) = @_;

    my $cmd_options = $options{cmd_options};
    $cmd_options .= " --debug" if ($self->{output}->is_debug());

    $self->{output}->output_add(long_msg => "Command line: '" . $self->{option_results}->{command} . " " . $cmd_options . "'", debug => 1);

    my ($response) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $cmd_options,
        redirect_stderr => ($self->{output}->is_debug()) ? 0 : 1
    );

    my $raw_results;

    eval {
        $raw_results = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $response, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    return $raw_results;
}

sub cloudwatch_get_metrics_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "cloudwatch get-metric-statistics --region $self->{option_results}->{region} --namespace $options{namespace}" . 
        " --metric-name '$options{metric_name}' --start-time $options{start_time} --end-time $options{end_time}" . 
        " --period $options{period} --statistics " . join(' ', @{$options{statistics}}) . " --output json --dimensions";
    foreach my $entry (@{$options{dimensions}}) {
        $cmd_options .= " 'Name=$entry->{Name},Value=$entry->{Value}'";
    }
    $cmd_options .= " --endpoint-url $self->{endpoint_url}" if (defined($self->{endpoint_url}) && $self->{endpoint_url} ne '');

    return $cmd_options;
}

sub cloudwatch_get_metrics {
    my ($self, %options) = @_;

    my $metric_results = {};
    my $start_time = DateTime->now->subtract(seconds => $options{timeframe})->iso8601;
    my $end_time = DateTime->now->iso8601;

    foreach my $metric_name (@{$options{metrics}}) {
        my $cmd_options = $self->cloudwatch_get_metrics_set_cmd(%options, metric_name => $metric_name,
            start_time => $start_time, end_time => $end_time);
        my $raw_results = $self->execute(cmd_options => $cmd_options);

        $metric_results->{$raw_results->{Label}} = { points => 0 };
        foreach my $point (@{$raw_results->{Datapoints}}) {
            if (defined($point->{Average})) {
                $metric_results->{$raw_results->{Label}}->{average} = 0 if (!defined($metric_results->{$raw_results->{Label}}->{average}));
                $metric_results->{$raw_results->{Label}}->{average} += $point->{Average};
            }
            if (defined($point->{Minimum})) {
                $metric_results->{$raw_results->{Label}}->{minimum} = $point->{Minimum}
                    if (!defined($metric_results->{$raw_results->{Label}}->{minimum}) || $point->{Minimum} < $metric_results->{$raw_results->{Label}}->{minimum});
            }
            if (defined($point->{Maximum})) {
                $metric_results->{$raw_results->{Label}}->{maximum} = $point->{Maximum}
                    if (!defined($metric_results->{$raw_results->{Label}}->{maximum}) || $point->{Maximum} > $metric_results->{$raw_results->{Label}}->{maximum});
            }
            if (defined($point->{Sum})) {
                $metric_results->{$raw_results->{Label}}->{sum} = 0 if (!defined($metric_results->{$raw_results->{Label}}->{sum}));
                $metric_results->{$raw_results->{Label}}->{sum} += $point->{Sum};
            }

            $metric_results->{$raw_results->{Label}}->{points}++;
        }

        if (defined($metric_results->{$raw_results->{Label}}->{average})) {
            $metric_results->{$raw_results->{Label}}->{average} /= $metric_results->{$raw_results->{Label}}->{points};
        }
    }

    return $metric_results;
}

sub discovery_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = $options{service} . " " . $options{command} . " --region $self->{option_results}->{region} --output json";
    $cmd_options .= " --endpoint-url $self->{endpoint_url}" if (defined($self->{endpoint_url}) && $self->{endpoint_url} ne '');

    return $cmd_options;
}

sub discovery {
    my ($self, %options) = @_;

    my $cmd_options = $self->discovery_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results;
}

sub cloudwatch_get_alarms_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "cloudwatch describe-alarms --region $self->{option_results}->{region} --output json";
    $cmd_options .= " --endpoint-url $self->{endpoint_url}" if (defined($self->{endpoint_url}) && $self->{endpoint_url} ne '');

    return $cmd_options;
}

sub cloudwatch_get_alarms {
    my ($self, %options) = @_;

    my $cmd_options = $self->cloudwatch_get_alarms_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    my $alarm_results = [];
    foreach my $alarm (@{$raw_results->{MetricAlarms}}) {
        push @$alarm_results, {
            AlarmName => $alarm->{AlarmName},
            StateValue => $alarm->{StateValue},
            MetricName => $alarm->{MetricName},
            StateReason => $alarm->{StateReason},
            StateUpdatedTimestamp => $alarm->{StateUpdatedTimestamp},
        };
    }

    return $alarm_results;
}

sub cloudwatch_list_metrics_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "cloudwatch list-metrics --region $self->{option_results}->{region} --output json";
    $cmd_options .= " --namespace $options{namespace}" if (defined($options{namespace}));
    $cmd_options .= " --metric-name $options{metric}" if (defined($options{metric}));
    $cmd_options .= " --endpoint-url $self->{endpoint_url}" if (defined($self->{endpoint_url}) && $self->{endpoint_url} ne '');

    return $cmd_options;
}

sub cloudwatch_list_metrics {
    my ($self, %options) = @_;

    my $cmd_options = $self->cloudwatch_list_metrics_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results->{Metrics};
}

sub cloudwatchlogs_describe_log_groups_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "logs describe-log-groups --region $self->{option_results}->{region} --output json";
    $cmd_options .= " --endpoint-url $self->{endpoint_url}" if (defined($self->{endpoint_url}) && $self->{endpoint_url} ne '');

    return $cmd_options;
}

sub cloudwatchlogs_describe_log_groups {
    my ($self, %options) = @_;

    my $cmd_options = $self->cloudwatchlogs_describe_log_groups_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results->{logGroups};
}

sub cloudwatchlogs_filter_log_events_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "logs filter-log-events --region $self->{option_results}->{region} --output json --log-group-name '$options{group_name}'";
    $cmd_options .= " --start-time $options{start_time}" if (defined($options{start_time}));
    if (defined($options{stream_names})) {
        $cmd_options .= " --log-stream-names";
        foreach (@{$options{stream_names}}) {
            $cmd_options .= " '$_'";
        }
    }
    $cmd_options .= " --endpoint-url $self->{endpoint_url}" if (defined($self->{endpoint_url}) && $self->{endpoint_url} ne '');

    return $cmd_options;
}

sub cloudwatchlogs_filter_log_events {
    my ($self, %options) = @_;

    my $cmd_options = $self->cloudwatchlogs_filter_log_events_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results->{events};
}

sub ebs_list_volumes_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "ec2 describe-volumes --no-dry-run --region $self->{option_results}->{region} --output json";
    $cmd_options .= " --endpoint-url $self->{endpoint_url}" if (defined($self->{endpoint_url}) && $self->{endpoint_url} ne '');

    return $cmd_options;
}

sub ebs_list_volumes {
    my ($self, %options) = @_;

    my $cmd_options = $self->ebs_list_volumes_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    my $resource_results = [];
    foreach my $volume_request (@{$raw_results->{Volumes}}) {
        my @name_tags;
            foreach my $tag (@{$volume_request->{Tags}}) {
                if ($tag->{Key} eq "Name" && defined($tag->{Value})) {
                    push @name_tags, $tag->{Value};
                }
            };
        push @{$resource_results}, {
            VolumeId       => $volume_request->{VolumeId},
            VolumeName     => join(",", @name_tags),
            VolumeType     => $volume_request->{VolumeType},
            VolumeState    => $volume_request->{State}
        };
    }

    return $resource_results;
}

sub ec2_get_instances_status_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "ec2 describe-instance-status --include-all-instances --no-dry-run --region $self->{option_results}->{region} --output json";
    $cmd_options .= " --endpoint-url $self->{endpoint_url}" if (defined($self->{endpoint_url}) && $self->{endpoint_url} ne '');

    return $cmd_options;
}

sub ec2_get_instances_status {
    my ($self, %options) = @_;

    my $cmd_options = $self->ec2_get_instances_status_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    my $instance_results = {};
    foreach (@{$raw_results->{InstanceStatuses}}) {
        $instance_results->{$_->{InstanceId}} = {
            state => $_->{InstanceState}->{Name},
            status => => $_->{InstanceStatus}->{Status}
        };
    }

    return $instance_results;
}

sub ec2spot_get_active_instances_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "ec2 describe-spot-fleet-instances --no-dry-run --region $self->{option_results}->{region} --output json";
    $cmd_options .= " --endpoint-url $self->{endpoint_url}" if (defined($self->{endpoint_url}) && $self->{endpoint_url} ne '');
    $cmd_options .= " --spot-fleet-request-id " . $options{spot_fleet_request_id};

    return $cmd_options;
}

sub ec2spot_get_active_instances_status {
    my ($self, %options) = @_;

    my $cmd_options = $self->ec2spot_get_active_instances_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    my $instance_results = {};
    foreach (@{$raw_results->{ActiveInstances}}) {
        $instance_results->{$_->{InstanceId}} = {
            health      => $_->{InstanceHealth},
            type        => $_->{InstanceType},
            request_id  => $_->{SpotInstanceRequestId}
        };
    }

    return $instance_results;
}

sub ec2spot_list_fleet_requests_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "ec2 describe-spot-fleet-requests --no-dry-run --region $self->{option_results}->{region} --output json";
    $cmd_options .= " --endpoint-url $self->{endpoint_url}" if (defined($self->{endpoint_url}) && $self->{endpoint_url} ne '');

    return $cmd_options;
}

sub ec2spot_list_fleet_requests {
    my ($self, %options) = @_;

    my $cmd_options = $self->ec2spot_list_fleet_requests_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    my $resource_results = [];
    foreach my $fleet_request (@{$raw_results->{SpotFleetRequestConfigs}}) {
        push @{$resource_results}, {
            SpotFleetRequestState => $fleet_request->{SpotFleetRequestState},
            SpotFleetRequestId    => $fleet_request->{SpotFleetRequestId},
            ActivityStatus        => $fleet_request->{ActivityStatus}
        };
    }

    return $resource_results;
}

sub ec2_list_resources_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "ec2 describe-instances --no-dry-run --region $self->{option_results}->{region} --output json";
    $cmd_options .= " --endpoint-url $self->{endpoint_url}" if (defined($self->{endpoint_url}) && $self->{endpoint_url} ne '');

    return $cmd_options;
}

sub ec2_list_resources {
    my ($self, %options) = @_;

    my $cmd_options = $self->ec2_list_resources_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    my $resource_results = [];
    foreach my $reservation (@{$raw_results->{Reservations}}) {
        foreach my $instance (@{$reservation->{Instances}}) {
            my @instance_tags;
            foreach my $tag (@{$instance->{Tags}}) {
                my %already = map { $_->{Name} => $_ } @{$resource_results};
                if ($tag->{Key} eq "aws:autoscaling:groupName") {
                    next if (defined($already{$tag->{Value}}));
                    push @{$resource_results}, {
                        Name => $tag->{Value},
                        Type => 'asg',
                    };
                } elsif ($tag->{Key} eq "Name" && defined($tag->{Value})) {
                    push @instance_tags, $tag->{Value};
                }
            }
            push @{$resource_results}, {
                Name => $instance->{InstanceId},
                Type => 'instance',
                AvailabilityZone => $instance->{Placement}->{AvailabilityZone},
                InstanceType => $instance->{InstanceType},
                State => $instance->{State}->{Name},
                Tags => join(",", @instance_tags),
                KeyName => $instance->{KeyName},
            };
        }
    }

    return $resource_results;
}

sub asg_get_resources_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "autoscaling describe-auto-scaling-groups --region $self->{option_results}->{region} --output json";
    $cmd_options .= " --endpoint-url $self->{endpoint_url}" if (defined($self->{endpoint_url}) && $self->{endpoint_url} ne '');

    return $cmd_options;
}

sub asg_get_resources {
    my ($self, %options) = @_;

    my $cmd_options = $self->asg_get_resources_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return \@{$raw_results->{AutoScalingGroups}};
}

sub rds_get_instances_status_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "rds describe-db-instances --region $self->{option_results}->{region} --output json";
    $cmd_options .= " --endpoint-url $self->{endpoint_url}" if (defined($self->{endpoint_url}) && $self->{endpoint_url} ne '');

    return $cmd_options;
}

sub rds_get_instances_status {
    my ($self, %options) = @_;

    my $cmd_options = $self->rds_get_instances_status_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    my $instance_results = {};
    foreach (@{$raw_results->{DBInstances}}) {
        $instance_results->{$_->{DBInstanceIdentifier}} = { state => $_->{DBInstanceStatus} };
    }

    return $instance_results;
}

sub rds_list_instances_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "rds describe-db-instances --region $self->{option_results}->{region} --output json";
    $cmd_options .= " --endpoint-url $self->{endpoint_url}" if (defined($self->{endpoint_url}) && $self->{endpoint_url} ne '');

    return $cmd_options;
}

sub rds_list_instances {
    my ($self, %options) = @_;

    my $cmd_options = $self->rds_list_instances_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    my $instance_results = [];
    foreach my $instance (@{$raw_results->{DBInstances}}) {
        push @{$instance_results}, {
            Name => $instance->{DBInstanceIdentifier},
            AvailabilityZone => $instance->{AvailabilityZone},
            Engine => $instance->{Engine},
            StorageType => $instance->{StorageType},
            DBInstanceStatus => $instance->{DBInstanceStatus},
            AllocatedStorage => $instance->{AllocatedStorage}
        };
    }

    return $instance_results;
}

sub rds_list_clusters_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "rds describe-db-clusters --region $self->{option_results}->{region} --output json";
    $cmd_options .= " --endpoint-url $self->{endpoint_url}" if (defined($self->{endpoint_url}) && $self->{endpoint_url} ne '');

    return $cmd_options;
}

sub rds_list_clusters {
    my ($self, %options) = @_;

    my $cmd_options = $self->rds_list_clusters_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    my $cluster_results = [];
    foreach my $cluster (@{$raw_results->{DBClusters}}) {
        push @{$cluster_results}, {
            Name => $cluster->{DBClusterIdentifier},
            DatabaseName => $cluster->{DatabaseName},
            Engine => $cluster->{Engine},
            Status => $cluster->{Status},
            AllocatedStorage => $cluster->{AllocatedStorage}
        };
    }

    return $cluster_results;
}

sub vpn_list_connections_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "ec2 describe-vpn-connections --region $self->{option_results}->{region} --output json";
    $cmd_options .= " --endpoint-url $self->{endpoint_url}" if (defined($self->{endpoint_url}) && $self->{endpoint_url} ne '');

    return $cmd_options;
}

sub vpn_list_connections {
    my ($self, %options) = @_;

    my $cmd_options = $self->vpn_list_connections_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    my $connections_results = [];
    foreach my $connection (@{$raw_results->{VpnConnections}}) {
        my @name_tags;
            foreach my $tag (@{$connection->{Tags}}) {
                if ($tag->{Key} eq "Name" && defined($tag->{Value})) {
                    push @name_tags, $tag->{Value};
                }
            }
        push @{$connections_results}, {
            id      => $connection->{VpnConnectionId},
            name    => join(",", @name_tags),
            state   => $connection->{State}
        }
    };
    return $connections_results;
}

sub health_describe_events_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "health describe-events --region $self->{option_results}->{region} --output json";

    my ($filter, $filter_append) = ('', '');
    foreach ((['service', 'services'], ['region', 'regions'], ['entity_value', 'entityValues'], ['event_status', 'eventStatusCodes'], ['event_category', 'eventTypeCategories'])) {
        next if (!defined($options{ 'filter_' . $_->[0] }));

        $filter .= $filter_append . $_->[1] . '=' . join(',', @{$options{ 'filter_' . $_->[0] }});
        $filter_append = ',';
    }

    $cmd_options .= " --filter '$filter'" if ($filter ne '');
    $cmd_options .= " --endpoint-url $self->{endpoint_url}" if (defined($self->{endpoint_url}) && $self->{endpoint_url} ne '');

    return $cmd_options;
}

sub health_describe_events {
    my ($self, %options) = @_;

    my $cmd_options = $self->health_describe_events_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results->{events};
}

sub health_describe_affected_entities_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "health describe-affected-entities --region $self->{option_results}->{region} --output json";

    my $filter = '';
    if (defined($options{filter_event_arns})) {
        $filter = 'eventArns=' . join(',', @{$options{filter_event_arns}});
    }

    $cmd_options .= " --filter '$filter'" if ($filter ne '');
    $cmd_options .= " --endpoint-url $self->{endpoint_url}" if (defined($self->{endpoint_url}) && $self->{endpoint_url} ne '');

    return $cmd_options;
}

sub health_describe_affected_entities {
    my ($self, %options) = @_;

    my $all_results = [];
    while (my @elements = splice(@{$options{filter_event_arns}}, 0, 10)) {
        my $cmd_options = $self->health_describe_affected_entities_set_cmd(filter_event_arns => \@elements);
        my $raw_results = $self->execute(cmd_options => $cmd_options);
        push @$all_results, @{$raw_results->{entities}};
    }

    return $all_results;
}

sub sqs_list_queues_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "sqs list-queues --region $self->{option_results}->{region} --output json";
    $cmd_options .= " --endpoint-url $self->{endpoint_url}" if (defined($self->{endpoint_url}) && $self->{endpoint_url} ne '');

    return $cmd_options;
}

sub sqs_list_queues {
    my ($self, %options) = @_;

    my $cmd_options = $self->sqs_list_queues_set_cmd(%options);
    my $queues_results = $self->execute(cmd_options => $cmd_options);

    return $queues_results->{QueueUrls};
}

sub sns_list_topics_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "sns list-topics --region $self->{option_results}->{region} --output json";
    $cmd_options .= " --endpoint-url $self->{endpoint_url}" if (defined($self->{endpoint_url}) && $self->{endpoint_url} ne '');

    return $cmd_options;
}

sub sns_list_topics {
    my ($self, %options) = @_;

    my $cmd_options = $self->sns_list_topics_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    my $topics_results = [];
    foreach my $topic (@{$raw_results->{Topics}}) {
        push @{$topics_results}, { name => $topic->{TopicArn} };
    };

    return $topics_results;
}

sub tgw_list_gateways_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "ec2 describe-transit-gateways --region $self->{option_results}->{region} --output json";
    $cmd_options .= " --endpoint-url $self->{endpoint_url}" if (defined($self->{endpoint_url}) && $self->{endpoint_url} ne '');

    return $cmd_options;
}

sub tgw_list_gateways {
    my ($self, %options) = @_;

    my $cmd_options = $self->tgw_list_gateways_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    my $gateway_results = [];
    foreach my $gateway (@{$raw_results->{TransitGateways}}) {
        push @{$gateway_results}, { id => $gateway->{TransitGatewayId}, name => $gateway->{Description} };
    };

    return $gateway_results;
}

1;

__END__

=head1 NAME

Amazon AWS

=head1 AWSCLI OPTIONS

Amazon AWS CLI

=over 8

=item B<--aws-secret-key>

Set AWS secret key.

=item B<--aws-access-key>

Set AWS access key.

=item B<--aws-session-token>

Set AWS session token.

=item B<--aws-profile>

Set AWS profile.

=item B<--endpoint-url>

Override AWS service endpoint URL if necessary.

=item B<--region>

Set the region name (Required).

=item B<--period>

Set period in seconds.

=item B<--timeframe>

Set timeframe in seconds.

=item B<--statistic>

Set cloudwatch statistics (Can be: 'minimum', 'maximum', 'average', 'sum').

=item B<--zeroed>

Set metrics value to 0 if none. Usefull when CloudWatch
does not return value when not defined.

=item B<--timeout>

Set timeout in seconds (Default: 50).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'aws').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: none).

=item B<--proxyurl>

Proxy URL if any

=back

=head1 DESCRIPTION

B<custom>.

=cut
