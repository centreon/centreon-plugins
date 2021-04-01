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

package cloud::aws::custom::paws;

use strict;
use warnings;
use Paws;
use Paws::Net::LWPCaller;
use DateTime;

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
            'region:s'            => { name => 'region' },
            'timeframe:s'         => { name => 'timeframe' },
            'period:s'            => { name => 'period' },
            'statistic:s@'        => { name => 'statistic' },
            'zeroed'              => { name => 'zeroed' },
            'proxyurl:s'          => { name => 'proxyurl' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'PAWS OPTIONS', once => 1);

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
        $ENV{AWS_SECRET_KEY} = $self->{option_results}->{aws_secret_key};
    }
    if (defined($self->{option_results}->{aws_access_key}) && $self->{option_results}->{aws_access_key} ne '') {
        $ENV{AWS_ACCESS_KEY} = $self->{option_results}->{aws_access_key};
    }
    if (defined($self->{option_results}->{aws_session_token}) && $self->{option_results}->{aws_session_token} ne '') {
        $ENV{AWS_SESSION_TOKEN} = $self->{option_results}->{aws_session_token};
    }

    if (!defined($self->{option_results}->{region}) || $self->{option_results}->{region} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --region option.');
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

    return 0;
}

sub cloudwatch_get_metrics {
    my ($self, %options) = @_;

    my $metric_results = {};
    eval {
        my $lwp_caller = new Paws::Net::LWPCaller();
        my $cw = Paws->service('CloudWatch', caller => $lwp_caller, region => $self->{option_results}->{region});
        my $start_time = DateTime->now->subtract(seconds => $options{timeframe})->iso8601;
        my $end_time = DateTime->now->iso8601;

        foreach my $metric_name (@{$options{metrics}}) {
            my $metric_result = $cw->GetMetricStatistics(
                MetricName => $metric_name,
                Namespace => $options{namespace},
                Statistics => $options{statistics},
                #ExtendedStatistics => ['p100'],
                EndTime => $end_time,
                StartTime => $start_time,
                Period => $options{period},
                #Unit => $unit,
                Dimensions => $options{dimensions},
            );

            $metric_results->{$metric_result->{Label}} = { points => 0 };
            foreach my $point (@{$metric_result->{Datapoints}}) {
                if (defined($point->{Average})) {
                    $metric_results->{$metric_result->{Label}}->{average} = 0 if (!defined($metric_results->{$metric_result->{Label}}->{average}));
                    $metric_results->{$metric_result->{Label}}->{average} += $point->{Average};
                }
                if (defined($point->{Minimum})) {
                    $metric_results->{$metric_result->{Label}}->{minimum} = $point->{Minimum}
                        if (!defined($metric_results->{$metric_result->{Label}}->{minimum}) || $point->{Minimum} < $metric_results->{$metric_result->{Label}}->{minimum});
                }
                if (defined($point->{Maximum})) {
                    $metric_results->{$metric_result->{Label}}->{maximum} = $point->{Maximum}
                        if (!defined($metric_results->{$metric_result->{Label}}->{maximum}) || $point->{Maximum} > $metric_results->{$metric_result->{Label}}->{maximum});
                }
                if (defined($point->{Sum})) {
                    $metric_results->{$metric_result->{Label}}->{sum} = 0 if (!defined($metric_results->{$metric_result->{Label}}->{sum}));
                    $metric_results->{$metric_result->{Label}}->{sum} += $point->{Sum};
                }

                $metric_results->{$metric_result->{Label}}->{points}++;
            }

            if (defined($metric_results->{$metric_result->{Label}}->{average})) {
                $metric_results->{$metric_result->{Label}}->{average} /= $metric_results->{$metric_result->{Label}}->{points};
            }
        }
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }

    return $metric_results;
}

