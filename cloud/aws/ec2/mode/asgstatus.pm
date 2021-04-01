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

package cloud::aws::ec2::mode::asgstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = "[Health: " . $self->{result_values}->{health} .
        " - Lifecycle: " . $self->{result_values}->{lifecycle} . "]";

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{health} = $options{new_datas}->{$self->{instance} . '_health'};
    $self->{result_values}->{lifecycle} = $options{new_datas}->{$self->{instance} . '_lifecycle'};
    $self->{result_values}->{asg} = $options{new_datas}->{$self->{instance} . '_asg'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_asg_output {
    my ($self, %options) = @_;

    my $msg = sprintf('Instance current count: %s (config: min=%d max=%d)',
        $self->{result_values}->{count},
        $self->{result_values}->{min_size},
        $self->{result_values}->{max_size});
    return $msg;
}

sub custom_asg_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{count} = $options{new_datas}->{$self->{instance} . '_count'};
    $self->{result_values}->{min_size} = $options{new_datas}->{$self->{instance} . '_min_size'};
    $self->{result_values}->{max_size} = $options{new_datas}->{$self->{instance} . '_max_size'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};

    return 0;
}

sub prefix_awsasg_output {
    my ($self, %options) = @_;

    return "AutoScalingGroup '" . $options{instance_value}->{display} . "' ";
}

sub prefix_awsinstance_output {
    my ($self, %options) = @_;

    return "Instance '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'aws_asg', type => 1, cb_prefix_output => 'prefix_awsasg_output',
          message_multiple => 'All Auto Scaling Groups are ok' },
        { name => 'aws_instances', type => 1, cb_prefix_output => 'prefix_awsinstance_output',
          message_multiple => 'All instances are ok' },
    ];

    $self->{maps_counters}->{aws_asg} = [
        { label => 'asg-instance-current', nlabel => 'ec2.asg.instance.current.count', set => {
                key_values => [ { name => 'display' }, { name => 'count' },
                    { name => 'min_size' }, { name => 'max_size' } ],
                threshold_use => 'count',
                closure_custom_calc => $self->can('custom_asg_calc'),
                closure_custom_output => $self->can('custom_asg_output'),
                perfdatas => [
                    { value => 'count', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
    $self->{maps_counters}->{aws_instances} = [
        { label => 'instances', set => {
                key_values => [ { name => 'health' }, { name => 'lifecycle' },
                    { name => 'asg' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "filter-asg:s"          => { name => 'filter_asg', default => '' },
        "warning-instances:s"   => { name => 'warning_instances', default => '' },
        "critical-instances:s"  => { name => 'critical_instances',
            default => '%{health} =~ /Healthy/ && %{lifecycle} !~ /InService/' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_instances', 'critical_instances']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{aws_autoscaling_groups} = {};

    my $result = $options{custom}->asg_get_resources();

    foreach my $asg (@{$result}) {
        my $instance_count = 0;

        if (defined($self->{option_results}->{filter_asg}) && $self->{option_results}->{filter_asg} ne '' &&
            $asg->{AutoScalingGroupName} !~ /$self->{option_results}->{filter_asg}/) {
            $self->{output}->output_add(long_msg => "skipping asg '" . $asg->{AutoScalingGroupName} . "': no matching filter.", debug => 1);
            next;
        }

        foreach my $instance (@{$asg->{Instances}}) {
             $self->{aws_instances}->{$instance->{InstanceId}} = {
                 display => $instance->{InstanceId},
                asg => $asg->{AutoScalingGroupName},
                health => $instance->{HealthStatus},
                lifecycle => $instance->{LifecycleState}
            };
            $instance_count++;
        }
        $self->{aws_asg}->{$asg->{AutoScalingGroupName}} = {
            display => $asg->{AutoScalingGroupName},
            min_size => $asg->{MinSize},
            max_size => $asg->{MaxSize},
            count => $instance_count
        };
    }

    if (scalar(keys %{$self->{aws_instances}}) <= 0 && $self->{aws_asg} <= 0) {
        $self->{output}->add_option_msg(short_msg => "Didn't check anything, are your filters correct ?");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check EC2 Auto Scaling Groups and related instances status
(number of instances within, state of each instances)

Example: 
perl centreon_plugins.pl --plugin=cloud::aws::ec2::plugin --custommode=paws --mode=asg-status --region='eu-west-1'
--critical-instances='%{health} =~ /Healthy/ && %{lifecycle} !~ /InService/' --warning-count 10 --verbose

See 'https://docs.aws.amazon.com/autoscaling/ec2/APIReference/API_DescribeAutoScalingGroups.html' for more informations.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Possible values: asg / instances

=item B<--filter-asg>

Filter by autoscaling group name (can be a regexp).

=item B<--warning-instances>

Set warning threshold for status (Default: '').
Can use special variables like: %{health}, %{lifecycle}

=item B<--critical-instances>

Set critical threshold for instances states
(Default: '%{health} =~ /Healthy/ && %{lifecycle} !~ /InService/').
Can use special variables like: %{health}, %{lifecycle}

=item B<--warning-asg-instance-current>

Threshold warning about number of
instances in the autoscaling group

=item B<--critical-asg-instance-current>

Threshold critical about number of
instances in the autoscaling group

=back

=cut
