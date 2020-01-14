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

package network::libraesva::snmp::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'mails-sent', nlabel => 'system.mails.sent.count', set => {
                key_values => [ { name => 'mailSent', diff => 1 } ],
                output_template => 'mails sent: %s',
                perfdatas => [
                    { value => 'mailSent_absolute', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'mails-received', nlabel => 'system.mails.received.count', set => {
                key_values => [ { name => 'mailReceived', diff => 1 } ],
                output_template => 'mails received: %s',
                perfdatas => [
                    { value => 'mailReceived_absolute', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'mails-rejected', nlabel => 'system.mails.rejected.count', set => {
                key_values => [ { name => 'mailRejected', diff => 1 } ],
                output_template => 'mails rejected: %s',
                perfdatas => [
                    { value => 'mailRejected_absolute', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'mails-bounced', nlabel => 'system.mails.bounced.count', display_ok => 0, set => {
                key_values => [ { name => 'mailBounced', diff => 1 } ],
                output_template => 'mails bounced: %s',
                perfdatas => [
                    { value => 'mailBounced_absolute', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'messages-spam', nlabel => 'system.messages.spam.count', set => {
                key_values => [ { name => 'spamMessages', diff => 1 } ],
                output_template => 'spam messages: %s',
                perfdatas => [
                    { value => 'spamMessages_absolute', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'messages-virus', nlabel => 'system.messages.virus.count', set => {
                key_values => [ { name => 'virusMessages', diff => 1 } ],
                output_template => 'virus messages: %s',
                perfdatas => [
                    { value => 'virusMessages_absolute', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'mails-queue-in', nlabel => 'system.mails.queue.in.count', set => {
                key_values => [ { name => 'incomingMailQueue' } ],
                output_template => 'mails queue in: %s',
                perfdatas => [
                    { value => 'incomingMailQueue_absolute', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'mails-queue-out', nlabel => 'system.mails.queue.ou.count', set => {
                key_values => [ { name => 'outgoingMailQueue' } ],
                output_template => 'mails queue out: %s',
                perfdatas => [
                    { value => 'outgoingMailQueue_absolute', template => '%s', min => 0 },
                ],
            }
        },
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

my $mapping = {
    mailSent          => { oid => '.1.3.6.1.4.1.41091.1.1.1' },
    mailReceived      => { oid => '.1.3.6.1.4.1.41091.1.1.2' },
    mailRejected      => { oid => '.1.3.6.1.4.1.41091.1.1.3' },
    mailBounced       => { oid => '.1.3.6.1.4.1.41091.1.1.4' },
    spamMessages      => { oid => '.1.3.6.1.4.1.41091.1.1.5' },
    virusMessages     => { oid => '.1.3.6.1.4.1.41091.1.1.6' },
    incomingMailQueue => { oid => '.1.3.6.1.4.1.41091.1.1.8' },
    outgoingMailQueue => { oid => '.1.3.6.1.4.1.41091.1.1.9' },
    clusterStatus     => { oid => '.1.3.6.1.4.1.41091.1.1.10' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    $self->{global} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');

    $self->{cache_name} = 'libraesva_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check system usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^mail-sent$'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'mails-sent', 'mails-received', 'mails-rejected', 'mails-bounced',
'mails-queue-in', 'mails-queue-out', 'messages-spam', 'messages-virus', 

=back

=cut
