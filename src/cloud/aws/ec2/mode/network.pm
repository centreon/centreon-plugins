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

package cloud::aws::ec2::mode::network;

use base qw(cloud::aws::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        extra_params => {
            message_multiple => 'All network metrics are ok'
        },
        metrics => {
            NetworkIn => {
                output => 'Network In',
                label => 'network-in',
                nlabel => {
                    absolute => 'ec2.network.in.bytes',
                    per_second => 'ec2.network.in.bytespersecond'
                },
                unit => 'B'
            },
            NetworkOut => {
                output => 'Network Out',
                label => 'network-out',
                nlabel => {
                    absolute => 'ec2.network.out.bytes',
                    per_second => 'ec2.network.out.bytespersecond'
                },
                unit => 'B'
            },
            NetworkPacketsIn => {
                output => 'Network Packets In',
                label => 'network-packets-in',
                nlabel => {
                    absolute => 'ec2.network.packets.in.count',
                    per_second => 'ec2.network.packets.in.persecond'
                },
                unit => 'packets'
            },
            NetworkPacketsOut => {
                output => 'Network Packets Out',
                label => 'network-packets-out',
                nlabel => {
                    absolute => 'ec2.network.packets.out.count',
                    per_second => 'ec2.network.packets.out.persecond'
                },
                unit => 'packets'
            }
        }
    };

    return $metrics_mapping;
}

sub prefix_metric_output {
    my ($self, %options) = @_;
    
    return ucfirst($self->{option_results}->{type}) . " '" . $options{instance_value}->{display} . "' ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking " . ucfirst($self->{option_results}->{type}) . " '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'type:s'  => { name => 'type' },
        'name:s@' => { name => 'name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{type}) || $self->{option_results}->{type} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --type option.");
        $self->{output}->option_exit();
    }

    if ($self->{option_results}->{type} ne 'asg' && $self->{option_results}->{type} ne 'instance') {
        $self->{output}->add_option_msg(short_msg => "Instance type '" . $self->{option_results}->{type} . "' is not handled for this mode");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{name}) || $self->{option_results}->{name} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --name option.");
        $self->{output}->option_exit();
    }

    foreach my $instance (@{$self->{option_results}->{name}}) {
        if ($instance ne '') {
            push @{$self->{aws_instance}}, $instance;
        }
    }
}

my %map_type = (
    'instance' => "InstanceId",
    'asg'      => "AutoScalingGroupName"
);

sub manage_selection {
    my ($self, %options) = @_;

    my %metric_results;
    foreach my $instance (@{$self->{aws_instance}}) {
        $metric_results{$instance} = $options{custom}->cloudwatch_get_metrics(
            namespace => 'AWS/EC2',
            dimensions => [ { Name => $map_type{$self->{option_results}->{type}}, Value => $instance } ],
            metrics => $self->{aws_metrics},
            statistics => $self->{aws_statistics},
            timeframe => $self->{aws_timeframe},
            period => $self->{aws_period},
        );

        foreach my $metric (@{$self->{aws_metrics}}) {
            foreach my $statistic (@{$self->{aws_statistics}}) {
                next if (!defined($metric_results{$instance}->{$metric}->{lc($statistic)}) &&
                    !defined($self->{option_results}->{zeroed}));

                $self->{metrics}->{$instance}->{display} = $instance;
                $self->{metrics}->{$instance}->{statistics}->{lc($statistic)}->{display} = $statistic;
                $self->{metrics}->{$instance}->{statistics}->{lc($statistic)}->{timeframe} = $self->{aws_timeframe};
                $self->{metrics}->{$instance}->{statistics}->{lc($statistic)}->{$metric} = 
                    defined($metric_results{$instance}->{$metric}->{lc($statistic)}) ? 
                    $metric_results{$instance}->{$metric}->{lc($statistic)} : 0;
            }
        }
    }

    if (scalar(keys %{$self->{metrics}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No metrics. Check your options or use --zeroed option to set 0 on undefined values');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check EC2 instances network metrics.

Example: 
perl centreon_plugins.pl --plugin=cloud::aws::ec2::plugin --custommode=paws --mode=network --region='eu-west-1'
--type='asg' --name='centreon-middleware' --filter-metric='Packets' --statistic='sum'
--critical-network-packets-out='10' --verbose

See 'https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ec2-metricscollected.html' for more informations.

Default statistic: 'average' / All satistics are valid.

=over 8

=item B<--type>

Set the instance type (required) (can be: 'asg', 'instance').

=item B<--name>

Set the instance name (required) (can be defined multiple times).

=item B<--filter-metric>

Filter metrics (can be: 'NetworkIn', 'NetworkOut', 
'NetworkPacketsIn', 'NetworkPacketsOut') 
(can be a regexp).

=item B<--warning-*> B<--critical-*>

Warning thresholds (can be 'network-in', 'network-out',
'network-packets-in', 'network-packets-out'.

=item B<--per-sec>

Change the data to be unit/sec.

=back

=cut
