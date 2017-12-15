#
# Copyright 2017 Centreon (http://www.centreon.com/)
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
        $options{options}->add_options(arguments => 
                    {                      
                    "aws-secret-key:s"  => { name => 'aws_secret_key' },
                    "aws-access-key:s"  => { name => 'aws_access_key' },
                    });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'AWS OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{mode} = $options{mode};
    
    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {
    my ($self, %options) = @_;

    foreach (keys %{$options{default}}) {
        if ($_ eq $self->{mode}) {
            for (my $i = 0; $i < scalar(@{$options{default}->{$_}}); $i++) {
                foreach my $opt (keys %{$options{default}->{$_}[$i]}) {
                    if (!defined($self->{option_results}->{$opt}[$i])) {
                        $self->{option_results}->{$opt}[$i] = $options{default}->{$_}[$i]->{$opt};
                    }
                }
            }
        }
    }
}

sub check_options {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{aws_secret_key}) && $self->{option_results}->{aws_secret_key} ne '') {
        $ENV{AWS_SECRET_KEY} = $self->{option_results}->{aws_secret_key};
    }
    if (defined($self->{option_results}->{aws_access_key}) && $self->{option_results}->{aws_access_key} ne '') {
        $ENV{AWS_ACCESS_KEY} = $self->{option_results}->{aws_access_key};
    }

    return 0;
}

sub cloudwatch_get_metrics {
    my ($self, %options) = @_;
    
    my $metric_results = {};
    eval {
        my $cw = Paws->service('CloudWatch', region => $options{region});
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
        my $cw = Paws->service('CloudWatch', region => $options{region});
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
        my $cw = Paws->service('CloudWatch', region => $options{region});
        my %options = ();
        $options{Namespace} = $options{namespace} if (defined($options{namespace}));
        while ((my $list_metrics = $cw->ListMetrics(%options))) {
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
            $options{NextToken} = $list_metrics->{NextToken};
        }
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }
    
    return $metric_results;
}

sub ec2_get_instances_status {
    my ($self, %options) = @_;
    
    my $instance_results = {};
    eval {
        my $ec2 = Paws->service('EC2', region => $options{region});
        my $instances = $ec2->DescribeInstanceStatus(DryRun => 0, IncludeAllInstances => 1);
        foreach (@{$instances->{InstanceStatuses}}) {
            $instance_results->{$_->{InstanceId}} = { state => $_->{InstanceState}->{Name} };
        }
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "error: $@");
        $self->{output}->option_exit();
    }
    
    return $instance_results;
}

sub rds_get_instances_status {
    my ($self, %options) = @_;
    
    my $instance_results = {};
    eval {
        my $rds = Paws->service('RDS', region => $options{region});
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

1;

__END__

=head1 NAME

Amazon AWS

=head1 SYNOPSIS

Amazon AWS

=head1 AWS OPTIONS

=over 8

=item B<--aws-secret-key>

Set AWS secret key.

=item B<--aws-access-key>

Set AWS access key.

=back

=head1 DESCRIPTION

B<custom>.

=cut
