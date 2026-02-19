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

package cloud::cisco::webex::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self = {};
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
            'client-id:s'            => { name => 'client_id' },
            'client-secret:s'        => { name => 'client_secret' },
            'refresh-token:s'        => { name => 'refresh_token' },
            'hostname:s'             => { name => 'hostname' },
            'port:s'                 => { name => 'port', default => 443 },
            'proto:s'                => { name => 'proto', default => 'https' },
            'timeout:s'              => { name => 'timeout', default => 30 },
            'unknown-http-status:s'  => {
                name    => 'unknown_http_status',
                default => '%{http_code} < 200 or %{http_code} >= 300'
            },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'HPE Primera API OPTIONS', once => 1);

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

    if (centreon::plugins::misc::is_empty($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }
    if (centreon::plugins::misc::is_empty($self->{option_results}->{client_id})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --client-id option.');
        $self->{output}->option_exit();
    }
    if (centreon::plugins::misc::is_empty($self->{option_results}->{client_secret})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --client-secret option.');
        $self->{output}->option_exit();
    }
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{http}->add_header(key => 'Content-Type', value => 'application/x-www-form-urlencoded');

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{option_results}->{hostname} . ':' . $self->{option_results}->{port};
}

sub get_token {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache}->read(statefile =>
        'cloud_cisco_webexapi_' . md5_hex($self->get_connection_info() . '_' . $self->{option_results}->{client_id}));
    my $access_token = $self->{cache}->get(name => 'access_token');
    my $expires_on = $self->{cache}->get(name => 'expires_on');

    if ($has_cache_file == 0 || !defined($access_token) || $access_token eq '' || (($expires_on - time()) < 60)) {
        my $post_data = 'client_id=' . $self->{option_results}->{client_id} .
            '&client_secret=' . $self->{option_results}->{client_secret} .
            '&refresh_token=' . $self->{option_results}->{refresh_token} .
            '&grant_type=refresh_token';

        my $content = $self->{http}->request(
            method          => 'POST',
            url_path        => '/v1/access_token',
            query_form_post => $post_data,
            unknown_status  => $self->{option_results}->{unknown_http_status},
            warning_status  => $self->{option_results}->{warning_http_status},
            critical_status => $self->{option_results}->{critical_http_status}
        );

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "An error occurred while decoding the response ('$content').");
            $self->{output}->option_exit();
        }

        $access_token = $decoded->{access_token};
        my $data = {
            updated  => time(),
            access_token => $decoded->{access_token},
            expires_in => $decoded->{expires_in},
            expires_on => time() + $decoded->{expires_in}
        };
        $self->{cache}->write(data => $data);
    }

    return $access_token;
}

sub clean_token {
    my ($self, %options) = @_;

    my $data = { updated => time() };
    $self->{cache}->write(data => $data);
}

sub request_api {
    my ($self, %options) = @_;

    my $get_param = [];
    if (defined($options{get_param})) {
        $get_param = $options{get_param};
    }

    my $token = $self->get_token();
    my ($content) = $self->{http}->request(
        url_path        => $options{endpoint},
        get_param       => $get_param,
        header => ['Authorization: Bearer ' . $token],
        unknown_status  => '',
        warning_status  => '',
        critical_status => ''
    );

    # Maybe token is invalid. so we retry
    if (!defined($token) || $self->{http}->get_code() >= 400) {
        $self->clean_token();
        $token = $self->get_token();

        $content = $self->{http}->request(
            url_path        => $options{endpoint},
            get_param       => $get_param,
            header => ['Authorization: Bearer ' . $token],
            unknown_status  => $self->{unknown_http_status},
            warning_status  => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );
    }

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg =>
            "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->allow_nonref(1)->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg =>
            "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    return $decoded;
}

1;

__END__

=head1 NAME

cloud cisco webex REST API

=head1 Webex API OPTIONS

Webex REST API

=over 8

=item B<--hostname>

Address of the server that hosts the API.

=item B<--port>

Define the TCP port to use to reach the API (default: 443).

=item B<--proto>

Define the protocol to reach the API (default: 'https').

=item B<--client-id>

Define the client-id for authentication.

=item B<--client-secret>

Define the secret associated with the username.

=item B<--refresh-token>

Define the refresh token associated with the username. Used to renew the access token

=item B<--timeout>

Define the timeout in seconds for HTTP requests (default: 30).

=back

=head1 DESCRIPTION

B<custom>.

=cut