sub cloudwatch_get_alarms {
    my ($self, %options) = @_;

    my $alarm_results = [];
    eval {
        my $lwp_caller = new Paws::Net::LWPCaller();
        my $cw = Paws->service('CloudWatch', caller => $lwp_caller, region => $self->{option_results}->{region});
        my $alarms = $cw->DescribeAlarms();
        foreach my $alarm (@{$alarms->{MetricAlarms}}) {
            push @$alarm_results, {
                AlarmName => $alarm->{AlarmName},
                StateValue => $alarm->{StateValue},
                MetricName => $alarm->{MetricName},
                StateReason => $alarm->{StateReason},
                StateUpdatedTimestamp => $alarm->{StateUpdatedTimestamp},
            };
        }
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }
    return $alarm_results;
}

sub cloudwatch_list_metrics {
    my ($self, %options) = @_;

    my $metric_results = [];
    eval {
        my $lwp_caller = new Paws::Net::LWPCaller();
        my $cw = Paws->service('CloudWatch', caller => $lwp_caller, region => $self->{option_results}->{region});
        my %cw_options = ();
        $cw_options{Namespace} = $options{namespace} if (defined($options{namespace}));
        $cw_options{MetricName} = $options{metric} if (defined($options{metric}));
        while ((my $list_metrics = $cw->ListMetrics(%cw_options))) {
            foreach (@{$list_metrics->{Metrics}}) {
                my $dimensions = [];
                foreach my $dimension (@{$_->{Dimensions}}) {
                    push @$dimensions, { Name => $dimension->{Name}, Value => $dimension->{Value} };
                }
                push @{$metric_results}, {
                    Namespace => $_->{Namespace},
                    MetricName => $_->{MetricName},
                    Dimensions => $dimensions,
                };
            }

            last if (!defined($list_metrics->{NextToken}));
            $cw_options{NextToken} = $list_metrics->{NextToken};
        }
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }

    return $metric_results;
}

sub cloudwatchlogs_describe_log_groups {
    my ($self, %options) = @_;

    my $log_groups_results = [];
    eval {
        my $lwp_caller = new Paws::Net::LWPCaller();
        my $cw = Paws->service('CloudWatchLogs', caller => $lwp_caller, region => $self->{option_results}->{region});
        my %cw_options = ();
        while ((my $list_log_groups = $cw->DescribeLogGroups(%cw_options))) {
            foreach (@{$list_log_groups->{logGroups}}) {
                push @$log_groups_results, $_;
            }

            last if (!defined($list_log_groups->{NextToken}));
            $cw_options{NextToken} = $list_log_groups->{NextToken};
        }
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }

    return $log_groups_results;
}

sub cloudwatchlogs_filter_log_events {
    my ($self, %options) = @_;

    my $log_groups_results = [];
    eval {
        my $lwp_caller = new Paws::Net::LWPCaller();
        my $cw = Paws->service('CloudWatchLogs', caller => $lwp_caller, region => $self->{option_results}->{region});
        my %cw_options = ();
        $cw_options{StartTime} = $options{start_time} if (defined($options{start_time}));
        $cw_options{LogStreamNames} = [@{$options{LogStreamNames}}] if (defined($options{LogStreamNames}));
        while ((my $list_log_groups = $cw->FilterLogEvents(%cw_options))) {
            foreach (@{$list_log_groups->{logGroups}}) {
                push @$log_groups_results, $_;
            }

            last if (!defined($list_log_groups->{NextToken}));
            $cw_options{NextToken} = $list_log_groups->{NextToken};
        }
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }

    return $log_groups_results;
}

