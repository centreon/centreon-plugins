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

package cloud::aws::sqs::mode::queues;

use base qw(cloud::aws::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        extra_params => {
            message_multiple => 'All queues metrics are ok'
        },
        metrics => {
            'ApproximateAgeOfOldestMessage' => {
                output => 'age of oldest message',
                label  => 'messages-oldest-age',
                nlabel => {
                    absolute => 'sqs.queue.messages.oldest.seconds'
                },
                unit => ''
            },
            'ApproximateNumberOfMessagesDelayed' => {
                output => 'delayed messages',
                label  => 'messages-delayed',
                nlabel => {
                    absolute => 'sqs.queue.messages.delayed.count'
                },
                unit => ''
            },
            'ApproximateNumberOfMessagesNotVisible' => {
                output => 'approximate number of messages not visible',
                label  => 'messages-notvisible',
                nlabel => {
                    absolute => 'sqs.queue.messages.notvisible.count'
                },
                unit => ''   
            },
            'ApproximateNumberOfMessagesVisible' => {
                output => 'approximate number of messages visible',
                label  => 'messages-visible',
                nlabel => {
                    absolute => 'sqs.queue.messages.visible.count'
                },
                unit => ''  
            },
            'NumberOfEmptyReceives' => {
                output => 'number of empty receives',
                label  => 'messages-empty-receives',
                nlabel => {
                    absolute => 'sqs.queue.messages.empty.count'
                },
                unit => ''
            },
            'NumberOfMessagesDeleted' => {
                output => 'number of messages deleted',
                label  => 'messages-deleted',
                nlabel => {
                    absolute => 'sqs.queue.messages.deleted.count'
                },
                unit => ''
            },
            'NumberOfMessagesReceived' => {
                output => 'number of messages received',
                label  => 'messages-received',
                nlabel => {
                    absolute => 'sqs.queue.messages.received.count'
                },
                unit => ''
            },
            'NumberOfMessagesSent' => {
                output => 'number of messages sent',
                label  => 'messages-sent',
                nlabel => {
                    absolute => 'sqs.queue.messages.sent.count'
                },
                unit => ''
            }
        }
    };

    return $metrics_mapping;
}


sub prefix_metric_output {
    my ($self, %options) = @_;

    return "'" . $options{instance_value}->{display} . "' ";
}

sub long_output {
    my ($self, %options) = @_;

    return "SQS Queue'" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "queue-name:s@"   => { name => 'queue_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{queue_name}) || $self->{option_results}->{queue_name} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --queue-name option.");
        $self->{output}->option_exit();
    };

    foreach my $instance (@{$self->{option_results}->{queue_name}}) {
        if ($instance ne '') {
            push @{$self->{aws_instance}}, $instance;
        };
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my %metric_results;
    foreach my $instance (@{$self->{aws_instance}}) {
        $metric_results{$instance} = $options{custom}->cloudwatch_get_metrics(
            namespace => 'AWS/SQS',
            dimensions => [ { Name => 'QueueName', Value => $instance } ],
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
                $self->{metrics}->{$instance}->{type} = $self->{option_results}->{type};
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

Check Amazon SQS queues metrics.

Example:
perl centreon_plugins.pl --plugin=cloud::aws::sqs::plugin --custommode=paws --mode=queues --region='eu-west-1'
--queue-name='my_aws_queue_1' --filter-metric='NumberOfMessagesSent' --statistic='average'
--critical-messages-sent='200' --verbose

See 'https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-monitoring-using-cloudwatch.html' for more information.

Default statistic: 'average' / All satistics are valid.

=over 8

=item B<--queue-name>

Set the SQS queue name (required) (can be multiple, one instance per --queue-name option).
Example: --queue-name="myqueue1" --queue-name="myqueue2".

=item B<--filter-metric>

Filter metrics (can be: 'ApproximateAgeOfOldestMessage', 'ApproximateNumberOfMessagesDelayed',
'ApproximateNumberOfMessagesNotVisible', 'ApproximateNumberOfMessagesVisible', 'NumberOfEmptyReceives',
'NumberOfMessagesDeleted', 'NumberOfMessagesReceived', 'NumberOfMessagesSent').
(can be a regexp).

=item B<--warning-*> B<--critical-*>

Warning thresholds (can be 'messages-oldest-age', 'messages-delayed',
'messages-notvisible', 'messages-visible', 'messages-empty-receives',
'messages-deleted', 'messages-received', 'messages-sent').

=back

=cut
