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

package apps::monitoring::iplabel::ekara::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);

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
            'api-key:s'            => { name => 'api_key', default => '' },
            'api-username:s'       => { name => 'api_username', default => '' },
            'api-password:s'       => { name => 'api_password', default => '' },
            'hostname:s'           => { name => 'hostname', default => 'api.ekara.ip-label.net' },
            'port:s'               => { name => 'port', default => 443 },
            'proto:s'              => { name => 'proto', default => 'https' },
            'timeout:s'            => { name => 'timeout', default => 10 },
            'url-path:s'           => { name => 'url_path', default => '' },
            'filter-id:s'          => { name => 'filter_id' },
            'filter-name:s'        => { name => 'filter_name' },
            'filter-workspaceid:s' => { name => 'filter_workspaceid' },
            'filter-siteid:s'      => { name => 'filter_siteid' },
            'filter-status:s@'     => { name => 'filter_status' },
            'authent-endpoint'     => { name => 'authent_endpoint', default => '/auth/login' },
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
    $self->{cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;
    use Data::Dumper;
    $self->{unknown_http_status} = $self->{option_results}->{unknown_http_status} // '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = $self->{option_results}->{warning_http_status} // '';
    $self->{critical_http_status} = $self->{option_results}->{critical_http_status} // '';

    $self->{$_} = $self->{option_results}->{$_} for qw/api_key api_password api_username authent_endpoint hostname port proto timeout url_path/;

    $self->{cache}->check_options(option_results => $self->{option_results});

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }

    # Ekara REST API support two authentication modes: API key or username/password
    # Both modes cannot be used simultaneously
    if (($self->{api_username} ne '' || $self->{api_password} ne '') && $self->{api_key} ne '') {
        $self->{output}->add_option_msg(short_msg => "Cannot use both --api-key and --api-username/--api-password options.");
        $self->{output}->option_exit();
    }

    if ($self->{api_key} eq '') {
        # username/password required if api_key is not set
        foreach (qw/api_username api_password/) {
            if ($self->{option_results}->{$_} eq '') {
                $self->{output}->add_option_msg(short_msg => "Need to specify --api-key or --api-username/--api-password options.");
                $self->{output}->option_exit();
            }
        }
        # authent_endpoint is required if username/password authentication mode is used
        if ($self->{authent_endpoint} eq '') {
            $self->{output}->add_option_msg(short_msg => "Need to specify --authent-endpoint option.");
            $self->{output}->option_exit();
        }
    }

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
    $self->{option_results}->{unknown_status} = '%{http_code} < 200 or %{http_code} >= 500';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    if ($self->{api_key} ne '') {
        $self->{http}->add_header(key => 'X-API-KEY', value => $self->{api_key});
    } elsif ($self->{access_token}) {
        $self->{http}->add_header(key => 'Authorization', value => 'Bearer ' . $self->{access_token});
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_access_token {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'iplabel_ekara_api_' . md5_hex($self->{hostname}) . '_' . md5_hex($self->{api_username}));
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $access_token = $options{statefile}->get(name => 'access_token');
    if ( $has_cache_file == 0 || !defined($access_token) || (($expires_on - time()) < 10) ) {
        my $login = { email => $self->{api_username}, password => $self->{api_password} };
        my $post_json = JSON::XS->new->utf8->encode($login);

        $self->settings();

        my $content = $self->{http}->request(
            method => 'POST',
            header => ['Content-type: application/json'],
            query_form_post => $post_json,
            url_path => $self->{authent_endpoint}
        );

        if (!defined($content) || $content eq '' || $self->{http}->get_header(name => 'content-length') == 0) {
            $self->{output}->add_option_msg(short_msg => "Authentication endpoint returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
            $self->{output}->option_exit();
        }

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->output_add(long_msg => $content, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
            $self->{output}->option_exit();
        }
        if (!($decoded->{success})) {
            $self->{output}->output_add(long_msg => "Error message : " . $decoded->{message}, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Authentication endpoint returns error code '" . $decoded->{message} . "' (add --debug option for detailed message)");
            $self->{output}->option_exit();
        }

        $access_token = $decoded->{token};
        my $datas = { last_timestamp => time(), access_token => $decoded->{token}, expires_on => time() + 3600 };
        $options{statefile}->write(data => $datas);
    }

    return $access_token;
}

sub request_scenarios_status{
    my ($self, %options) = @_;

    my $status_filter = {};
    my @get_param;

    if (defined($self->{option_results}->{filter_status}) && $self->{option_results}->{filter_status}[0] ne '') {
        $status_filter->{statusFilter} = $self->{option_results}->{filter_status};
    }
    if (defined($self->{option_results}->{filter_workspaceid}) && $self->{option_results}->{filter_workspaceid} ne '') {
        push(@get_param, "workspaceId=$self->{option_results}->{filter_workspaceid}");
    }
    if (defined($self->{option_results}->{filter_siteid}) && $self->{option_results}->{filter_siteid} ne '') {
        push(@get_param, "siteId=$self->{option_results}->{filter_siteid}");
    }
    my $results = $self->request_api(
        endpoint => '/results-api/scenarios/status',
        method => 'POST',
        post_body => $status_filter,
        get_param => \@get_param,
    );
    if (ref($results) eq "HASH" ) {
        if (defined($results->{message})) {
            $self->{output}->add_option_msg(short_msg => "Cannot get scenarios : " . $results->{message});
            $self->{output}->option_exit();
        }
        if (defined($results->{error})) {
            $self->{output}->add_option_msg(short_msg => "Cannot get scenarios : " . $results->{error});
            $self->{output}->option_exit();
        }
        $self->{output}->add_option_msg(short_msg => "Cannot get scenarios due to an unknown error, please use the --debug option to find more information");
        $self->{output}->option_exit();
    }

    my @scenarios;
    for my $scenario (@$results) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $scenario->{scenarioName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping scenario '" . $scenario->{scenarioName} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $scenario->{scenarioId} !~ /$self->{option_results}->{filter_id}/) {
            $self->{output}->output_add(long_msg => "skipping scenario '" . $scenario->{scenarioName} . "': no matching filter.", debug => 1);
            next;
        }
        push(@scenarios, $scenario);
    }
    return \@scenarios;
}

sub request_api {
    my ($self, %options) = @_;

    if ($self->{api_key} eq '' && !$self->{access_token}) {
        $self->{access_token} = $self->get_access_token(statefile => $self->{cache});
    }

    $self->settings();

    my ($json, $response);

    my $post_json = $options{post_body} // {};

    $response = $self->{http}->request(
        get_param => $options{get_param},
        method => $options{method},
        url_path => $self->{url_path} . $options{endpoint},
        query_form_post => JSON::XS->new->utf8->encode($post_json)
    );
    $self->{output}->output_add(long_msg => $response, debug => 1);

    # Bad API key returns 401 Unauthorized
    if ($self->{api_key} ne '' && ($self->{http}->get_code() // '') eq '401') {
        $self->{output}->add_option_msg(short_msg => "API key is not valid.");
        $self->{output}->option_exit();
    }

    eval {
        $json = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode ekara JSON response: $@");
        $self->{output}->option_exit();
    };

    return $json;
}


1;

__END__

=head1 NAME

ip-label Ekara Rest API

=head1 REST API OPTIONS

ip-label Ekara Rest API

=head2 Authentication

Ekara REST API supports two authentication modes which cannot be use simultaneously: API key or username/password.

=over 8

=item B<--api-key>

Set API key authentication.

=item B<--api-username>

Set username.

=item B<--api-password>

Set password.

=head2 Other common API options

=over 8

=item B<--hostname>

Set hostname (default: 'api.ip-label.net').

=item B<--port>

Port used (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')


=item B<--filter-id>

Filter by monitor ID (can be a regexp).

=item B<--filter-name>

Filter by monitor name (can be a regexp).

=item B<--filter-status>

Filter by numeric status (can be multiple).
0 => 'Unknown',
1 => 'Success',
2 => 'Failure',
3 => 'Aborted',
4 => 'No execution',
5 => 'No execution',
6 => 'Stopped',
7 => 'Excluded',
8 => 'Degraded'

Example: --filter-status='1,2'

=item B<--filter-workspaceid>

Filter scenario to check by workspace id.

=item B<--filter-siteid>

Filter scenario to check by site id.

=item B<--timeout>

Set timeout in seconds (default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
