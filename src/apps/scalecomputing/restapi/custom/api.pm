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

package apps::scalecomputing::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::statefile;
use DateTime;

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
        $options{options}->add_options(
            arguments => {
                'hostname:s'             => { name => 'hostname' },
                'port:s'                 => { name => 'port' },
                'proto:s'                => { name => 'proto' },
                'username:s'             => { name => 'username' },
                'password:s'             => { name => 'password' },
                'api-path:s'             => { name => 'api_path' },
                'timeout:s'              => { name => 'timeout' },
                'unknown-http-status:s'  => { name => 'unknown_http_status' },
                'warning-http-status:s'  => { name => 'warning_http_status' },
                'critical-http-status:s' => { name => 'critical_http_status' }
            }
        );
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{cache_cookie} = centreon::plugins::statefile->new(%options);
    $self->{cache_app} = centreon::plugins::statefile->new(%options);

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
    $self->{username} = (defined($self->{option_results}->{username})) ? $self->{option_results}->{username} : '';
    $self->{password} = (defined($self->{option_results}->{password})) ? $self->{option_results}->{password} : '';
    $self->{api_path} = (defined($self->{option_results}->{api_path})) ?
        $self->{option_results}->{api_path} :
        '/rest/v1';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ?
        $self->{option_results}->{unknown_http_status} :
        '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ?
        $self->{option_results}->{warning_http_status} :
        '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ?
        $self->{option_results}->{critical_http_status} :
        '';

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }
    if ($self->{username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --username option.");
        $self->{output}->option_exit();
    }
    if ($self->{password} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --password option.");
        $self->{output}->option_exit();
    }

    $self->{cache_cookie}->check_options(option_results => $self->{option_results});
    $self->{cache_app}->check_options(option_results => $self->{option_results});

    return 0;
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

sub get_connection_infos {
    my ($self, %options) = @_;

    return $self->{hostname} . '_' . $self->{http}->get_port();
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
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

sub clean_session {
    my ($self, %options) = @_;

    my $datas = {};
    $options{statefile}->write(data => $datas);
    $self->{session_cookie} = undef;
    $self->{http}->add_header(key => 'Cookie', value => undef);
}

sub get_session_cookie {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(
        statefile =>
            'scalecomputing_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{option_results}->{username})
    );
    my $session_cookie = $options{statefile}->get(name => 'session_cookie');

    if ($has_cache_file == 0 || !defined($session_cookie)) {
        my $form_post = { username => $self->{username}, password => $self->{password} };
        my $encoded;
        eval {
            $encoded = JSON::XS->new->utf8->encode($form_post);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => 'Cannot encode json request');
            $self->{output}->option_exit();
        }

        $self->{http}->request(
            method          => 'POST',
            url_path        => $self->{api_path} . '/login',
            query_form_post => $encoded,
            warning_status  => '',
            unknown_status  => '',
            critical_status => ''
        );

        if ($self->{http}->get_code() != 200) {
            $self->{output}->add_option_msg(
                short_msg =>
                    "Authentication error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']"
            );
            $self->{output}->option_exit();
        }

        my ($cookie) = $self->{http}->get_header(name => 'Set-Cookie');
        if (!defined($cookie)) {
            $self->{output}->add_option_msg(short_msg => "Cannot get session");
            $self->{output}->option_exit();
        }

        $cookie =~ /sessionID=(.*);/;
        $session_cookie = $1;

        if (!defined($session_cookie)) {
            $self->{output}->add_option_msg(short_msg => "Cannot get session");
            $self->{output}->option_exit();
        }

        $options{statefile}->write(data => { session_cookie => $session_cookie });
    }

    $self->{session_cookie} = $session_cookie;
    $self->{http}->add_header(key => 'Cookie', value => 'sessionID=' . $self->{session_cookie});
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();

    my $encoded_form_post;
    if (defined($options{query_form_post})) {
        eval {
            $encoded_form_post = JSON::XS->new->utf8->encode($options{query_form_post});
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot encode json request");
            $self->{output}->option_exit();
        }
    }

    my $loop = 0;
    while (1) {
        if (!defined($self->{session_cookie})) {
            $self->get_session_cookie(statefile => $self->{cache_cookie});
        }

        my ($content) = $self->{http}->request(
            method          => $options{method},
            url_path        => $self->{api_path} . $options{endpoint},
            query_form_post => $encoded_form_post,
            unknown_status  => $loop > 0 ? $self->{unknown_http_status} : '',
            warning_status  => $loop > 0 ? $self->{warning_http_status} : '',
            critical_status => $loop > 0 ? $self->{critical_http_status} : ''
        );
        $loop++;
        if ($loop == 3) {
            $self->{output}->add_option_msg(short_msg => 'cannot get valid data');
            $self->{output}->option_exit();
        }

        if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
            $self->clean_session(statefile => $self->{cache_cookie});
            next;
        }

        my $decoded = $self->json_decode(content => $content);
        if (!defined($decoded)) {
            $self->{output}->add_option_msg(
                short_msg => 'error while retrieving data (add --debug option for detailed message)'
            );
            $self->{output}->option_exit();
        }
        if (ref($decoded) ne 'ARRAY' && defined($decoded->{error})) {
            $self->{output}->add_option_msg(
                short_msg => sprintf(
                    "API returned http code '%s', error '%s'",
                    $self->{http}->get_code(),
                    $decoded->{error}
                )
            );
            $self->{output}->option_exit();
        }

        return $decoded;
    }
}

sub list_drives {
    my ($self) = shift;

    my $response = $self->request_api(
        method   => 'GET',
        endpoint => "/Drive/",
    );

    return $response;
}

sub list_clusters {
    my ($self) = shift;

    my $response = $self->request_api(
        method   => 'GET',
        endpoint => "/Cluster/",
    );

    return $response;
}

sub list_nodes {
    my ($self) = shift;

    my $response = $self->request_api(
        method   => 'GET',
        endpoint => "/Node/",
    );

    return $response;
}

sub list_virtual_domains {
    my ($self) = shift;

    my $response = $self->request_api(
        method   => 'GET',
        endpoint => "/VirDomain/",
    );

    return $response;
}

sub list_virtual_domain_block_devices {
    my ($self) = shift;

    my $response = $self->request_api(
        method   => 'GET',
        endpoint => "/VirDomainBlockDevice/",
    );

    return $response;
}

1;

__END__

=head1 NAME

Scale Computing HyperCore Rest API

=head1 SYNOPSIS

Scale Computing HyperCore Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Scale Computing HyperCore API hostname.

=item B<--port>

Port used (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--username>

Scale Computing HyperCore API username.

=item B<--password>

Scale Computing HyperCore API password.

=item B<--api-path>

API base url path (default: '/rest/v1').

=item B<--timeout>

Set HTTP timeout in seconds (default: '10').

=item B<--unknown-http-status>

Threshold unknown for http response code (default: '%{http_code} < 200 or (%{http_code} >= 300 && %{http_code} != 404)')

=item B<--warning-http-status>

Warning threshold for http response code

=item B<--critical-http-status>

Critical threshold for http response code

=back

=head1 DESCRIPTION

B<custom>.

=cut
