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

package notification::centreon::opentickets::api::custom::api;

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
            'api-hostname:s' => { name => 'api_hostname' },
            'api-port:s'     => { name => 'api_port' },
            'api-proto:s'    => { name => 'api_proto' },
            'url-path:s'     => { name => 'url_path' },
            'api-username:s' => { name => 'api_username' },
            'api-password:s' => { name => 'api_password' },
            'api-timeout:s'      => { name => 'api_timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{cache} = centreon::plugins::statefile->new(%options, default_backend => 'curl');

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{api_hostname} = (defined($self->{option_results}->{api_hostname})) ? $self->{option_results}->{api_hostname} : '';
    $self->{api_proto} = (defined($self->{option_results}->{api_proto})) ? $self->{option_results}->{api_proto} : 'http';
    $self->{api_port} = (defined($self->{option_results}->{api_port})) ? $self->{option_results}->{api_port} : 80;
    $self->{url_path} = (defined($self->{option_results}->{url_path})) ? $self->{option_results}->{url_path} : '/centreon/api/';
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{api_timeout} = (defined($self->{option_results}->{api_timeout})) ? $self->{option_results}->{api_timeout} : 10;

    if ($self->{api_hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify api-hostname option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-username option.");
        $self->{output}->option_exit();
    }
    if ($self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-password option.");
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results});
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

sub json_decode {
    my ($self, %options) = @_;

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($options{content});
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub settings {
    my ($self, %options) = @_;

    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->set_options(
        hostname => $self->{api_hostname},
        port => $self->{api_port},
        proto => $self->{api_proto},
        %{$self->{option_results}}
    );
}

sub clean_token {
    my ($self, %options) = @_;

    my $datas = {};
    $self->{cache}->write(data => $datas);
}

sub get_token {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache}->read(statefile => 'centreon_opentickets_' . md5_hex($self->{api_hostname}) . '_' . md5_hex($self->{api_username}));
    my $token = $self->{cache}->get(name => 'token');

    if ($has_cache_file == 0 || !defined($token)) {
        my ($content) = $self->{http}->request(
            method => 'POST',
            url_path => $self->{url_path} . 'index.php',
            get_param => ['action=authenticate'],
            post_param => [
                'username=' . $self->{api_username},
                'password=' . $self->{api_password}
            ],
            warning_status => '', unknown_status => '', critical_status => ''
        );

        if ($self->{http}->get_code() != 200) {
            $self->{output}->add_option_msg(short_msg => "Authentication error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
            $self->{output}->option_exit();
        }

        my $decoded = $self->json_decode(content => $content);
        if (!defined($decoded->{authToken})) {
            $self->{output}->add_option_msg(short_msg => "Cannot get token");
            $self->{output}->option_exit();
        }

        $token = $decoded->{authToken};
        my $datas = { token => $token };
        $self->{cache}->write(data => $datas);
    }

    return $token;
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    my $token = $self->get_token();

    my $encoded;
    eval {
        $encoded = JSON::XS->new->utf8->encode($options{data});
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => 'cannot encode json request');
        $self->{output}->option_exit();
    }

    my $content = $self->{http}->request(
        method => 'POST',
        url_path => $self->{url_path} . 'index.php',
        get_param => [
            'object=centreon_openticket',
            'action=' . $options{action},
        ],
        header => [
            'Content-Type: application/json',
            'centreon-auth-token: ' . $token
        ],
        query_form_post => $encoded,
        warning_status => '',
        unknown_status => '',
        critical_status => ''
    );

    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->clean_token();
        $token = $self->get_token();
        $content = $self->{http}->request(
            method => 'POST',
            url_path => $self->{url_path} . 'index.php',
            get_param => [
                'object=centreon_openticket',
                'action=' . $options{action},
            ],
            header => [
                'Content-Type: application/json',
                'centreon-auth-token: ' . $token
            ],
            query_form_post => $encoded,
            warning_status => '',
            unknown_status => '',
            critical_status => ''
        );
    }

    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->{output}->add_option_msg(short_msg => "Authentication error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded = $self->json_decode(content => $content);
    if (!defined($decoded)) {
        $self->{output}->add_option_msg(short_msg => 'Error while retrieving data (add --debug option for detailed message)');
        $self->{output}->option_exit();
    }

    return $decoded;
}

1;

__END__

=head1 NAME

Centreon Open-Tickets API

=head1 SYNOPSIS

Centreon open-tickets api

=head1 REST API OPTIONS

=over 8

=item B<--api-hostname>

Centreon address.

=item B<--url-path>

API url path (default: '/centreon/api/')

=item B<--api-port>

API port (default: 80)

=item B<--api-proto>

Specify https if needed (default: 'http')

=item B<--api-username>

API username

=item B<--api-password>

API password

=item B<--api-timeout>

HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
