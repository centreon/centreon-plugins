#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::exense::step::restapi::custom::api;

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
            'hostname:s'     => { name => 'hostname' },
            'port:s'         => { name => 'port' },
            'proto:s'        => { name => 'proto' },
            'api-username:s' => { name => 'api_username' },
            'api-password:s' => { name => 'api_password' },
            'token:s'        => { name => 'token' },
            'timeout:s'      => { name => 'timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
    $self->{cache_connect} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{token} = (defined($self->{option_results}->{token})) ? $self->{option_results}->{token} : '';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300' ;
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify hostname option.');
        $self->{output}->option_exit();
    }
    if ($self->{token} ne '') {
        return 0;
    }

    if ($self->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-username or --token option.");
        $self->{output}->option_exit();
    }
    if ($self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-password option.");
        $self->{output}->option_exit();
    }

    $self->{cache_connect}->check_options(option_results => $self->{option_results});
    return 0;
}

sub get_connection_infos {
    my ($self, %options) = @_;

    return $self->{hostname} . '_' . $self->{http}->get_port();
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub get_port {
    my ($self, %options) = @_;

    return $self->{port};
}


sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
}

sub clean_session_id {
    my ($self, %options) = @_;

    my $datas = { updated => time() };
    $self->{cache_connect}->write(data => $datas);
}

sub get_session_id {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache_connect}->read(statefile => 'exense_step_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{option_results}->{api_username}));
    my $session_id = $self->{cache_connect}->get(name => 'session_id');
    my $md5_secret_cache = $self->{cache_connect}->get(name => 'md5_secret');
    my $md5_secret = md5_hex($self->{api_username} . $self->{api_password});

    if ($has_cache_file == 0 ||
        !defined($session_id) ||
        (defined($md5_secret_cache) && $md5_secret_cache ne $md5_secret)
        ) {
        my $json_request = { username => $self->{api_username}, password => $self->{api_password} };
        my $encoded = centreon::plugins::misc::json_encode($json_request);
        unless($encoded) {
            $self->{output}->add_option_msg(short_msg => 'cannot encode json request');
            $self->{output}->option_exit();
        }

        my ($content) = $self->{http}->request(
            method => 'POST',
            url_path => '/rest/access/login',
            query_form_post => $encoded,
            warning_status => '', unknown_status => '', critical_status => ''
        );

        if ($self->{http}->get_code() != 200) {
            $self->{output}->add_option_msg(short_msg => "Authentication error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
            $self->{output}->option_exit();
        }

        my (@cookies) = $self->{http}->get_first_header(name => 'Set-Cookie');
        foreach my $cookie (@cookies) {
            $session_id = $1 if ($cookie =~ /sessionid=(.+?);/);
        }

        if (!defined($session_id)) {
            $self->{output}->add_option_msg(short_msg => "Cannot get cookie");
            $self->{output}->option_exit();
        }

        my $datas = {
            updated => time(),
            session_id => $session_id,
            md5_secret => $md5_secret
        };
        $self->{cache_connect}->write(data => $datas);
    }

    return $session_id;
}

sub credentials {
    my ($self, %options) = @_;

    my $creds = {};
    if ($self->{token} ne '') {
        $creds = {
            header => ['Authorization: Bearer ' . $self->{token}],
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        };
    } else {
        my $session_id = $self->get_session_id();
        $creds = {
            header => ['Cookie: sessionid=' . $session_id],
            warning_status => '',
            unknown_status => '',
            critical_status => ''
        };
    }

    return $creds;
}

sub request {
    my ($self, %options) = @_;

    my $endpoint = $options{endpoint};

    $self->settings();
    my $creds = $self->credentials();

    my $content = $self->{http}->request(
        method => $options{method},
        url_path => $endpoint,
        get_param => $options{get_param},
        query_form_post => $options{query_form_post},
        %$creds
    );

    # Maybe there is an issue with the token. So we retry.
    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->clean_session_id();
        $creds = $self->credentials();
        $creds->{unknown_status} = $self->{unknown_http_status};
        $creds->{warning_status} = $self->{warning_status};
        $creds->{critical_http_status} = $self->{critical_http_status};
        $content = $self->{http}->request(
            method => $options{method},
            url_path => $endpoint,
            get_param => $options{get_param},
            query_form_post => $options{query_form_post},
            %$creds
        );
    }

    return if (defined($options{skip_decode}));

    my $decoded = centreon::plugins::misc::json_decode($content);
    if (!defined($decoded)) {
        $self->{output}->add_option_msg(short_msg => 'Error while retrieving data (add --debug option for detailed message)');
        $self->{output}->option_exit();
    }

    return $decoded;
}

1;

__END__

=head1 NAME

Exense Step API

=head1 SYNOPSIS

Exense Step API

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

API hostname.

=item B<--port>

API port (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--token>

Use token authentication.

=item B<--api-username>

Set API username

=item B<--api-password>

Set API password

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