sub ebs_list_volumes {
    my ($self, %options) = @_;

    my $volume_results = [];
    eval {
        my $lwp_caller = new Paws::Net::LWPCaller();
        my $ebsvolume = Paws->service('EC2', caller => $lwp_caller, region => $self->{option_results}->{region});
        my $ebsvolume_requests = $ebsvolume->DescribeVolumes(DryRun => 0);
        foreach my $request (@{$ebsvolume_requests->{Volumes}}) {
            my @name_tags;
            foreach my $tag (@{$request->{Tags}}) {
                if ($tag->{Key} eq "Name" && defined($tag->{Value})) {
                    push @name_tags, $tag->{Value};
                }
            };
            push @{$volume_results}, {
                VolumeId       => $request->{VolumeId},
                VolumeName     => join(",", @name_tags),
                VolumeType     => $request->{VolumeType},
                VolumeState    => $request->{State}
            };
        }
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }

    return $volume_results;
}

sub ec2_get_instances_status {
    my ($self, %options) = @_;

    my $instance_results = {};
    eval {
        my $lwp_caller = new Paws::Net::LWPCaller();
        my $ec2 = Paws->service('EC2', caller => $lwp_caller, region => $self->{option_results}->{region});
        my $instances = $ec2->DescribeInstanceStatus(DryRun => 0, IncludeAllInstances => 1);

        foreach (@{$instances->{InstanceStatuses}}) {
            $instance_results->{$_->{InstanceId}} = {
                state => $_->{InstanceState}->{Name},
                status => $_->{InstanceStatus}->{Status}
            };
        }
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }

    return $instance_results;
}

sub ec2spot_get_active_instances {
    my ($self, %options) = @_;

    my $instance_results = {};
    eval {
        my $lwp_caller = new Paws::Net::LWPCaller();
        my $ec2 = Paws->service('EC2', caller => $lwp_caller, region => $self->{option_results}->{region});
        my $instances = $ec2->DescribeSpotFleetInstances('SpotFleetRequestId' => $options{spot_fleet_request_id}, DryRun => 0, IncludeAllInstances => 1);

        foreach (@{$instances->{ActiveInstances}}) {
            $instance_results->{$_->{InstanceId}} = {
                health      => $_->{InstanceHealth},
                type        => $_->{InstanceType},
                request_id  => $_->{SpotInstanceRequestId} };
        }
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }

    return $instance_results;
}

sub ec2spot_list_fleet_requests {
    my ($self, %options) = @_;

    my $resource_results = [];
    eval {
        my $lwp_caller = new Paws::Net::LWPCaller();
        my $ec2spot = Paws->service('EC2', caller => $lwp_caller, region => $self->{option_results}->{region});
        my $spot_fleet_requests = $ec2spot->DescribeSpotFleetRequests(DryRun => 0);

        foreach (@{$spot_fleet_requests->{SpotFleetRequestConfigs}}) {
            push @{$resource_results}, {
                SpotFleetRequestState => $_->{SpotFleetRequestState},
                SpotFleetRequestId    => $_->{SpotFleetRequestId},
                ActivityStatus        => $_->{ActivityStatus}
            };
        }
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }

    return $resource_results;
}

sub ec2_list_resources {
    my ($self, %options) = @_;

    my $resource_results = [];
    eval {
        my $lwp_caller = new Paws::Net::LWPCaller();
        my $ec2 = Paws->service('EC2', caller => $lwp_caller, region => $self->{option_results}->{region});
        my $list_instances = $ec2->DescribeInstances(DryRun => 0);

        foreach my $reservation (@{$list_instances->{Reservations}}) {
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
                    } elsif (defined($tag->{Key}) && defined($tag->{Value})) {
                        push @instance_tags, $tag->{Key} . ":" . $tag->{Value};
                    }
                }
                push @{$resource_results}, { 
                    Name => $instance->{InstanceId},
                    Type => 'instance',
                    AvailabilityZone => $instance->{Placement}->{AvailabilityZone},
                    InstanceType => $instance->{InstanceType},
                    State => $instance->{State}->{Name},
                    Tags => join(",", @instance_tags),
                };

            }
        }
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }

    return $resource_results;
}

