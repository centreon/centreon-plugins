#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package apps::mulesoft::restapi::mode::messages;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use POSIX;

use base qw(centreon::plugins::templates::counter);

sub prefix_queue_output {
    my ($self, %options) = @_;

    return "Queue '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'queues', type => 1, cb_prefix_output => 'prefix_queue_output', message_multiple => 'All queues are ok' }
    ];

    $self->{maps_counters}->{queues} = [
        { label => 'total', nlabel => 'mulesoft.mq.messages.total.count', set => {
                key_values      => [ { name => 'total' }, { name => 'display' } ],
                output_template => 'total: %s',
                perfdatas       => [ { template => '%d', min => 0, cast_int => 1, label_extra_instance => 1, instance_use => 'display' } ]
            }
        },
        { label => 'inflight', nlabel => 'mulesoft.mq.inflight.count', set => {
                key_values      => [ { name => 'inflight' }, { name => 'display' } ],
                output_template => 'inflight: %s',
                perfdatas       => [ { template => '%d', min => 0, cast_int => 1, label_extra_instance => 1, instance_use => 'display' } ]
            }
        },
        { label => 'received', nlabel => 'mulesoft.mq.received.count', set => {
                key_values      => [ { name => 'received' }, { name => 'display' } ],
                output_template => 'received: %s',
                perfdatas       => [ { template => '%d', min => 0, cast_int => 1, label_extra_instance => 1, instance_use => 'display' } ]
            }
        },
        { label => 'sent', nlabel => 'mulesoft.mq.sent.count', set => {
                key_values      => [ { name => 'sent' }, { name => 'display' } ],
                output_template => 'sent: %s',
                perfdatas       => [ { template => '%d', min => 0, cast_int => 1, label_extra_instance => 1, instance_use => 'display' } ]
            }
        },
        { label => 'visible', nlabel => 'mulesoft.mq.visible.count', set => {
                key_values      => [ { name => 'visible' }, { name => 'display' } ],
                output_template => 'visible: %s',
                perfdatas       => [ { template => '%d', min => 0, cast_int => 1, label_extra_instance => 1, instance_use => 'display' } ]
            }
        },
        { label => 'acked', nlabel => 'mulesoft.mq.acked.count', set => {
                key_values      => [ { name => 'acked' }, { name => 'display' } ],
                output_template => 'acked: %s',
                perfdatas       => [ { template => '%d', min => 0, cast_int => 1, label_extra_instance => 1, instance_use => 'display' } ]
            }
        }
   ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
        'region-id:s'   => { name => 'region_id' },
        'timeframe:s'   => { name => 'timeframe', default => '600' },
        'period:s'      => { name => 'period', default => '60' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{region_id}) || $self->{option_results}->{region_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --region-id option.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    POSIX::setlocale(LC_ALL, "C");
    my $time = time();
    my $end_time = POSIX::strftime('%a, %d %b %Y %H:%M:%S', gmtime()) . ' GMT';
    my $start_time = POSIX::strftime('%a, %d %b %Y %H:%M:%S', gmtime($time - $self->{option_results}->{timeframe})) . ' GMT';

    my $destinations = $options{custom}->list_objects(
        api_type  => 'mq',
        endpoint  => '/destinations',
        region_id => $self->{option_results}->{region_id},
    );

    my $get_param = [
        'startDate=' . $start_time,
        'endDate=' . $end_time,
        'period=' . $self->{option_results}->{period}
    ];

    foreach my $queue (@{$destinations}) {
        next if (defined($self->{option_results}->{filter_name})
                && $self->{option_results}->{filter_name} ne ''
                && $queue->{queueId} !~ /$self->{option_results}->{filter_name}/ );
        my $queue_stats = $options{custom}->get_objects_status(
            api_type  => 'mq',
            endpoint  => '/queues',
            region_id => $self->{option_results}->{region_id},
            object_id => $queue->{queueId},
            get_param => $get_param
        );

        my $message_type = {};
        my $total_value;

        foreach my $message_type (keys %$queue_stats) {
            next if ($message_type =~ 'destination');
            foreach my $values (@{$queue_stats->{$message_type}} ) {
                push @{$self->{raw_results}->{$queue->{queueId}}->{$message_type}}, $values->{value};
                $total_value += $values->{value};
            }
            my $points = scalar(@{$self->{raw_results}->{$queue->{queueId}}->{$message_type}});

            $self->{raw_results}->{$queue->{queueId}}{$message_type} =  $total_value / $points;
        }

        $self->{queues}->{$queue->{queueId}} = {
            display  => $queue->{queueId},
            total    => $self->{raw_results}->{$queue->{queueId}}{messages},
            inflight => $self->{raw_results}->{$queue->{queueId}}{inflightMessages},
            received => $self->{raw_results}->{$queue->{queueId}}{messagesReceived},
            sent     => $self->{raw_results}->{$queue->{queueId}}{messagesSent},
            visible  => $self->{raw_results}->{$queue->{queueId}}{messagesVisible},
            acked    => $self->{raw_results}->{$queue->{queueId}}{messagesAcked}
        }
    }

    if (scalar(keys %{$self->{queues}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No queues found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Mulesoft Messages Queues (MQ).

Example:
perl centreon_plugins.pl --plugin=apps::mulesoft::restapi::plugin --mode=messages
--environment-id='1234abc-56de-78fg-90hi-1234abcdefg' --organization-id='1234abcd-56ef-78fg-90hi-1234abcdefg'
--api-username='myapiuser' --api-password='myapipassword' --warning-total=900 --critical-total=1000 --verbose

More information on 'https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/anypoint-mq-stats/'.

=over 8

=item B<--filter-name>

Filter by queue name (Regexp can be used).
Example: --filter-name='^mymessagequeue1$'

=item B<--region-id>

Specify the queue region ID (Mandatory).
Example: --region-id='eu-central-1'

=item B<--timeframe>

Specify the time window in seconds on which to collect the data.
Default: 600 (5 min)

=item B<--period>

Specify the data granularity in seconds.
Default: 60 (1 value/minute)


=item B<--warning-*>

Warning threshold for queue messages count, by message type where * can be:
total, inflight, received, sent, visible, acked.

=item B<--critical-*>

Critical threshold for queue messages count, by message type where * can be:
total, inflight, received, sent, visible, acked.

=back

=cut
