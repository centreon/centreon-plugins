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

package apps::antivirus::mcafee::webgateway::snmp::mode::httpstatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'traffics', type => 0, cb_prefix_output => 'prefix_traffic_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'requests', nlabel => 'http.requests.persecond', set => {
                key_values => [ { name => 'stHttpRequests', per_second => 1 } ],
                output_template => 'HTTP Requests (per sec): %d',
                perfdatas => [
                    { label => 'http_requests', template => '%d', min => 0, unit => 'requests/s' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{traffics} = [
        { label => 'client-to-proxy', nlabel => 'http.traffic.client2proxy.bitspersecond', set => {
                key_values => [ { name => 'stHttpBytesFromClient', per_second => 1 } ],
                output_template => 'from client to proxy: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'http_traffic_client_to_proxy', template => '%d', min => 0, unit => 'b/s' }
                ]
            }
        },
        { label => 'server-to-proxy', nlabel => 'http.traffic.server2proxy.bitspersecond', set => {
                key_values => [ { name => 'stHttpBytesFromServer', per_second => 1 } ],
                output_template => 'from server to proxy: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'http_traffic_server_to_proxy', template => '%d', min => 0, unit => 'b/s' }
                ]
            }
        },
        { label => 'proxy-to-client', nlabel => 'http.traffic.proxy2client.bitspersecond', set => {
                key_values => [ { name => 'stHttpBytesToClient', per_second => 1 } ],
                output_template => 'from proxy to client: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'http_traffic_proxy_to_client', template => '%d', min => 0, unit => 'b/s' }
                ]
            }
        },
        { label => 'proxy-to-server', nlabel => 'http.traffic.proxy2server.bitspersecond', set => {
                key_values => [ { name => 'stHttpBytesToServer', per_second => 1 } ],
                output_template => 'from proxy to server: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'http_traffic_proxy_to_server', template => '%d', min => 0, unit => 'b/s' }
                ]
            }
        }
    ];
}

sub prefix_traffic_output {
    my ($self, %options) = @_;

    return "HTTP Traffic ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $oid_stHttpRequests = '.1.3.6.1.4.1.1230.2.7.2.2.1.0';
my $oid_stHttpBytesFromClient = '.1.3.6.1.4.1.1230.2.7.2.2.3.0';
my $oid_stHttpBytesFromServer = '.1.3.6.1.4.1.1230.2.7.2.2.4.0';
my $oid_stHttpBytesToClient = '.1.3.6.1.4.1.1230.2.7.2.2.5.0';
my $oid_stHttpBytesToServer = '.1.3.6.1.4.1.1230.2.7.2.2.6.0';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'mcafee_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $results = $options{snmp}->get_leef(
        oids => [
            $oid_stHttpRequests, $oid_stHttpBytesFromClient,
            $oid_stHttpBytesFromServer, $oid_stHttpBytesToClient,
            $oid_stHttpBytesToServer
        ], 
        nothing_quit => 1
    );

    $self->{global} = {
        stHttpRequests => $results->{$oid_stHttpRequests}
    };
    $self->{traffics} = {
        stHttpBytesFromClient => $results->{$oid_stHttpBytesFromClient} * 8,
        stHttpBytesFromServer => $results->{$oid_stHttpBytesFromServer} * 8,
        stHttpBytesToClient => $results->{$oid_stHttpBytesToClient} * 8,
        stHttpBytesToServer => $results->{$oid_stHttpBytesToServer} * 8
    };
}

1;

__END__

=head1 MODE

Check HTTP statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
(Example: --filter-counters='^proxy')

=item B<--warning-*>

Threshold warning.
Can be: 'request', 'client-to-proxy', 'server-to-proxy',
'proxy-to-client', 'proxy-to-server'.

=item B<--critical-*>

Threshold critical.
Can be: 'request', 'client-to-proxy', 'server-to-proxy',
'proxy-to-client', 'proxy-to-server'.

=back

=cut
