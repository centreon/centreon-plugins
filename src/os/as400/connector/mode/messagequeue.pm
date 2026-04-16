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

package os::as400::connector::mode::messagequeue;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_jobs_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => $self->{result_values}->{mq_path},
        value => $self->{result_values}->{total},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 }  }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'messages', nlabel => 'mq.messages.count', set => {
                key_values => [ { name => 'total' }, { name => 'mq_path' } ],
                output_template => 'number of messages: %s',
                closure_custom_perfdata => $self->can('custom_jobs_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, ); #force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'message-queue-path:s'   => { name => 'message_queue_path' },
        'memory'                 => { name => 'memory' },
        'include-message-id:s'   => { name => 'include_message_id',   default => '' },
        'filter-message-id:s'    => { redirect => 'include_message_id' },       # for compatibility
        'include-reply-status:s' => { name => 'include_reply_status', default => '' },
        'exclude-reply-status:s' => { name => 'exclude_reply_status', default => 'A' },
        'include-text:s'         => { name => 'include_text',         default => '' },
        'exclude-text:s'         => { name => 'exclude_text',         default => '' },
        'min-severity:s'         => { name => 'min_severity',         default => '' },
        'max-severity:s'         => { name => 'max_severity',         default => '' },
        'display-messages'       => { name => 'display_messages' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{message_queue_path}) || $self->{option_results}->{message_queue_path} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --message-queue-path option.');
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my %cmd = (command => 'getErrorMessageQueue', args => { messageQueuePath => $self->{option_results}->{message_queue_path} });
    $cmd{args}->{messageIdfilterPattern} = $self->{option_results}->{include_message_id}
        if $self->{option_results}->{include_message_id} ne '';
    $cmd{args}->{minSeverityLevel} = $self->{option_results}->{min_severity}
        if $self->{option_results}->{min_severity} ne '';
    $cmd{args}->{maxSeverityLevel} = $self->{option_results}->{max_severity}
        if $self->{option_results}->{max_severity} ne '';
    $cmd{command} = 'getNewMessageInMessageQueue'
        if defined($self->{option_results}->{memory});

    $self->{global} = { total => 0, mq_path => $self->{option_results}->{message_queue_path} };
    my $messages = $options{custom}->request_api(%cmd);
    if (defined($self->{option_results}->{memory}) && defined($messages->{message})) {
        $self->{output}->output_add(short_msg => $messages->{message});
        $self->{output}->display();
        $self->{output}->exit();
    }

    foreach my $entry (@{$messages->{result}}) {
        # compatibility with old as400 daemon version who does not return 'replyStatus'
        $entry->{replyStatus} //= '';

        next if $self->{option_results}->{include_reply_status} ne '' && $entry->{replyStatus} !~ /$self->{option_results}->{include_reply_status}/;
        next if $self->{option_results}->{exclude_reply_status} ne '' && $entry->{replyStatus} =~ /$self->{option_results}->{exclude_reply_status}/;
        next if $self->{option_results}->{include_text} ne '' && $entry->{text} !~ /$self->{option_results}->{include_text}/;
        next if $self->{option_results}->{exclude_text} ne '' && $entry->{text} =~ /$self->{option_results}->{exclude_text}/;

        if (defined($self->{option_results}->{display_messages})) {
            $entry->{text} =~ s/\|/ /g;
            $self->{output}->output_add(
                long_msg => sprintf(
                    'message [id: %s] [severity: %s] [date: %s] [user: %s]%s: %s',
                    $entry->{id},
                    $entry->{severity},
                    scalar(localtime($entry->{date} / 1000)),
                    defined($entry->{user}) ? $entry->{user} : '-',
                    $entry->{replyStatus} ne '' ? ' [replyStatus: ' . $entry->{replyStatus} . ']': '',
                    $entry->{text}
                )
            );
        }

        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check message queue.

=over 8

=item B<--message-queue-path>

Specify the message queue (required. Example: --message-queue-path='/QSYS.LIB/QSYSOPR.MSGQ').

=item B<--memory>

Check only new messages.

=item B<--include-message-id>

Filter messages by ID (can be a regexp).

=item B<--include-reply-status>

Filter messages by reply status (can be a regexp).

=item B<--exclude-reply-status>

Exclude messages by reply status (can be a regexp) (default: 'A').

=item B<--include-text>

Filter messages by text (can be a regexp).

=item B<--exclude-text>

Exclude messages by text (can be a regexp).

=item B<--min-severity>

Filter messages with severity greater than or equal to X.

=item B<--max-severity>

Filter messages with severity less than to X.

=item B<--display-messages>

Display messages in verbose output.

=item B<--warning-messages>

Thresholds.

=item B<--critical-messages>

Thresholds.

=back

=cut
