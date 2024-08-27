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

package network::stormshield::api::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);
use MIME::Base64;
use XML::LibXML::Simple;
use URI::Encode;

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
            'api-username:s'    => { name => 'api_username' },
            'api-password:s'    => { name => 'api_password' },
            'hostname:s'        => { name => 'hostname' },
            'port:s'            => { name => 'port' },
            'proto:s'           => { name => 'proto' },
            'timeout:s'         => { name => 'timeout' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'API OPTIONS', once => 1);

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

    $self->{option_results}->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{option_results}->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{option_results}->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{option_results}->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';

    if ($self->{option_results}->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-username option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-password option.');
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{http}->add_header(key => 'Accept', value => '*/*');
    $self->{settings_done} = 1;
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{option_results}->{hostname} . ':' . $self->{option_results}->{port};
}

sub decode_xml {
    my ($self, %options) = @_;

    my $decoded;
    eval {
        $SIG{__WARN__} = sub {};
        $decoded = XMLin($options{content}, KeyAttr => [], ForceArray => ['serverd', 'section', 'key', 'line']);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode xml response: $@");
        $self->{output}->option_exit();
    }

    return $decoded;
}

my $map_api_code = {
    SSL_SERVERD_OK => 100,
    SSL_SERVERD_REQUEST_ERROR => 200,
    SSL_SERVERD_UNKNOWN_COMMAND => 201,
    SSL_SERVERD_ERROR_COMMAND => 202,
    SSL_SERVERD_INVALID_SESSION => 203,
    SSL_SERVERD_EXPIRED_SESSION => 204,
    SSL_SERVERD_AUTH_ERROR => 205,
    SSL_SERVERD_PENDING_TRANSFER => 206,
    SSL_SERVERD_PENDING_UPLOAD => 207,
    SSL_SERVERD_OVERHEAT => 500,
    SSL_SERVERD_UNREACHABLE => 501,
    SSL_SERVERD_DISCONNECTED => 502,
    SSL_SERVERD_INTERNAL_ERROR => 900
};
my $map_api_msg = {
    $map_api_code->{SSL_SERVERD_REQUEST_ERROR} => "request error",
    $map_api_code->{SSL_SERVERD_UNKNOWN_COMMAND} => "unknown command",
    $map_api_code->{SSL_SERVERD_ERROR_COMMAND} => "command error",
    $map_api_code->{SSL_SERVERD_INVALID_SESSION} => "invalid session",
    $map_api_code->{SSL_SERVERD_EXPIRED_SESSION} => "expired session",
    $map_api_code->{SSL_SERVERD_AUTH_ERROR} => "authentication error",
    $map_api_code->{SSL_SERVERD_PENDING_TRANSFER} => "pending transfer",
    $map_api_code->{SSL_SERVERD_PENDING_UPLOAD} => "upload pending",
    $map_api_code->{SSL_SERVERD_OVERHEAT} => "server overheat",
    $map_api_code->{SSL_SERVERD_UNREACHABLE} => "server unreachable",
    $map_api_code->{SSL_SERVERD_DISCONNECTED} => "server disconnected",
    $map_api_code->{SSL_SERVERD_INTERNAL_ERROR} => "internal error"
};

sub get_session_id {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache}->read(statefile => 'stormshield_' . md5_hex($self->get_connection_info() . '_' . $self->{api_username}));
    my $session_id = $self->{cache}->get(name => 'session_id');
    my $cookie = $self->{cache}->get(name => 'cookie');
    my $md5_secret_cache = $self->{cache}->get(name => 'md5_secret');
    my $md5_secret = md5_hex($self->{api_username} . $self->{api_password});

    if ($has_cache_file == 0 ||
        !defined($session_id) ||
        (defined($md5_secret_cache) && $md5_secret_cache ne $md5_secret)
        ) {
        my $json_request = {
            username => $self->{api_username},
            password => $self->{api_password},
            grant_type => 'password'
        };

        $self->settings();
        my ($content) = $self->{http}->request(
            method => 'POST',
            url_path => '/auth/admin.html',
            post_param => [
                'uid=' . MIME::Base64::encode_base64($self->{api_username}, ''),
                'pswd=' . MIME::Base64::encode_base64($self->{api_password}, ''),
                'app=sslclient'
            ],
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );

        my $decoded = $self->decode_xml(content => $content);
        if ($decoded->{msg} ne 'AUTH_SUCCESS') {
            $self->{output}->add_option_msg(short_msg => 'Authentication failed: ' . $decoded->{msg});
            $self->{output}->option_exit();
        }

        my (@cookies) = $self->{http}->get_first_header(name => 'Set-Cookie');
        $cookie = '';
        foreach (@cookies) {
            $cookie = $1 if (/(NETASQ_sslclient=.+?);/);
        }

        if (!defined($cookie) || $cookie eq '') {
            $self->{output}->add_option_msg(short_msg => 'Cannot get cookie');
            $self->{output}->option_exit();
        }

        ($content) = $self->{http}->request(
            method => 'POST',
            url_path => '/api/auth/login',
            post_param => [
                'app=sslclient',
                'id=0'
            ],
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status},
            header => ['Cookie: ' . $cookie]
        );

        $decoded = $self->decode_xml(content => $content);
        if ($decoded->{code} != $map_api_code->{SSL_SERVERD_OK}) {
            $self->{output}->add_option_msg(short_msg => "Can't get serverd session: " . $map_api_msg->{ $decoded->{code} });
            $self->{output}->option_exit();
        }
        if (!defined($decoded->{sessionid})) {
            $self->{output}->add_option_msg(short_msg => "Can't get serverd session");
            $self->{output}->option_exit();
        }

        $session_id = $decoded->{sessionid};

        my $datas = {
            updated => time(),
            cookie => $cookie,
            session_id => $session_id,
            md5_secret => $md5_secret
        };
        $self->{cache}->write(data => $datas);
    }

    return ($cookie, $session_id);
}

