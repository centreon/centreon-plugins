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

package apps::mq::rabbitmq::restapi::mode::systemusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'queue-msg', nlabel => 'system.queue.messages.count', set => {
                key_values => [ { name => 'queue_messages' } ],
                output_template => 'current queue messages : %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'queue-msg-ready', nlabel => 'system.queue.messages.ready.count', set => {
                key_values => [ { name => 'queue_messages_ready' } ],
                output_template => 'current queue messages ready : %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'db-event-queue', nlabel => 'system.db.event.queue.count', set => {
                key_values => [ { name => 'db_event_queue' } ],
                output_template => 'db event queue : %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'disk-read-iops', nlabel => 'system.disk.read.usage.iops', set => {
                key_values => [ { name => 'disk_reads', per_second => 1 } ],
                output_template => 'disk reads iops : %s',
                perfdatas => [
                    { template => '%d', unit => 'iops', min => 0 }
                ]
            }
        },
        { label => 'disk-write-iops', nlabel => 'system.disk.write.usage.iops', set => {
                key_values => [ { name => 'disk_writes', per_second => 1 } ],
                output_template => 'disk writes iops : %s',
                perfdatas => [
                    { template => '%d', unit => 'iops', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->query(url_path => '/api/overview');
    $self->{global} = {
        disk_reads => $result->{message_stats}->{disk_reads},
        disk_writes => $result->{message_stats}->{disk_writes},
        queue_messages_ready => $result->{queue_totals}->{messages_ready},
        queue_messages => $result->{queue_totals}->{messages},
        db_event_queue => $result->{statistics_db_event_queue},
    };

    $self->{cache_name} = "rabbitmq_" . $self->{mode} . '_' . $options{custom}->get_hostname() . '_' . $options{custom}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check global system statistics

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'disk-read-iops', 'disk-write-iops',
'queue-msg-ready', 'queue-msg', 'db-event-queue'.

=back

=cut
