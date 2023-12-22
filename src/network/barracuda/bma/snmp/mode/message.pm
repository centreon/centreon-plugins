#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package network::barracuda::bma::snmp::mode::message;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'queued-message', nlabel => 'message.queued.count', set => {
                key_values => [ { name => 'indexQueueLength' } ],
                output_template => 'Number of messages in queue: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'last-archived-message', nlabel => 'message.archived.last.second', set => {
                key_values => [ { name => 'last_message_archived_seconds' }, { name => 'last_message_archived_human' } ],
                output_template => 'Last message archived %s ago',
                output_use => 'last_message_archived_human',
                threshold_use => 'last_message_archived_seconds',
                perfdatas => [
                    { template => '%s', min => 0, unit => 's' }
                ]
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_indexQueueLength = '.1.3.6.1.4.1.20632.6.6.8'; # indexQueueLength
    my $oid_lastMessageArchived = '.1.3.6.1.4.1.20632.6.6.9'; # lastMessageArchived

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ $oid_indexQueueLength, $oid_lastMessageArchived ],
        nothing_quit => 1
    );

    # 2023-12-22 12:59:53Z
    my $tz = centreon::plugins::misc::set_timezone(name => 'UTC');
    $snmp_result->{$oid_lastMessageArchived} =~ /^(\d{4})-(\d{2})-(\d{2})\s+(\d+):(\d+):(\d+)Z/;
    my $dt = DateTime->new(
        year       => $1,
        month      => $2,
        day        => $3,
        hour       => $4,
        minute     => $5,
        second     => $6,
        %$tz
    );
    my $last_message_archived_seconds = time() - $dt->epoch;
    my $last_message_archived_human = centreon::plugins::misc::change_seconds(value => $last_message_archived_seconds);

    $self->{global} = {
        indexQueueLength => $snmp_result->{$oid_indexQueueLength},
        last_message_archived_seconds => $last_message_archived_seconds,
        last_message_archived_human => $last_message_archived_human
    };
}

1;

__END__

=head1 MODE

Check messages queued and archived.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'queued-message', 'last-archived-message' (s)

=back

=cut
