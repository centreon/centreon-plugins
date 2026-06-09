#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::centreon::logmanagement::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::misc qw(json_decode json_encode value_of);

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    $options{output}->option_exit(short_msg => "Class Custom: Need to specify 'options' argument.")
        unless defined($options{options});
    
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'hostname:s' => { name => 'hostname', default => 'api.euwest1.obs.mycentreon.com' },
            'org:s'      => { name => 'org', default => '' },
            'port:i'     => { name => 'port', default => '443', greater_than => 0, less_than => 65536 },
            'proto:s'    => { name => 'proto', default => 'https', regexp_match => '^http[s]?$' },
            'token:s'    => { name => 'token', default => '' },
            'timeout:s'  => { name => 'timeout', default => 30 },
            'unknown-http-status:s' => { name => 'unknown_http_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
            'warning-http-status:s' => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' },
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->{$_} = $self->{option_results}->{$_} for qw/hostname org api_path proto port token timeout/;
  
    $self->{output}->option_exit(short_msg => "Need to specify --org option.")
        if $self->{org} eq '';
        
    $self->{output}->option_exit(short_msg => "Need to specify --token option.")
        if $self->{token} eq '';
        
    # Replace {org} placeholder in api_path with actual organization
    if (defined($self->{api_path}) && $self->{api_path} =~ /\{org\}/) {
        $self->{api_path} =~ s/\{org\}/$self->{org}/g;
    }

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{port}     = $self->{port};
    $self->{option_results}->{proto}    = $self->{proto};
    $self->{option_results}->{timeout}  = $self->{timeout};

    # Note: Authentication header is handled directly in get_log_count method
    # to avoid being overridden by Content-Type header
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_alert_events {
    my ($self, %options) = @_;

    $self->settings();

    my $query    = $options{query};
    my $period   = $options{period};
    my $interval = $options{interval}; # Use the provided interval value

    # Combine authentication header with content-type header
    my @headers = ("Content-Type: application/json");

    # Add authentication header if token is provided
    push @headers, "X-Api-Key: " . $self->{token}
        if $self->{token};

    # statuses must be given as an array of strings (as a string). Eg: '["ok","critical"]'
    my $accepted_statuses = "[]";
    $accepted_statuses = '["' . join('","', @{$options{accepted_statuses}}) . '"]'
        if $options{accepted_statuses} && ref $options{accepted_statuses} eq 'ARRAY' && @{$options{accepted_statuses}};

    my $full_response = [];

    my $page = 1;
    my $limit = 50;
    my $total;
    while (1) {
        my $json_response = $self->{http}->request(
            method          => 'GET',
            proto           => $self->{proto},
            port            => $self->{port},
            url_path        => '/v1/orgs/' . $self->{org} . '/alerts/events',
            get_param       => [
                'limit=' . $limit,
                'page=' . $page,
                'status=' . $accepted_statuses
            ],
            header          => \@headers,
            unknown_status  => '',
            warning_status  => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );

        my $response = json_decode($json_response, output => $self->{output});

        $self->{output}->option_exit(short_msg => $response->{message})
            if $response->{message};
        $self->{output}->option_exit(short_msg => "No result array in response: " . $json_response)
            unless ref $response->{results} eq 'ARRAY';

        push @$full_response, @{$response->{results}};

        $total = value_of($response, '->{meta}->{total}', 0);
        last if @$full_response == $total;
        $page++;
    }

    return $full_response;
}

sub get_log_count {
    my ($self, %options) = @_;

    $self->settings();

    my $query    = $options{query};
    my $period   = $options{period};
    my $interval = $options{interval}; # Use the provided interval value

    my $request_body = {
        op       => 'count-doc',
        period   => int($period),
        query    => $query,
        version  => '1',
        interval => int($interval)
    };

    # Combine authentication header with content-type header
    my @headers = ("Content-Type: application/json");

    # Add authentication header if token is provided
    push @headers, "X-Api-Key: " . $self->{token}
        if $self->{token};

    my $response = $self->{http}->request(
        method          => 'POST',
        proto           => $self->{proto},
        port            => $self->{port},
        url_path        => '/v1/orgs/' . $self->{org} .'/datasources/centreon-log/query/metrics',
        query_form_post => json_encode($request_body, output => $self->{output}),
        header          => \@headers,
        unknown_status => $self->{unknown_http_status},
        warning_status => $self->{warning_http_status},
        critical_status => $self->{critical_http_status}
    );

    $response = json_decode($response, output => $self->{output});
    $self->{output}->option_exit(short_msg => $response->{message}) if $response->{message};

    return $response;
}

1;

__END__

=head1 NAME

Centreon Log Management REST API

=head1 SYNOPSIS

Centreon Log Management Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Centreon Log Management hostname.

=item B<--org>

Organization code.

=item B<--proto>

Specify https if needed (default: 'https').

=item B<--port>

Specify TCP port if needed (default: 443).

=item B<--token>

Authentication token for Centreon Log Management API. This token is sent in the C<X-Api-Key> header.

=item B<--timeout>

Set HTTP timeout (default: 30).

=item B<--unknown-http-status>

Threshold for unknown HTTP status (default: '%{http_code} < 200 or %{http_code} >= 300').

=item B<--warning-http-status>

Threshold for warning HTTP status.

=item B<--critical-http-status>

Threshold for critical HTTP status.

=back

=head1 DESCRIPTION

B<custom>.

=cut
