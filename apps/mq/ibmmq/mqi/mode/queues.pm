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

package apps::mq::ibmmq::mqi::mode::queues;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use  centreon::plugins::misc;

sub custom_oldest_output {
    my ($self, %options) = @_;

    return sprintf(
        'oldest message: %s',
         centreon::plugins::misc::change_seconds(value => $self->{result_values}->{oldest_msg_age})
    );
}

sub custom_connections_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => [$self->{result_values}->{qmgr_name}, $self->{result_values}->{queue_name}],
        value => $self->{result_values}->{open_input_count},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_qdepth_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => [$self->{result_values}->{qmgr_name}, $self->{result_values}->{queue_name}],
        value => $self->{result_values}->{current_qdepth},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_oldest_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => [$self->{result_values}->{qmgr_name}, $self->{result_values}->{queue_name}],
        value => $self->{result_values}->{oldest_msg_age},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub prefix_queue_output {
    my ($self, %options) = @_;

    return "Queue '" . $options{instance_value}->{qmgr_name} . ':' . $options{instance_value}->{queue_name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'queue', type => 1, cb_prefix_output => 'prefix_queue_output', message_multiple => 'All queues are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{queue} = [
        { label => 'connections-input', nlabel => 'queue.connections.input.count', set => {
                key_values => [ { name => 'open_input_count' }, { name => 'qmgr_name' }, { name => 'queue_name' } ],
                output_template => 'current input connections: %s',
                closure_custom_perfdata => $self->can('custom_connections_perfdata')
            }
        },
        { label => 'messages-depth', nlabel => 'queue.messages.depth.count', set => {
                key_values => [ { name => 'current_qdepth' }, { name => 'qmgr_name' }, { name => 'queue_name' } ],
                output_template => 'current messages depth: %s',
                closure_custom_perfdata => $self->can('custom_qdepth_perfdata')
            }
        },
        { label => 'message-oldest', nlabel => 'queue.message.oldest.seconds', set => {
                key_values => [ { name => 'oldest_msg_age' }, { name => 'qmgr_name' }, { name => 'queue_name' } ],
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
        'filter-name:s' => { name => 'filter_name' }
    });
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->execute_command(
        command => 'InquireQueueStatus',
        attrs => { QStatusAttrs => ['QName', 'CurrentQDepth', 'OpenInputCount', 'OldestMsgAge'] }
    );

    $self->{queue} = {};
    foreach (@$result) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' 
            && $_->{QName} !~ /$self->{option_results}->{filter_name}/);

        $self->{queue}->{$_->{QName}} = {
            qmgr_name => $options{custom}->get_qmgr_name(),
            queue_name => $_->{QName},
            open_input_count => $_->{OpenInputCount},
            current_qdepth => $_->{CurrentQDepth},
            oldest_msg_age => $_->{OldestMsgAge} # in seconds
        };
    }

    if (scalar(keys %{$self->{queue}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No queue found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check queues.

=over 8

=item B<--filter-name>

Filter queue name (Can use regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'connections-input', 'messages-depth', 'message-oldest'.

=back

=cut
