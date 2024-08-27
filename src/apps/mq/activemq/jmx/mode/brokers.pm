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

package apps::mq::activemq::jmx::mode::brokers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_CurrentStatus'};
    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};

    return 0;
}

sub broker_long_output {
    my ($self, %options) = @_;

    return "checking broker '" . $options{instance} . "'";
}

sub prefix_broker_output {
    my ($self, %options) = @_;

    return "Broker '" . $options{instance} . "' ";
}

sub prefix_queue_output {
    my ($self, %options) = @_;

    return "queue '" . $options{instance} . "' ";
}

sub prefix_topic_output {
    my ($self, %options) = @_;

    return "topic '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'brokers', type => 3, cb_prefix_output => 'prefix_broker_output', cb_long_output => 'broker_long_output', indent_long_output => '    ', message_multiple => 'All brokers are ok',
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'queue', display_long => 1, cb_prefix_output => 'prefix_queue_output',  message_multiple => 'All queues are ok', type => 1, skipped_code => { -10 => 1 } },
                { name => 'topic', display_long => 1, cb_prefix_output => 'prefix_topic_output',  message_multiple => 'All topics are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', type => 2, critical_default => '%{status} !~ /Good/i', set => {
                key_values => [ { name => 'CurrentStatus' }, { name => 'name' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                output_template => 'status: %s',
                output_use => 'status',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'store-usage', nlabel => 'broker.store.usage.percentage', set => {
                key_values => [ { name => 'StorePercentUsage' } ],
                output_template => 'store usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'temporary-usage', nlabel => 'broker.temporary.usage.percentage', set => {
                key_values => [ { name => 'TempPercentUsage' } ],
                output_template => 'temporary usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'memory-usage', nlabel => 'broker.memory.usage.percentage', set => {
                key_values => [ { name => 'MemoryPercentUsage' } ],
                output_template => 'memory usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        }
    ];

    foreach (('queue', 'topic')) {
        $self->{maps_counters}->{$_} = [
            { label => $_ . '-average-enqueue-time', nlabel => 'broker.' . $_ . '.average.enqueue.time.milliseconds', set => {
                    key_values => [ { name => 'AverageEnqueueTime' } ],
                    output_template => 'average time messages remained enqueued: %.3f ms',
                    perfdatas => [
                        { template => '%.3f', unit => 'ms', min => 0, label_extra_instance => 1 }
                    ]
                }
            },
            { label => $_ . '-consumers-connected', nlabel => 'broker.' . $_ . '.consumers.connected.count', set => {
                    key_values => [ { name => 'ConsumerCount' } ],
                    output_template => 'consumers connected: %s',
                    perfdatas => [
                        { template => '%s', min => 0, label_extra_instance => 1 }
                    ]
                }
            },
            { label => $_ . '-producers-connected', nlabel => 'broker.' . $_ . '.producers.connected.count', display_ok => 0, set => {
                    key_values => [ { name => 'ProducerCount' } ],
                    output_template => 'producers connected: %s',
                    perfdatas => [
                        { template => '%s', min => 0, label_extra_instance => 1 }
                    ]
                }
            },
            { label => $_ . '-memory-usage', nlabel => 'broker.' . $_ . '.memory.usage.percentage', display_ok => 0, set => {
                    key_values => [ { name => 'MemoryPercentUsage' } ],
                    output_template => 'memory usage: %.2f %%',
                    perfdatas => [
                        { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                    ]
                }
            },
            { label => $_ . '-size', nlabel => 'broker.' . $_ . '.size.count', set => {
                    key_values => [ { name => 'QueueSize' } ],
                    output_template => 'queue size: %s',
                    perfdatas => [
                        { template => '%s', min => 0, label_extra_instance => 1 }
                    ]
                }
            },
            { label => $_ . '-messages-enqueued', nlabel => 'broker.' . $_ . '.messages.enqueued.count', display_ok => 0, set => {
                    key_values => [ { name => 'EnqueueCount', diff => 1 } ],
                    output_template => 'messages enqueued: %s',
                    perfdatas => [
                        { template => '%s', min => 0, label_extra_instance => 1 }
                    ]
                }
            },
            { label => $_ . '-messages-dequeued', nlabel => 'broker.' . $_ . '.messages.dequeue.count', display_ok => 0, set => {
                    key_values => [ { name => 'DequeueCount', diff => 1 } ],
                    output_template => 'messages dequeued: %s',
                    perfdatas => [
                        { template => '%s', min => 0, label_extra_instance => 1 }
                    ]
                }
            },
            { label => $_ . '-messages-expired', nlabel => 'broker.' . $_ . '.messages.expired.count', display_ok => 0, set => {
                    key_values => [ { name => 'ExpiredCount', diff => 1 } ],
                    output_template => 'messages expired: %s',
                    perfdatas => [
                        { template => '%s', min => 0, label_extra_instance => 1 }
                    ]
                }
            },
            { label => $_ . '-messages-inflighted', nlabel => 'broker.' . $_ . '.messages.inflighted.count', display_ok => 0, set => {
                    key_values => [ { name => 'InFlightCount', diff => 1 } ],
                    output_template => 'messages in-flighted: %s',
                    perfdatas => [
                        { template => '%s', min => 0, label_extra_instance => 1 }
                    ]
                }
            },
            { label => $_ . '-messages-size-average', nlabel => 'broker.' . $_ . '.messages.size.average.bytes', display_ok => 0, set => {
                    key_values => [ { name => 'AverageMessageSize' } ],
                    output_template => 'average messages size: %s %s',
                    output_change_bytes => 1,
                    perfdatas => [
                        { template => '%s', unit => 'B', min => 0, label_extra_instance => 1 }
                    ]
                }
            }
        ];
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-broker-name:s'      => { name => 'filter_broker_name' },
        'filter-destination-name:s' => { name => 'filter_destination_name' },
        'filter-destination-type:s' => { name => 'filter_destination_type' },
        'request:s@'                => { name => 'request' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $request = [
        {
            mbean => 'org.apache.activemq:brokerName=*,destinationName=*,destinationType=*,type=Broker',
            attributes => [
                { name => 'AverageEnqueueTime' }, { name => 'ConsumerCount' }, 
                { name => 'ProducerCount' }, { name => 'MemoryPercentUsage' },
                { name => 'QueueSize' }, { name => 'EnqueueCount' },
                { name => 'DequeueCount' }, { name => 'ExpiredCount' },
                { name => 'InFlightCount' }, { name => 'AverageMessageSize' }
            ]
        },
        {
            mbean => 'org.apache.activemq:brokerName=*,type=Broker',
            attributes => [
                { name => 'StorePercentUsage' }, { name => 'TempPercentUsage' }, 
                { name => 'MemoryPercentUsage' }
            ]
        },
        {
            mbean => 'org.apache.activemq:brokerName=*,type=Broker,service=Health',
            attributes => [
                { name => 'CurrentStatus' }
            ]
        }
    ];

    if (defined($self->{option_results}->{request}) && $self->{option_results}->{request} ne '') {
        centreon::plugins::misc::mymodule_load(
            output => $self->{output}, module => 'JSON::XS',
            error_msg => "Cannot load module 'JSON::XS'."
        );
        $request = undef;
        foreach (@{$self->{option_results}->{request}}) {
            eval {
                push @$request, JSON::XS->new->utf8->decode($_);
            };
            if ($@) {
                $self->{output}->add_option_msg(short_msg => "Cannot use request as it is a malformed JSON: " . $@);
                $self->{output}->option_exit();
            }
        }
    }

    my $result = $options{custom}->get_attributes(request => $request, nothing_quit => 1);

    $self->{cache_name} = 'activemq_' . $self->{mode} . '_' . md5_hex($options{custom}->get_connection_info()) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_broker_name}) ? md5_hex($self->{option_results}->{filter_broker_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_destination_name}) ? md5_hex($self->{option_results}->{filter_destination_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_destination_type}) ? md5_hex($self->{option_results}->{filter_destination_type}) : md5_hex('all'));

    $self->{brokers} = {};
    foreach my $mbean (keys %$result) {
        my ($broker_name, $destination_name, $destination_type);

        $broker_name = $1 if ($mbean =~ /brokerName=(.*?)(?:,|$)/);
        $destination_name = $1 if ($mbean =~ /destinationName=(.*?)(?:,|$)/);
        $destination_type = $1 if ($mbean =~ /destinationType=(.*?)(?:,|$)/);

        if (defined($self->{option_results}->{filter_broker_name}) && $self->{option_results}->{filter_broker_name} ne '' &&
            $broker_name !~ /$self->{option_results}->{filter_broker_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $broker_name . "': no matching filter.", debug => 1);
            next;
        }

        if (!defined($self->{brokers}->{$broker_name})) {
            $self->{brokers}->{$broker_name} = {
                global => { name => $broker_name },
                queue => {},
                topic => {}
            };
        }

        if (defined($destination_name)) {
            my $type = lc($destination_type);
            next if ($type ne 'topic' && $type ne 'queue');

            if (defined($self->{option_results}->{filter_destination_name}) && $self->{option_results}->{filter_destination_name} ne '' &&
                $destination_name !~ /$self->{option_results}->{filter_destination_name}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $destination_name . "': no matching filter.", debug => 1);
                next;
            }
            if (defined($self->{option_results}->{filter_destination_type}) && $self->{option_results}->{filter_destination_type} ne '' &&
                $destination_type !~ /$self->{option_results}->{filter_destination_type}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $broker_name . "': no matching filter.", debug => 1);
                next;
            }

            $self->{brokers}->{$broker_name}->{$type}->{$destination_name} = $result->{$mbean};
        } else {
            foreach (keys %{$result->{$mbean}}) {
                $self->{brokers}->{$broker_name}->{global}->{$_} = $result->{$mbean}->{$_};
            }
        }
    }

    if (scalar(keys %{$self->{brokers}}) <= 0) {
        $self->{output}->output_add(short_msg => 'no brokers found');
    }
}

1;

__END__

=head1 MODE

Check brokers.

=over 8

=item B<--filter-broker-name>

Filter broker name (can be a regexp).

=item B<--filter-destination-name>

Filter destination name (can be a regexp).

=item B<--filter-destination-type>

Filter destination type (can be a regexp).

=item B<--request>

EXPERIMENTAL Option : Community-supported only (no support from Centreon at this time)

Set the MBean and attributes to request (will replace defaults)
in a JSON-formatted fashion.

This is useful to reduce the size of returned data by providing destination
type and name or broker name instead of filtering afterwards, and grabbing
exactly the wanted attributes.

This can be set multiple times.

Example:

--request='{"mbean":"org.apache.activemq:brokerName=*,destinationName=MyQueue,destinationType=Queue,type=Broker","attributes":[{"name":"QueueSize"}]}'
--request='{"mbean":"org.apache.activemq:brokerName=*,type=Broker,service=Health","attributes":[{"name":"CurrentStatus"}]}'

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /Good/i').
You can use the following variables: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'store-usage' (%), 'temporary-usage' (%), 'memory-usage' (%),
'queue-average-enqueue-time' (ms), 'queue-consumers-connected',
'queue-producers-connected', 'queue-memory-usage' (%), 'queue-size',
'queue-messages-enqueued', 'queue-messages-dequeued', 'queue-messages-expired',
'queue-messages-inflighted',
'topic-average-enqueue-time' (ms), 'topic-consumers-connected',
'topic-producers-connected', 'topic-memory-usage' (%), 'topic-size',
'topic-messages-enqueued', 'topic-messages-dequeued', 'topic-messages-expired',
'topic-messages-inflighted'.

=back

=cut
