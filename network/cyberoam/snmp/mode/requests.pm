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

package network::cyberoam::snmp::mode::requests;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'live-users', set => {
                key_values => [ { name => 'live_users' } ],
                output_template => 'live users: %s',
                perfdatas => [
                    { label => 'live_users', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'http-hits', set => {
                key_values => [ { name => 'http_hits', diff => 1 } ],
                output_template => 'http hits: %s',
                perfdatas => [
                    { label => 'http_hits', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'ftp-hits', set => {
                key_values => [ { name => 'ftp_hits', diff => 1 } ],
                output_template => 'ftp hits: %s',
                perfdatas => [
                    { label => 'ftp_hits', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'pop3-hits', set => {
                key_values => [ { name => 'pop3_hits', diff => 1 } ],
                output_template => 'pop3 hits: %s',
                perfdatas => [
                    { label => 'pop3_hits', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'imap-hits', set => {
                key_values => [ { name => 'imap_hits', diff => 1 } ],
                output_template => 'imap hits: %s',
                perfdatas => [
                    { label => 'imap_hits', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'smtp-hits', set => {
                key_values => [ { name => 'smtp_hits', diff => 1 } ],
                output_template => 'smtp hits: %s',
                perfdatas => [
                    { label => 'smtp_hits', template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return 'Requests ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
    });

    return $self;
}

sub add_counters {
    my ($self, %options) = @_;

    return if (!defined($options{result}->{live_users}));

    $self->{global} = { %{$options{result}} };
}

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => 'Need to use SNMP v2c or v3.');
        $self->{output}->option_exit();
    }

    my $mapping = {
        v17 => {
            live_users => { oid => '.1.3.6.1.4.1.21067.2.1.2.6' }, # liveUsers
            http_hits  => { oid => '.1.3.6.1.4.1.21067.2.1.2.7' }, # httpHits
            ftp_hits   => { oid => '.1.3.6.1.4.1.21067.2.1.2.8' }, # ftpHits
            pop3_hits  => { oid => '.1.3.6.1.4.1.21067.2.1.2.9.1' }, # pop3Hits
            imap_hits  => { oid => '.1.3.6.1.4.1.21067.2.1.2.9.2' }, # imapHits
            smtp_hits  => { oid => '.1.3.6.1.4.1.21067.2.1.2.9.3' }  # smtpHits
        },
        v18 => {
            live_users => { oid => '.1.3.6.1.4.1.2604.5.1.2.6' }, # sfosLiveUsersCount
            http_hits  => { oid => '.1.3.6.1.4.1.2604.5.1.2.7' }, # sfosHTTPHits
            ftp_hits   => { oid => '.1.3.6.1.4.1.2604.5.1.2.8' }, # sfosFTPHits
            pop3_hits  => { oid => '.1.3.6.1.4.1.2604.5.1.2.9.1' }, # sfosPOP3Hits
            imap_hits  => { oid => '.1.3.6.1.4.1.2604.5.1.2.9.2' }, # sfosImapHits
            smtp_hits  => { oid => '.1.3.6.1.4.1.2604.5.1.2.9.3' }  # sfosSmtpHits
        }
    };

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%{$mapping->{v17}}), values(%{$mapping->{v18}})) ],
        nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping->{v17}, results => $snmp_result, instance => 0);
    $self->add_counters(result => $result);
    $result = $options{snmp}->map_instance(mapping => $mapping->{v18}, results => $snmp_result, instance => 0);
    $self->add_counters(result => $result);

    $self->{cache_name} = 'cyberoam_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check request statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='http-hits'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: live-users, http-hits, ftp-hits, pop3-hits, imap-hits, smtp-hits.

=back

=cut
