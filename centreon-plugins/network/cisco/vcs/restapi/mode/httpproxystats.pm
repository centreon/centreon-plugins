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

package network::cisco::vcs::restapi::mode::httpproxystats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "http proxy status is '%s'",
        $self->{result_values}->{status}
    );
}

sub prefix_connections_output {
    my ($self, %options) = @_;

    return 'Connections ';
}

sub prefix_requests_output {
    my ($self, %options) = @_;

    return 'Resquests ';
}

sub prefix_responses_output {
    my ($self, %options) = @_;

    return 'Responses ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'connections', type => 0, cb_prefix_output => 'prefix_connections_output' },
        { name => 'requests', type => 0, cb_prefix_output => 'prefix_requests_output' },
        { name => 'responses', type => 0, cb_prefix_output => 'prefix_responses_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', type => 2, critical_default => '%{status} ne "Active"',set => {
                key_values => [ { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{connections} = [
        { label => 'connections-client', nlabel => 'httproxy.connections.client.persecond', set => {
                key_values => [ { name => 'total_client_connection', per_second => 1 } ],
                output_template => 'client: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 }
                ]
            }
        },
        { label => 'connections-server', nlabel => 'httproxy.connections.server.persecond', set => {
                key_values => [ { name => 'total_server_connection', per_second => 1 } ],
                output_template => 'server: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{requests} = [
        { label => 'requests-completed', nlabel => 'httproxy.requests.completed.persecond', set => {
                key_values => [ { name => 'completed', per_second => 1 } ],
                output_template => 'completed: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 }
                ]
            }
        },
        { label => 'requests-get', nlabel => 'httproxy.requests.get.persecond', set => {
                key_values => [ { name => 'get', per_second => 1 } ],
                output_template => 'get: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 }
                ]
            }
        },
        { label => 'requests-post', nlabel => 'httproxy.requests.post.persecond', set => {
                key_values => [ { name => 'post', per_second => 1 } ],
                output_template => 'post: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{responses} = [
        { label => 'responses-1xx', nlabel => 'httproxy.responses.1xx.persecond', set => {
                key_values => [ { name => 'response1xxx', per_second => 1 } ],
                output_template => '1xx: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 }
                ]
            }
        },
        { label => 'responses-2xx', nlabel => 'httproxy.responses.2xx.persecond', set => {
                key_values => [ { name => 'response2xxx', per_second => 1 } ],
                output_template => '2xx: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 }
                ]
            }
        },
        { label => 'responses-3xx', nlabel => 'httproxy.responses.3xx.persecond', set => {
                key_values => [ { name => 'response3xxx', per_second => 1 } ],
                output_template => '3xx: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 }
                ]
            }
        },
        { label => 'responses-4xx', nlabel => 'httproxy.responses.4xx.persecond', set => {
                key_values => [ { name => 'response4xxx', per_second => 1 } ],
                output_template => '4xx: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 }
                ]
            }
        },
        { label => 'responses-5xx', nlabel => 'httproxy.responses.5xx.persecond', set => {
                key_values => [ { name => 'response5xxx', per_second => 1 } ],
                output_template => '5xx: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 }
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

    my $results = $options{custom}->get_endpoint(
        endpoint => '/getxml?location=/Status/HTTPProxy'
    );

    $self->{global} = {
        status => $results->{HTTPProxy}->{Status}->{content}
    };
    if (defined($results->{HTTPProxy}->{Stats})) {
        $self->{connections} = {
            total_client_connection => $results->{HTTPProxy}->{Stats}->{TotalClientConnection}->{content},
            total_server_connection => $results->{HTTPProxy}->{Stats}->{TotalServerConnection}->{content}
        };
        $self->{requests} = {
            completed => $results->{HTTPProxy}->{Stats}->{CompletedRequests}->{content},
            get => $results->{HTTPProxy}->{Stats}->{GetRequests}->{content},
            post => $results->{HTTPProxy}->{Stats}->{PostRequests}->{content}
        };
        $self->{responses} = {
            response1xxx => $results->{HTTPProxy}->{Stats}->{Response1XXCount}->{content},
            response2xxx => $results->{HTTPProxy}->{Stats}->{Response2XXCount}->{content},
            response3xxx => $results->{HTTPProxy}->{Stats}->{Response3XXCount}->{content},
            response4xxx => $results->{HTTPProxy}->{Stats}->{Response4XXCount}->{content},
            response5xxx => $results->{HTTPProxy}->{Stats}->{Response5XXCount}->{content}
        };
    }

    $self->{cache_name} = 'cisco_vcs_' . $options{custom}->get_hostname() . '_' . $options{custom}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check HTTP proxy status and statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
(Example: --filter-counters='responses')

=item B<--warning-*> B<--critical-*>

Threshold.
Can be: 'connections-client', 'connections-server', 
'requests-completed', 'requests-get', 'requests-post',
'responses-1xx', 'responses-2xx', 'responses-3xx', 'responses-4xx', 'responses-5xx'.

=item B<--warning-status>

Set warning threshold for status.
Can use special variables like: %{status}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} ne "Active"').
Can use special variables like: %{status}.

=back

=cut