sub asg_get_resources {
    my ($self, %options) = @_;

    my $autoscaling_groups = {};
    eval {
        my $lwp_caller = new Paws::Net::LWPCaller();
        my $asg = Paws->service('AutoScaling', caller => $lwp_caller, region => $self->{option_results}->{region});
        $autoscaling_groups = $asg->DescribeAutoScalingGroups();
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }

    return \@{$autoscaling_groups->{AutoScalingGroups}};
}

sub rds_get_instances_status {
    my ($self, %options) = @_;

    my $instance_results = {};
    eval {
        my $lwp_caller = new Paws::Net::LWPCaller();
        my $rds = Paws->service('RDS', caller => $lwp_caller, region => $self->{option_results}->{region});
        my $instances = $rds->DescribeDBInstances();
        foreach (@{$instances->{DBInstances}}) {
            $instance_results->{$_->{DBInstanceIdentifier}} = { state => $_->{DBInstanceStatus} };
        }
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }

    return $instance_results;
}

sub rds_list_instances {
    my ($self, %options) = @_;

    my $instance_results = [];
    eval {
        my $lwp_caller = new Paws::Net::LWPCaller();
        my $rds = Paws->service('RDS', caller => $lwp_caller, region => $self->{option_results}->{region});
        my $list_instances = $rds->DescribeDBInstances();

        foreach my $instance (@{$list_instances->{DBInstances}}) {
            push @{$instance_results}, {
                Name => $instance->{DBInstanceIdentifier},
                AvailabilityZone => $instance->{AvailabilityZone},
                Engine => $instance->{Engine},
                StorageType => $instance->{StorageType},
                DBInstanceStatus => $instance->{DBInstanceStatus},
                AllocatedStorage => $instance->{AllocatedStorage}
            };
        }
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }

    return $instance_results;
}

sub rds_list_clusters {
    my ($self, %options) = @_;

    my $cluster_results = [];
    eval {
        my $lwp_caller = new Paws::Net::LWPCaller();
        my $rds = Paws->service('RDS', caller => $lwp_caller, region => $self->{option_results}->{region});
        my $list_clusters = $rds->DescribeDBClusters();

        foreach my $cluster (@{$list_clusters->{DBClusters}}) {
            push @{$cluster_results}, {
                Name => $cluster->{DBClusterIdentifier},
                DatabaseName => $cluster->{DatabaseName},
                Engine => $cluster->{Engine},
                Status => $cluster->{Status},
                AllocatedStorage => $cluster->{AllocatedStorage}
            };
        }
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }

    return $cluster_results;
}

