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

package cloud::aws::sns::mode::notifications;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my %metrics_mapping = (
    'NumberOfMessagesPublished' => {
        'output' => 'number of notifications published',
        'label'  => 'notifications-published',
        'nlabel' => 'sns.notifications.published.count',
    },
    'NumberOfNotificationsDelivered' => {
        'output' => 'number of notifications delivered',
        'label'  => 'notifications-delivered',
        'nlabel' => 'sns.notifications.delivered.count',
    },
    'NumberOfNotificationsFailed' => {
        'output' => 'number of notifications failed',
        'label'  => 'notifications-failed',
        'nlabel' => 'sns.notifications.failed.count',
    },
    'NumberOfNotificationsFilteredOut' => {
        'output' => 'number of notifications filtered',
        'label'  => 'notifications-filtered',
        'nlabel' => 'sns.notifications.filtered.count',
    }
);


sub prefix_metric_output {
    my ($self, %options) = @_;

    return "'" . $options{instance_value}->{display} . "' ";
}

sub prefix_statistics_output {
    my ($self, %options) = @_;

    return "Statistic '" . $options{instance_value}->{display} . "' ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Notifications for topic '" . $options{instance_value}->{display} . "' :";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'metrics', type => 3, cb_prefix_output => 'prefix_metric_output', cb_long_output => 'long_output',
          message_multiple => 'All SNS metrics are ok', indent_long_output => '    ',
            group => [
                { name => 'statistics', display_long => 1, cb_prefix_output => 'prefix_statistics_output',
                  message_multiple => 'All metrics are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    foreach my $metric (keys %metrics_mapping) {
        my $entry = {
            label => $metrics_mapping{$metric}->{label},
            nlabel => $metrics_mapping{$metric}->{nlabel},
            set => {
                key_values => [ { name => $metric }, { name => 'display' } ],
                output_template => $metrics_mapping{$metric}->{output} . ': %d',
                perfdatas => [
                    { value => $metric, template => '%d', label_extra_instance => 1 }
                ],
            }
        };
        push @{$self->{maps_counters}->{statistics}}, $entry;
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "topic-name:s"    => { name => 'topic_name' },
        "filter-metric:s" => { name => 'filter_metric' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{aws_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 600;
    $self->{aws_period} = defined($self->{option_results}->{period}) ? $self->{option_results}->{period} : 60;

    $self->{aws_statistics} = ['Sum'];
    if (defined($self->{option_results}->{statistic})) {
        $self->{aws_statistics} = [];
        foreach my $stat (@{$self->{option_results}->{statistic}}) {
            if ($stat ne '') {
                push @{$self->{aws_statistics}}, ucfirst(lc($stat));
            }
        }
    };
    foreach my $metric (keys %metrics_mapping) {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);
        push @{$self->{aws_metrics}}, $metric;
    };
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{topics} = $options{custom}->sns_list_topics();
    foreach my $topic (@{$self->{topics}}) {
        next if (defined($self->{option_results}->{topic_name})
                && $self->{option_results}->{topic_name} ne ''
                && $topic->{name} !~ /$self->{option_results}->{topic_name}/ );

        $topic->{name} =~ s/(.*)\://g;
        push @{$self->{aws_instance}}, $topic->{name};
    };

    my %metric_results;
    foreach my $instance (@{$self->{aws_instance}}) {
        $metric_results{$instance} = $options{custom}->cloudwatch_get_metrics(
            namespace => 'AWS/SNS',
            dimensions => [ { Name => 'TopicName', Value => $instance } ],
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

Check Amazon SNS notifications statistics.

Example:
perl centreon_plugins.pl --plugin=cloud::aws::sns::plugin --custommode=paws --mode=notifications --region='eu-west-1'
--topic-name='my_sns_topic_1' --filter-metric='NumberOfNotificationsFailed' --statistic='sum'
--critical-messages-sent='200' --verbose

See 'https://docs.aws.amazon.com/sns/latest/dg/sns-monitoring-using-cloudwatch.html' for more information.

Default statistic: 'sum' / Valid statistics are: sum, average.

=over 8

=item B<--topic-name>

Filter on a specific SNS topic (Can be multiple, one instance per --topic-name option).
Example: --topic-name="my_sns_topic_1" --topic-name="my_sns_topic_2".

=item B<--filter-metric>

Filter metrics (Can be: 'NumberOfMessagesPublished', 'NumberOfNotificationsDelivered',
'NumberOfNotificationsFailed', 'NumberOfNotificationsFilteredOut').
(Can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds warning (Can be 'notifications-published', 'notifications-delivered',
'notifications-failed', 'notifications-filtered).

=back

=cut