sub clean_session_id {
    my ($self, %options) = @_;

    my $datas = { updated => time() };
    $self->{cache}->write(data => $datas);
}

sub request_api_internal {
    my ($self, %options) = @_;

    $self->settings();
    my ($cookie, $session_id) = $self->get_session_id();

    my $uri = URI::Encode->new({encode_reserved => 1});

    # stormshield doesnt like the space separator +
    my ($content) = $self->{http}->request(
        url_path => '/api/command?sessionid=' . $session_id . '&cmd=' . $uri->encode($options{command}),
        header => ['Cookie: ' . $cookie],
        unknown_status => $options{unknown_status},
        warning_status => $options{warning_status},
        critical_status => $options{critical_status}
    );

    return $content;
}

sub request {
    my ($self, %options) = @_;

    my $content = $self->request_api_internal(
        command => $options{command},
        unknown_status => '',
        warning_status => '',
        critical_status => ''
    );

    # Maybe token is invalid. so we retry
    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->clean_session_id();
        $content = $self->request_api_internal(
            command => $options{command},
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );
    }

    my $decoded = $self->decode_xml(content => $content);
    if ($decoded->{code} == $map_api_code->{SSL_SERVERD_INVALID_SESSION} ||
        $decoded->{code} == $map_api_code->{SSL_SERVERD_EXPIRED_SESSION} ||
        $decoded->{code} == $map_api_code->{SSL_SERVERD_DISCONNECTED}) {
        $self->clean_session_id();
        $content = $self->request_api_internal(
            command => $options{command},
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );
        $decoded = $self->decode_xml(content => $content);
    }

    if ($decoded->{code} != $map_api_code->{SSL_SERVERD_OK}) {
        $self->{output}->add_option_msg(short_msg => "Command error: " . $map_api_msg->{ $decoded->{code} });
        $self->{output}->option_exit();
    }

    return $self->parse_format(xml => $decoded);
}

sub parse_format {
    my ($self, %options) = @_;

    my $code = scalar(@{$options{xml}->{serverd}}) > 1 ? $options{xml}->{serverd}->[1]->{ret} : $options{xml}->{serverd}->[0]->{ret};
    if ($code != $map_api_code->{SSL_SERVERD_OK}) {
        $self->{output}->add_option_msg(short_msg => "Command error: " . $map_api_msg->{ $code });
        $self->{output}->option_exit();
    }
    if ($options{xml}->{serverd}->[0]->{data}->{format} eq 'section') {
        my $result = {};
        foreach my $section (@{$options{xml}->{serverd}->[0]->{data}->{section}}) {
            $result->{ $section->{title} } = {};
            foreach my $entry (@{$section->{key}}) {
                $result->{ $section->{title} }->{ $entry->{name} } = $entry->{value};
            }
        }

        return $result;
    }

    if ($options{xml}->{serverd}->[0]->{data}->{format} eq 'section_line') {
        my $result = {};
        foreach my $section (@{$options{xml}->{serverd}->[0]->{data}->{section}}) {
            $result->{ $section->{title} } = [];
            foreach my $line (@{$section->{line}}) {
                my $entry = {};
                foreach (@{$line->{key}}) {
                    $entry->{ $_->{name} } = $_->{value};
                }

                push @{$result->{ $section->{title} }}, $entry;
            }
        }

        return $result;
    }

    $self->{output}->add_option_msg(short_msg => "Unsupported command response: " . $options{xml}->{serverd}->[0]->{data}->{format});
    $self->{output}->option_exit();
}

1;

__END__

=head1 NAME

Stormshield API

=head1 API OPTIONS

Stormshield API

=over 8

=item B<--hostname>

Set hostname.

=item B<--port>

Port used (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--api-username>

API username.

=item B<--api-password>

API password.

=item B<--timeout>

Set timeout in seconds (default: 30).

=back

=head1 DESCRIPTION

B<custom>.

=cut