sub vpn_list_connections {
    my ($self, %options) = @_;
    my $connections_results = [];
    eval {
        my $lwp_caller = new Paws::Net::LWPCaller();
        my $vpn = Paws->service('EC2', caller => $lwp_caller, region => $self->{option_results}->{region});
        my $list_vpn = $vpn->DescribeVpnConnections();
        foreach my $connection (@{$list_vpn->{VpnConnections}}) {
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
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }

    return $connections_results;
}

sub health_describe_events {
    my ($self, %options) = @_;

    my $event_results = [];
    eval {
        my $lwp_caller = new Paws::Net::LWPCaller();
        my $health = Paws->service('Health', caller => $lwp_caller, region => $self->{option_results}->{region});
        my $health_options = { Filter => {} };
        foreach ((['service', 'Services'], ['region', 'Regions'], ['entity_value', 'EntityValues'], ['event_status', 'EventStatusCodes'], ['event_category', 'EventTypeCategories'])) {
            next if (!defined($options{ $_->[0] }));
            $health_options->{Filter}->{ $_->[1] } = $_->[0];
        }

        while ((my $events = $health->DescribeEvents(%$health_options))) {
            foreach (@{$events->{Events}}) {
                push @$event_results, {
                    arn => $_->{Arn},
                    service => $_->{Service},
                    eventTypeCode => $_->{EventTypeCode},
                    eventTypeCategory => $_->{EventTypeCategory},
                    region => $_->{Region},
                    startTime => $_->{StartTime},
                    lastUpdatedTime => $_->{LastUpdatedTime},
                    statusCode => $_->{StatusCode}
                };
            }

            last if (!defined($events->{NextToken}));
            $health_options->{NextToken} = $events->{NextToken};
        }
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }

    return $event_results;
}

sub health_describe_affected_entities {
    my ($self, %options) = @_;

    my $entities_results = [];
    eval {
        my $lwp_caller = new Paws::Net::LWPCaller();
        my $health = Paws->service('Health', caller => $lwp_caller, region => $self->{option_results}->{region});
        my $health_options = { Filter => {} };
        if (defined($options{filter_event_arns})) {
            $health_options->{Filter}->{EventArns} = $options{filter_event_arns};
        }

        while ((my $entities = $health->DescribeAffectedEntities(%$health_options))) {
            foreach (@{$entities->{Entities}}) {
                push @$entities_results, {
                    entityArn => $_->{EntityArn},
                    eventArn => $_->{EventArn},
                    entityValue => $_->{EntityValue},
                    awsAccountId => $_->{AwsAccountId},
                    lastUpdatedTime => $_->{LastUpdatedTime},
                    statusCode => $_->{StatusCode}
                };
            }

            last if (!defined($entities->{NextToken}));
            $health_options->{NextToken} = $entities->{NextToken};
        }
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }

    return $entities_results;
}

sub sqs_list_queues {
    my ($self, %options) = @_;
    my $queues_results = [];
    eval {
        my $lwp_caller = new Paws::Net::LWPCaller();
        my $queues = Paws->service('SQS', caller => $lwp_caller, region => $self->{option_results}->{region});
        my $list_queues = $queues->ListQueues();
        foreach my $queue (@{$list_queues->{QueueUrls}}) {
            push @{$queues_results}, $queue;
        };
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }

    return $queues_results;
}

sub sns_list_topics {
    my ($self, %options) = @_;
    my $topics_results = [];
    eval {
        my $lwp_caller = new Paws::Net::LWPCaller();
        my $topics = Paws->service('SNS', caller => $lwp_caller, region => $self->{option_results}->{region});
        my $raw_results = $topics->ListTopics();
        foreach my $topic (@{$raw_results->{Topics}}) {
            push @{$topics_results}, { name => $topic->{TopicArn} };
        };
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }

    return $topics_results;
}

sub tgw_list_gateways {
    my ($self, %options) = @_;
    my $gateway_results = [];
    eval {
        my $lwp_caller = new Paws::Net::LWPCaller();
        my $gateways = Paws->service('EC2', caller => $lwp_caller, region => $self->{option_results}->{region});
        my $raw_results = $gateways->DescribeTransitGateways();
        foreach my $gateway (@{$raw_results->{TransitGateways}}) {
            push @{$gateway_results}, { id => $gateway->{TransitGatewayId}, name => $gateway->{Description} };
        };
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }

    return $gateway_results;
}

1;

__END__

=head1 NAME

Amazon AWS

=head1 SYNOPSIS

Amazon AWS

=head1 PAWS OPTIONS

=over 8

=item B<--aws-secret-key>

Set AWS secret key.

=item B<--aws-access-key>

Set AWS access key.

=item B<--aws-session-token>

Set AWS session token.

=item B<--region>

Set the region name (Required).

=item B<--period>

Set period in seconds.

=item B<--timeframe>

Set timeframe in seconds.

=item B<--statistic>

Set cloudwatch statistics
(Can be: 'minimum', 'maximum', 'average', 'sum').

=item B<--zeroed>

Set metrics value to 0 if none. Usefull when CloudWatch
does not return value when not defined.

=item B<--proxyurl>

Proxy URL if any

=back

=head1 DESCRIPTION

B<custom>.

=cut
