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

package apps::mq::ibmmq::restapi::mode::queues;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

sub custom_oldest_output {
    my ($self, %options) = @_;

    return sprintf(
        'oldest message: %s',
         centreon::plugins::misc::change_seconds(value => $self->{result_values}->{oldest_msg_age})
    );
}

sub qmgr_long_output {
    my ($self, %options) = @_;

    return "checking queue manager '" . $options{instance_value}->{name} . "'";
}

sub prefix_qmgr_output {
    my ($self, %options) = @_;

    return "queue manager '" . $options{instance_value}->{name} . "' ";
}

sub prefix_queue_output {
    my ($self, %options) = @_;

    return "queue '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'qmgr', type => 3, cb_prefix_output => 'prefix_qmgr_output', cb_long_output => 'qmgr_long_output', indent_long_output => '    ', message_multiple => 'All queue managers are ok',
            group => [
                { name => 'queues', display_long => 1, cb_prefix_output => 'prefix_queue_output',  message_multiple => 'queues are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{queues} = [
        { label => 'connections-input', nlabel => 'queue.connections.input.count', set => {
                key_values => [ { name => 'open_input_count' } ],
                output_template => 'current input connections: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'messages-depth', nlabel => 'queue.messages.depth.count', set => {
                key_values => [ { name => 'current_qdepth' }],
                output_template => 'current messages depth: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'message-oldest', nlabel => 'queue.message.oldest.seconds', set => {
                key_values => [ { name => 'oldest_msg_age' } ],
                closure_custom_output => $self->can('custom_oldest_output'),
                closure_custom_perfdata => $self->can('custom_oldest_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'qmgr-name:s'         => { name => 'qmgr_name' },
        'queue-name:s'        => { name => 'queue_name' },
        'filter-qmgr-name:s'  => { name => 'filter_qmgr_name' },
        'filter-queue-name:s' => { name => 'filter_queue_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my @list_qmgr = ();
    if (defined($self->{option_results}->{qmgr_name}) && $self->{option_results}->{qmgr_name} ne '') {
        @list_qmgr = ($self->{option_results}->{qmgr_name});
    } else {
        my $names = $options{custom}->request_api(
            endpoint => '/qmgr/'
        );
        foreach (@{$names->{qmgr}}) {
            push @list_qmgr, $_->{name}; 
        }
    }

    my $found = 0;
    $self->{qmgr} = {};
    foreach my $qmgr_name (@list_qmgr) {
        if (defined($self->{option_results}->{filter_qmgr_name}) && $self->{option_results}->{filter_qmgr_name} ne '' &&
            $qmgr_name !~ /$self->{option_results}->{filter_qmgr_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $qmgr_name . "': no matching filter.", debug => 1);
            next;
        }

        my $endpoint = '/qmgr/' . $qmgr_name . '/queue';
        if (defined($self->{option_results}->{queue_name}) && $self->{option_results}->{queue_name} ne '') {
            $endpoint .= '/' . $self->{option_results}->{queue_name};
        }

        my $queues = $options{custom}->request_api(
            endpoint => $endpoint,
            get_param => ['status=*']
        );
        foreach my $queue (@{$queues->{queue}}) {
            if (defined($self->{option_results}->{filter_queue_name}) && $self->{option_results}->{filter_queue_name} ne '' &&
                $queue->{name} !~ /$self->{option_results}->{filter_queue_name}/) {
                $self->{output}->output_add(long_msg => "skipping  '" . $queue->{name} . "': no matching filter.", debug => 1);
                next;
            }

            unless (defined($self->{qmgr}->{$qmgr_name})) {
                $self->{qmgr}->{$qmgr_name} = {
                    name => $qmgr_name,
                    queues => {}
                };
            }

            $self->{qmgr}->{$qmgr_name}->{queues}->{ $queue->{name} } = {
                name => $queue->{name},
                open_input_count => $queue->{status}->{openInputCount},
                current_qdepth => $queue->{status}->{currentDepth},
                oldest_msg_age => $queue->{status}->{oldestMessageAge}
            };
            $found = 1;
        }
    }

    unless ($found) {
        $self->{output}->add_option_msg(short_msg => 'No queue found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check queues.

=over 8

=item B<--qmgr-name>

Check exact queue manager.

=item B<--queue-name>

Check exact queue.

=item B<--filter-qmgr-name>

Filter queue managers by name (can be a regexp).

=item B<--filter-queue-name>

Filter queues by name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'connections-input', 'messages-depth', 'message-oldest'.

=back

=cut
