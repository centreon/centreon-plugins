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

package cloud::aws::ec2::mode::status;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my %map_type = (
    "instance" => "InstanceId",
    "asg"      => "AutoScalingGroupName",
);

my %map_status = (
    0 => 'passed',
    1 => 'failed',
);

sub prefix_metric_output {
    my ($self, %options) = @_;
    
    return ucfirst($options{instance_value}->{type}) . " '" . $options{instance_value}->{display} . "' ";
}

sub custom_status_threshold {
    my ($self, %options) = @_;
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($self->{instance_mode}->{option_results}->{critical_status}) && $self->{instance_mode}->{option_results}->{critical_status} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($self->{instance_mode}->{option_results}->{warning_status}) && $self->{instance_mode}->{option_results}->{warning_status} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{warning_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = $self->{result_values}->{metric}  . ": " . $self->{result_values}->{status};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $map_status{$options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{metric}}};
    $self->{result_values}->{metric} = $options{extra_options}->{metric};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'metric', type => 1, cb_prefix_output => 'prefix_metric_output', message_multiple => "All status metrics are ok", skipped_code => { -10 => 1 } },
    ];

    foreach my $metric ('StatusCheckFailed_Instance', 'StatusCheckFailed_System') {
        my $entry = { label => lc($metric), threshold => 0, set => {
                            key_values => [ { name => $metric }, { name => 'display' } ],
                            closure_custom_calc => $self->can('custom_status_calc'),
                            closure_custom_calc_extra_options => { metric => $metric },
                            closure_custom_output => $self->can('custom_status_output'),
                            closure_custom_perfdata => sub { return 0; },
                            closure_custom_threshold_check => $self->can('custom_status_threshold'),
                        }
                    };
        push @{$self->{maps_counters}->{metric}}, $entry;
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "type:s"	            => { name => 'type' },
        "name:s@"	            => { name => 'name' },
        "warning-status:s"      => { name => 'warning_status', default => '' },
        "critical-status:s"     => { name => 'critical_status', default => '%{status} =~ /failed/i' },
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
    
    $self->{aws_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 90;
    $self->{aws_period} = defined($self->{option_results}->{period}) ? $self->{option_results}->{period} : 60;
    $self->{aws_statistics} = ['Average'];

    foreach my $metric ('StatusCheckFailed_Instance', 'StatusCheckFailed_System') {
        push @{$self->{aws_metrics}}, $metric;
    }

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

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
        
        foreach my $metric (keys %{$metric_results{$instance}}) {
            next if (!defined($metric_results{$instance}->{$metric}->{average}));

            $self->{metric}->{$instance}->{display} = $instance;
            $self->{metric}->{$instance}->{type} = $self->{option_results}->{type};
            $self->{metric}->{$instance}->{$metric} = $metric_results{$instance}->{$metric}->{average};
        }
    }

    if (scalar(keys %{$self->{metric}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No metrics detected.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check EC2 instances status metrics.

Example: 
perl centreon_plugins.pl --plugin=cloud::aws::ec2::plugin --custommode=paws --mode=status --region='eu-west-1'
--type='asg' --name='centreon-middleware' --verbose

See 'https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ec2-metricscollected.html' for more informations.

Default statistic: 'average' / Only valid statistic: 'average'.

=over 8

=item B<--type>

Set the instance type (Required) (Can be: 'asg', 'instance').

=item B<--name>

Set the instance name (Required) (Can be multiple).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}.
'status' can be: 'passed', 'failed'.

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /failed/i').
Can used special variables like: %{status}.
'status' can be: 'passed', 'failed'.

=back

=cut
