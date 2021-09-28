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

package apps::antivirus::mcafee::webgateway::snmp::mode::connections;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_connection_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'legitimate', nlabel => 'connections.legitimate.persecond', set => {
                key_values => [ { name => 'stConnectionsLegitimate', per_second => 1 } ],
                output_template => 'Legitimate: %d',
                perfdatas => [
                    { label => 'legitimate_connections', template => '%d', min => 0, unit => 'connections/s' }
                ]
            }
        },
        { label => 'blocked', nlabel => 'connections.blocked.persecond', set => {
                key_values => [ { name => 'stConnectionsBlocked', per_second => 1 } ],
                output_template => 'Blocked: %d',
                perfdatas => [
                    { label => 'blocked_connections', template => '%d', min => 0, unit => 'connections/s' }
                ]
            }
        },
        { label => 'blocked-by-am', nlabel => 'connections.antimalware.blocked.persecond', set => {
                key_values => [ { name => 'stBlockedByAntiMalware', per_second => 1 } ],
                output_template => 'Blocked by Anti Malware: %d',
                perfdatas => [
                    { label => 'blocked_by_am', template => '%d', min => 0, unit => 'connections/s' }
                ]
            }
        },
        { label => 'blocked-by-mf',  nlabel => 'connections.mediafilter.blocked.persecond', set => {
                key_values => [ { name => 'stBlockedByMediaFilter', per_second => 1 } ],
                output_template => 'Blocked by Media Filter: %d',
                perfdatas => [
                    { label => 'blocked_by_mf', template => '%d', min => 0, unit => 'connections/s' }
                ]
            }
        },
        { label => 'blocked-by-uf',  nlabel => 'connections.urlfilter.blocked.persecond', set => {
                key_values => [ { name => 'stBlockedByURLFilter', per_second => 1 } ],
                output_template => 'Blocked by URL Filter: %d',
                perfdatas => [
                    { label => 'blocked_by_uf', template => '%d', min => 0, unit => 'connections/s' }
                ]
            }
        }
    ];
}

sub prefix_connection_output {
    my ($self, %options) = @_;

    return 'Connections (per sec) ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $oid_stConnectionsLegitimate = '.1.3.6.1.4.1.1230.2.7.2.1.3.0';
my $oid_stBlockedByAntiMalware = '.1.3.6.1.4.1.1230.2.7.2.1.4.0';
my $oid_stConnectionsBlocked = '.1.3.6.1.4.1.1230.2.7.2.1.5.0';
my $oid_stBlockedByMediaFilter = '.1.3.6.1.4.1.1230.2.7.2.1.6.0';
my $oid_stBlockedByURLFilter = '.1.3.6.1.4.1.1230.2.7.2.1.7.0';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'mcafee_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $results = $options{snmp}->get_leef(
        oids => [
            $oid_stConnectionsLegitimate, $oid_stBlockedByAntiMalware,
            $oid_stConnectionsBlocked, $oid_stBlockedByMediaFilter,
            $oid_stBlockedByURLFilter
        ],
        nothing_quit => 1
    );

    $self->{global} = {
        stConnectionsLegitimate => $results->{$oid_stConnectionsLegitimate},
        stBlockedByAntiMalware => $results->{$oid_stBlockedByAntiMalware},
        stConnectionsBlocked => $results->{$oid_stConnectionsBlocked},
        stBlockedByMediaFilter => $results->{$oid_stBlockedByMediaFilter},
        stBlockedByURLFilter => $results->{$oid_stBlockedByURLFilter},
    };
}

1;

__END__

=head1 MODE

Check connections statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
(Example: --filter-counters='blocked')

=item B<--warning-*>

Threshold warning.
Can be: 'legitimate', 'blocked', 'blocked-by-am',
'blocked-by-mf', 'blocked-by-uf'.

=item B<--critical-*>

Threshold critical.
Can be: 'legitimate', 'blocked', 'blocked-by-am',
'blocked-by-mf', 'blocked-by-uf'.

=back

=cut
