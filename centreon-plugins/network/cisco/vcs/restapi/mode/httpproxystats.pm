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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Status is '%s'", $self->{result_values}->{status});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_Status'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'connections', type => 0, cb_prefix_output => 'prefix_connections_output' },
        { name => 'requests', type => 0, cb_prefix_output => 'prefix_requests_output' },
        { name => 'responses', type => 0, cb_prefix_output => 'prefix_responses_output' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', set => {
                key_values => [ { name => 'Status' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
    $self->{maps_counters}->{connections} = [
        { label => 'client-connections', set => {
                key_values => [ { name => 'TotalClientConnection', per_second => 1 } ],
                output_template => 'Client: %.2f/s',
                perfdatas => [
                    { label => 'client_connections', template => '%.2f', min => 0, unit => 'connections/s' },
                ],
            }
        },
        { label => 'server-connections', set => {
                key_values => [ { name => 'TotalServerConnection', per_second => 1 } ],
                output_template => 'Server: %.2f/s',
                perfdatas => [
                    { label => 'server_connections', template => '%.2f', min => 0, unit => 'connections/s' },
                ],
            }
        }
    ];

    $self->{maps_counters}->{requests} = [
        { label => 'completed-requests', set => {
                key_values => [ { name => 'CompletedRequests', per_second => 1 } ],
                output_template => 'Completed: %.2f/s',
                perfdatas => [
                    { label => 'completed_requests', template => '%.2f', min => 0, unit => 'requests/s' },
                ],
            }
        },
        { label => 'get-requests', set => {
                key_values => [ { name => 'GetRequests', per_second => 1 } ],
                output_template => 'Get: %.2f/s',
                perfdatas => [
                    { label => 'get_requests', template => '%.2f', min => 0, unit => 'requests/s' },
                ],
            }
        },
        { label => 'post-requests', set => {
                key_values => [ { name => 'PostRequests', per_second => 1 } ],
                output_template => 'Post: %.2f/s',
                perfdatas => [
                    { label => 'post_requests', template => '%.2f', min => 0, unit => 'requests/s' },
                ],
            }
        }
    ];

    $self->{maps_counters}->{responses} = [
        { label => 'responses-1xx', set => {
                key_values => [ { name => 'Response1XXCount', per_second => 1 } ],
                output_template => '1XX: %.2f/s',
                perfdatas => [
                    { label => 'responses_1xx', template => '%.2f', min => 0, unit => 'responses/s' },
                ],
            }
        },
        { label => 'responses-2xx', set => {
                key_values => [ { name => 'Response2XXCount', per_second => 1 } ],
                output_template => '2XX: %.2f/s',
                perfdatas => [
                    { label => 'responses_2xx', template => '%.2f', min => 0, unit => 'responses/s' },
                ],
            }
        },
        { label => 'responses-3xx', set => {
                key_values => [ { name => 'Response3XXCount', per_second => 1 } ],
                output_template => '3XX: %.2f/s',
                perfdatas => [
                    { label => 'responses_3xx', template => '%.2f', min => 0, unit => 'responses/s' },
                ],
            }
        },
        { label => 'responses-4xx', set => {
                key_values => [ { name => 'Response4XXCount', per_second => 1 } ],
                output_template => '4XX: %.2f/s',
                perfdatas => [
                    { label => 'responses_4xx', template => '%.2f', min => 0, unit => 'responses/s' },
                ],
            }
        },
        { label => 'responses-5xx', set => {
                key_values => [ { name => 'Response5XXCount', per_second => 1 } ],
                output_template => '5XX: %.2f/s',
                perfdatas => [
                    { label => 'responses_5xx', template => '%.2f', min => 0, unit => 'responses/s' },
                ],
            }
        },
    ];
}

sub prefix_connections_output {
    my ($self, %options) = @_;

    return "Connections ";
}

sub prefix_requests_output {
    my ($self, %options) = @_;

    return "Resquests ";
}

sub prefix_responses_output {
    my ($self, %options) = @_;

    return "Responses ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'warning-status:s'  => { name => 'warning_status' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} ne "Active"' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->get_endpoint(method => '/Status/HTTPProxy');

    $self->{global} = {};
    $self->{connections} = {};
    $self->{requests} = {};
    $self->{responses} = {};

    $self->{global}->{Status} = $results->{HTTPProxy}->{Status}->{content};
    $self->{connections}->{TotalClientConnection} = $results->{HTTPProxy}->{Stats}->{TotalClientConnection}->{content};
    $self->{connections}->{TotalServerConnection} = $results->{HTTPProxy}->{Stats}->{TotalServerConnection}->{content};
    $self->{requests}->{CompletedRequests} = $results->{HTTPProxy}->{Stats}->{CompletedRequests}->{content};
    $self->{requests}->{GetRequests} = $results->{HTTPProxy}->{Stats}->{GetRequests}->{content};
    $self->{requests}->{PostRequests} = $results->{HTTPProxy}->{Stats}->{PostRequests}->{content};    
    $self->{responses}->{Response1XXCount} = $results->{HTTPProxy}->{Stats}->{Response1XXCount}->{content};
    $self->{responses}->{Response2XXCount} = $results->{HTTPProxy}->{Stats}->{Response2XXCount}->{content};
    $self->{responses}->{Response3XXCount} = $results->{HTTPProxy}->{Stats}->{Response3XXCount}->{content};
    $self->{responses}->{Response4XXCount} = $results->{HTTPProxy}->{Stats}->{Response4XXCount}->{content};
    $self->{responses}->{Response5XXCount} = $results->{HTTPProxy}->{Stats}->{Response5XXCount}->{content};

    $self->{cache_name} = "cisco_vcs_" . $options{custom}->get_hostname() . '_' . $options{custom}->get_port() . '_' . $self->{mode} . '_' .
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

=item B<--warning-*>

Threshold warning (/s).
Can be: 'client-connections', 'server-connections', 'completed-requests',
'get-requests', 'post-requests', 'responses-1xx', 'responses-2xx',
'responses-3xx', 'responses-4xx', 'responses-5xx'.

=item B<--critical-*>

Threshold critical (/s).
Can be: 'client-connections', 'server-connections', 'completed-requests',
'get-requests', 'post-requests', 'responses-1xx', 'responses-2xx',
'responses-3xx', 'responses-4xx', 'responses-5xx'.

=item B<--warning-status>

Set warning threshold for status. (Default: '').
Can use special variables like: %{status}.

=item B<--critical-status>

Set critical threshold for status. (Default: '%{status} ne "Active"').
Can use special variables like: %{status}.

=back

=cut
