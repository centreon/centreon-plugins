#
# Copyright 2018 Centreon (http://www.centreon.com/)
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
        { name => 'global', type => 0, cb_prefix_output => 'prefix_connection_output' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'legitimate', set => {
                key_values => [ { name => 'stConnectionsLegitimate', diff => 1 } ],
                output_template => 'Legitimate: %d',
                per_second => 1,
                perfdatas => [
                    { label => 'legitimate_connections', value => 'stConnectionsLegitimate_per_second', template => '%d',
                      min => 0, unit => 'connections/s' },
                ],
            }
        },
        { label => 'blocked', set => {
                key_values => [ { name => 'stConnectionsBlocked', diff => 1 } ],
                output_template => 'Blocked: %d',
                per_second => 1,
                perfdatas => [
                    { label => 'blocked_connections', value => 'stConnectionsBlocked_per_second', template => '%d',
                      min => 0, unit => 'connections/s' },
                ],
            }
        },
        { label => 'blocked-by-am', set => {
                key_values => [ { name => 'stBlockedByAntiMalware', diff => 1 } ],
                output_template => 'Blocked by Anti Malware: %d',
                per_second => 1,
                perfdatas => [
                    { label => 'blocked_by_am', value => 'stBlockedByAntiMalware_per_second', template => '%d',
                      min => 0, unit => 'connections/s' },
                ],
            }
        },
        { label => 'blocked-by-mf', set => {
                key_values => [ { name => 'stBlockedByMediaFilter', diff => 1 } ],
                output_template => 'Blocked by Media Filter: %d',
                per_second => 1,
                perfdatas => [
                    { label => 'blocked_by_mf', value => 'stBlockedByMediaFilter_per_second', template => '%d',
                      min => 0, unit => 'connections/s' },
                ],
            }
        },
        { label => 'blocked-by-uf', set => {
                key_values => [ { name => 'stBlockedByURLFilter', diff => 1 } ],
                output_template => 'Blocked by URL Filter: %d',
                per_second => 1,
                perfdatas => [
                    { label => 'blocked_by_uf', value => 'stBlockedByURLFilter_per_second', template => '%d',
                      min => 0, unit => 'connections/s' },
                ],
            }
        },
    ];
}

sub prefix_connection_output {
    my ($self, %options) = @_;

    return "Connections (per sec) ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                    "filter-counters:s" => { name => 'filter_counters', default => '' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

my $oid_stConnectionsLegitimate = '.1.3.6.1.4.1.1230.2.7.2.1.3.0';
my $oid_stBlockedByAntiMalware = '.1.3.6.1.4.1.1230.2.7.2.1.4.0';
my $oid_stConnectionsBlocked = '.1.3.6.1.4.1.1230.2.7.2.1.5.0';
my $oid_stBlockedByMediaFilter = '.1.3.6.1.4.1.1230.2.7.2.1.6.0';
my $oid_stBlockedByURLFilter = '.1.3.6.1.4.1.1230.2.7.2.1.7.0';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "mcafee_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $results = $options{snmp}->get_leef(oids => [ $oid_stConnectionsLegitimate, $oid_stBlockedByAntiMalware,
                                                     $oid_stConnectionsBlocked, $oid_stBlockedByMediaFilter,
                                                     $oid_stBlockedByURLFilter ], 
                                               nothing_quit => 1);
    
    $self->{global} = {};

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
