#
# Copyright 2026 Centreon (http://www.centreon.com/)
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
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'hostname:s' => { name => 'hostname', default => 'api.euwest1.obs.mycentreon.com' },
            'org:s'      => { name => 'org', default => '' },
            'api-path:s' => { name => 'api_path', default => '/v1/orgs/{org}/datasources/centreon-log/query/metrics' },
            'proto:s'    => { name => 'proto', default => 'https' },
            'token:s'    => { name => 'token', default => '' },
            'timeout:s'  => { name => 'timeout', default => 30 }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;
    $self->{$_} = $self->{option_results}->{$_} for qw/hostname org api_path proto token timeout/;
  
    $self->{output}->option_exit(short_msg => "Need to specify organization option.")
        if $self->{org} eq '';
        
    $self->{output}->option_exit(short_msg => "Need to specify token option.")
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
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{timeout} = $self->{timeout};

    # Note: Authentication header is handled directly in get_log_count method
    # to avoid being overridden by Content-Type header
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_log_count {
    my ($self, %options) = @_;

    $self->settings();

    my $query = $options{query};
    my $period = $options{period};
    my $interval = $options{interval};  # Use the provided interval value

    my $request_body = {
        op => 'count-doc',
        period => $period,
        query => $query,
        version => '1',
        interval => $interval
    };

    # Combine authentication header with content-type header
    my @headers = ("Content-Type: application/json");
    
    # Add authentication header if token is provided
    if (defined($self->{token}) && $self->{token} ne '') {
        push @headers, "X-Api-Key: " . $self->{token};
    }
    
    my $response = $self->{http}->request(
        method => 'POST',
        url_path => $self->{api_path},
        query_form_post => JSON::XS->new->utf8->encode($request_body),
        header => \@headers,
        critical_status => '',
        warning_status => ''
    );

    my $content;
    eval {
        $content = JSON::XS->new->utf8->decode($response);
    };

    $self->{output}->option_exit(exit_litteral => 'critical', short_msg => "Cannot decode json response: $@")
        if $@;

    if (defined($content->{error})) {
        $self->{output}->option_exit(exit_litteral => 'critical',
                                     short_msg => "Cannot get data: " . ($content->{error}->{message} || 'Unknown error'));
    }

    return $content;
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

=item B<--api-path>

API path (default: '/v1/orgs/{org}/datasources/centreon-log/query/metrics').
The {org} placeholder will be replaced with the organization code.

=item B<--proto>

Specify https if needed (default: 'https').

=item B<--token>

Authentication token for Centreon Log Management API. This token is sent in the X-Api-Key header.

=item B<--timeout>

Set HTTP timeout (default: 30).

=back

=head1 DESCRIPTION

B<custom>.

=cut