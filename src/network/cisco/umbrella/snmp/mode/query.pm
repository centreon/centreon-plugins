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

package network::cisco::umbrella::snmp::mode::query;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_query_output {
    my ($self, %options) = @_;

    return 'Query rate: ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'query', type => 0, cb_prefix_output => 'prefix_query_output' }
    ];

    $self->{maps_counters}->{query} = [
        { label => '5m', nlabel => 'dns.query.last.5m.persecond.count', set => {
                key_values => [ { name => '5m' } ],
                output_template => '%s/s (5m)',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => '15m', nlabel => 'dns.query.last.15m.persecond.count', set => {
                key_values => [ { name => '15m' } ],
                output_template => '%s/s (15m)',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_dnsQueriesLast5m = '.1.3.6.1.4.1.8072.1.3.2.4.1.2.4.113.112.115.53.1';
    my $oid_dnsQueriesLast15m = '.1.3.6.1.4.1.8072.1.3.2.4.1.2.5.113.112.115.49.53.1';

    my $result = $options{snmp}->get_leef(
        oids => [ $oid_dnsQueriesLast5m, $oid_dnsQueriesLast15m ],
        nothing_quit => 1
    );

    $self->{query} = { 
        '5m' => $result->{$oid_dnsQueriesLast5m},
        '15m' => $result->{$oid_dnsQueriesLast15m}
    };
}

1;

__END__

=head1 MODE

Check number of DNS queries per second over the last 5 and 15 minutes.

=over 8

=item B<--warning-*>

Warning threshold.
Can be: '5m', '15m'.

=item B<--critical-*>

Critical threshold.
Can be: '5m', '15m'.

=back

=cut
