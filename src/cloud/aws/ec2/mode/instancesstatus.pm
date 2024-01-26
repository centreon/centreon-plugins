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

package cloud::aws::ec2::mode::instancesstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use POSIX;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use DateTime;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_uptime_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{uptime_unit} },
        unit => $self->{instance_mode}->{option_results}->{uptime_unit},
        instances => $self->{result_values}->{display},
        value => floor($self->{result_values}->{uptime_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{uptime_unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_uptime_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{uptime_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{uptime_unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}


sub custom_status_output {
    my ($self, %options) = @_;
    
    return sprintf('state: %s, status: %s', $self->{result_values}->{state}, $self->{result_values}->{status});
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Total instances ';
}

sub prefix_awsinstance_output {
    my ($self, %options) = @_;
    
    return "Instance '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'aws_instances', type => 1, cb_prefix_output => 'prefix_awsinstance_output',
          message_multiple => 'All instances are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'pending', nlabel => 'ec2.instances.status.pending.count', set => {
                key_values => [ { name => 'pending' }  ],
                output_template => "pending: %s",
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'running', nlabel => 'ec2.instances.status.running.count', set => {
                key_values => [ { name => 'running' }  ],
                output_template => "running: %s",
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'shuttingdown', nlabel => 'ec2.instances.status.shuttingdown.count', set => {
                key_values => [ { name => 'shutting-down' }  ],
                output_template => "shutting down: %s",
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'terminated', nlabel => 'ec2.instances.status.terminated.count', set => {
                key_values => [ { name => 'terminated' }  ],
                output_template => "terminated: %s",
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'stopping', nlabel => 'ec2.instances.status.stopping.count', set => {
                key_values => [ { name => 'stopping' }  ],
                output_template => "stopping: %s",
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'stopped', nlabel => 'ec2.instances.status.stopped.count', set => {
                key_values => [ { name => 'stopped' }  ],
                output_template => "stopped: %s",
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{aws_instances} = [
        { label => 'status', type => 2, set => {
                key_values => [ { name => 'state' }, { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'uptime', nlabel => 'ec2.uptime', set => {
                key_values      => [ { name => 'uptime_seconds' }, { name => 'uptime_human' }, { name => 'display' } ],
                output_template => 'uptime: %s',
                output_use => 'uptime_human',
                closure_custom_perfdata => $self->can('custom_uptime_perfdata'),
                closure_custom_threshold_check => $self->can('custom_uptime_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-instanceid:s' => { name => 'filter_instanceid' },
        'add-uptime'          => { name => 'add_uptime' },
        'uptime-unit:s'       => { name => 'uptime_unit', default => 'd' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{uptime_unit} eq '' || !defined($unitdiv->{$self->{option_results}->{uptime_unit}})) {
        $self->{option_results}->{uptime_unit} = 'd';
    }
}

sub add_uptime {
    my ($self, %options) = @_;

    return if (!defined($options{instances}->{ $options{instance_id} }));

    return if ($options{state} !~ /running|stopping/);

    # format: "2021-04-16T07:54:33.000Z"
    return if ($options{instances}->{ $options{instance_id} }->{LaunchTime} !~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)/);

    my $dt = DateTime->new(
      year       => $1,
      month      => $2,
      day        => $3,
      hour       => $4,
      minute     => $5,
      second     => $6,
      time_zone  => 'UTC'
    );
    $self->{aws_instances}->{ $options{instance_id} }->{uptime_seconds} = time() - $dt->epoch();
    $self->{aws_instances}->{ $options{instance_id} }->{uptime_human} = centreon::plugins::misc::change_seconds(
        value => $self->{aws_instances}->{ $options{instance_id} }->{uptime_seconds}
    );
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {
        pending => 0, running => 0, 'shutting-down' => 0, terminated => 0, stopping => 0, stopped => 0,
    };

    $self->{aws_instances} = {};
    my $result = $options{custom}->ec2_get_instances_status();

    my $instances;
    if (defined($self->{option_results}->{add_uptime})) {
        $instances = $options{custom}->ec2_get_instances();
    }
    foreach my $instance_id (keys %{$result}) {
        if (defined($self->{option_results}->{filter_instanceid}) && $self->{option_results}->{filter_instanceid} ne '' &&
            $instance_id !~ /$self->{option_results}->{filter_instanceid}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $instance_id . "': no matching filter.", debug => 1);
            next;
        }

        $self->{aws_instances}->{$instance_id} = { 
            display => $instance_id, 
            state => $result->{$instance_id}->{state},
            status => $result->{$instance_id}->{status}
        };
        $self->add_uptime(instances => $instances, instance_id => $instance_id, state => $result->{$instance_id}->{state})
            if (defined($self->{option_results}->{add_uptime}));
        $self->{global}->{ $result->{$instance_id}->{state} }++;
    }

    if (scalar(keys %{$self->{aws_instances}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No aws instance found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check EC2 instances status.

Example:
perl centreon_plugins.pl --plugin=cloud::aws::ec2::plugin --custommode=paws --mode=instances-status --region='eu-west-1'
--filter-instanceid='.*' --filter-counters='^running$' --critical-running='10' --verbose

See 'https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeInstanceStatus.html' for more informations.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^running$'

=item B<--filter-instanceid>

Filter by instance ID (can be a regexp).

=item B<--add-uptime>

Monitor instances uptime.

=item B<--uptime-unit>

Select the unit for uptime threshold. May be 's' for seconds, 'm' for minutes,
'h' for hours, 'd' for days, 'w' for weeks. Default is days.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{state}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'pending', 'running', 'shuttingdown', 
'terminated', 'stopping', 'stopped',
'uptime'.

=back

=cut
