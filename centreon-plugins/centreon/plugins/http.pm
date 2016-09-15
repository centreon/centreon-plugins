#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package centreon::plugins::http;

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Cookies;
use URI;
use IO::Socket::SSL;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    $self->{output} = $options{output};
    $self->{ua} = undef;
    $self->{options} = {
        proto => 'http',
        url_path => '/',
        timeout => 5,
        method => 'GET',
        unknown_status => '%{http_code} < 200 or %{http_code} >= 300',
        warning_status => undef,
        critical_status => undef,
    };
    $self->{add_headers} = {};
    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{options} = { %{$self->{options}} };
    foreach (keys %options) {
        $self->{options}->{$_} = $options{$_} if (defined($options{$_}));
    }
}

sub add_header {
    my ($self, %options) = @_;

    $self->{add_headers}->{$options{key}} = $options{value};
}

sub check_options {
    my ($self, %options) = @_;

    if (($options{request}->{proto} ne 'http') && ($options{request}->{proto} ne 'https')) {
        $self->{output}->add_option_msg(short_msg => "Unsupported protocol specified '" . $self->{option_results}->{proto} . "'.");
        $self->{output}->option_exit();
    }
    if (!defined($options{request}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the hostname option");
        $self->{output}->option_exit();
    }
    if ((defined($options{request}->{credentials})) && (!defined($options{request}->{username}) || !defined($options{request}->{password}))) {
        $self->{output}->add_option_msg(short_msg => "You need to set --username= and --password= options when --credentials is used");
        $self->{output}->option_exit();
    }
    if ((defined($options{request}->{pkcs12})) && (!defined($options{request}->{cert_file}) && !defined($options{request}->{cert_pwd}))) {
        $self->{output}->add_option_msg(short_msg => "You need to set --cert-file= and --cert-pwd= options when --pkcs12 is used");
        $self->{output}->option_exit();
    }

    $options{request}->{port} = $self->get_port_request();

    $options{request}->{headers} = {};
    if (defined($options{request}->{header})) {
        foreach (@{$options{request}->{header}}) {
            if (/^(.*?):(.*)/) {
                $options{request}->{headers}->{$1} = $2;
            }
        }
    }
    foreach (keys %{$self->{add_headers}}) {
        $options{request}->{headers}->{$_} = $self->{add_headers}->{$_};
    }

    foreach my $method (('get', 'post')) {
        if (defined($options{request}->{$method . '_param'})) {
            $self->{$method . '_params'} = {};
            foreach (@{$options{request}->{$method . '_param'}}) {
                if (/^([^=]+)={0,1}(.*)$/) {
                    my $key = $1;
                    my $value = defined($2) ? $2 : 1;
                    if (defined($self->{$method . '_params'}->{$key})) {
                        if (ref($self->{$method . '_params'}->{$key}) ne 'ARRAY') {
                            $self->{$method . '_params'}->{$key} = [ $self->{$method . '_params'}->{$key} ];
                        }
                        push @{$self->{$method . '_params'}->{$key}}, $value;
                    } else {
                        $self->{$method . '_params'}->{$key} = $value;
                    }
                }
            }
        }
    }

    foreach (('unknown_status', 'warning_status', 'critical_status')) {
        if (defined($options{request}->{$_})) {
            $options{request}->{$_} =~ s/%\{http_code\}/\$response->code/g;
        }
    }
}

sub get_port {
    my ($self, %options) = @_;

    my $port = '';
    if (defined($self->{options}->{port}) && $self->{options}->{port} ne '') {
        $port = $self->{options}->{port};
    } else {
        $port = 80 if ($self->{options}->{proto} eq 'http');
        $port = 443 if ($self->{options}->{proto} eq 'https');
    }

    return $port;
}

sub get_port_request {
    my ($self, %options) = @_;

    my $port = '';
    if (defined($self->{options}->{port}) && $self->{options}->{port} ne '') {
        $port = $self->{options}->{port};
    }
    return $port;
}

sub set_proxy {
    my ($self, %options) = @_;

    if (defined($options{request}->{proxypac}) && $options{request}->{proxypac} ne '') {
        centreon::plugins::misc::mymodule_load(output => $self->{output}, module => 'HTTP::ProxyPAC',
                                               error_msg => "Cannot load module 'HTTP::ProxyPAC'.");
        my ($pac, $pac_uri);
        eval {
            if ($options{request}->{proxypac} =~ /^(http|https):\/\//) {
                $pac_uri = URI->new($options{request}->{proxypac});
                $pac = HTTP::ProxyPAC->new($pac_uri);
            } else {
                $pac = HTTP::ProxyPAC->new($options{request}->{proxypac});
            }
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => 'issue to load proxypac: ' . $@);
            $self->{output}->option_exit();
        }
        my $res = $pac->find_proxy($options{url});
        if (defined($res->direct) && $res->direct != 1) {
            my $proxy_uri = URI->new($res->proxy);
            $proxy_uri->userinfo($pac_uri->userinfo) if (defined($pac_uri->userinfo));
            $self->{ua}->proxy(['http', 'https'], $proxy_uri->as_string);
        }
    }
    if (defined($options{request}->{proxyurl}) && $options{request}->{proxyurl} ne '') {
        $self->{ua}->proxy(['http', 'https'], $options{request}->{proxyurl});
    }
}

sub request {
    my ($self, %options) = @_;

    my $request_options = { %{$self->{options}} };
    foreach (keys %options) {
        $request_options->{$_} = $options{$_} if (defined($options{$_}));
    }
    $self->check_options(request => $request_options);

    if (!defined($self->{ua})) {
        $self->{ua} = LWP::UserAgent->new(keep_alive => 1, protocols_allowed => ['http', 'https'], timeout => $request_options->{timeout});
        if (defined($request_options->{cookies_file})) {
            $self->{ua}->cookie_jar(HTTP::Cookies->new(file => $request_options->{cookies_file},
                                                       autosave => 1));
        }
    }
    if (defined($request_options->{no_follow})) {
        $self->{ua}->requests_redirectable(undef);
    } else {
        $self->{ua}->requests_redirectable([ 'GET', 'HEAD', 'POST' ]);
    }
    if (defined($request_options->{http_peer_addr})) {
        push @LWP::Protocol::http::EXTRA_SOCK_OPTS, PeerAddr => $request_options->{http_peer_addr};
    }

    my ($response, $content);
    my ($req, $url);
    if (defined($request_options->{full_url})) {
        $url = $request_options->{full_url};
    } elsif (defined($request_options->{port}) && $request_options->{port} =~ /^[0-9]+$/) {
        $url = $request_options->{proto}. "://" . $request_options->{hostname} . ':' . $request_options->{port} . $request_options->{url_path};
    } else {
        $url = $request_options->{proto}. "://" . $request_options->{hostname} . $request_options->{url_path};
    }

    my $uri = URI->new($url);
    if (defined($self->{get_params})) {
        $uri->query_form($self->{get_params});
    }
    $req = HTTP::Request->new($request_options->{method}, $uri);

    my $content_type_forced;
    foreach my $key (keys %{$request_options->{headers}}) {
        if ($key !~ /content-type/i) {
            $req->header($key => $request_options->{headers}->{$key});
        } else {
            $content_type_forced = $request_options->{headers}->{$key};
        }
    }

    if ($request_options->{method} eq 'POST') {
        if (defined($content_type_forced)) {
            $req->content_type($content_type_forced);
            $req->content($request_options->{query_form_post});
        } else {
            my $uri_post = URI->new();
            if (defined($self->{post_params})) {
                $uri_post->query_form($self->{post_params});
            }
            $req->content_type('application/x-www-form-urlencoded');
            $req->content($uri_post->query);
        }
    }

    if (defined($request_options->{credentials}) && defined($request_options->{ntlm})) {
        $self->{ua}->credentials($request_options->{hostname} . ':' . $request_options->{port}, '', $request_options->{username}, $request_options->{password});
    } elsif (defined($request_options->{credentials})) {
        $req->authorization_basic($request_options->{username}, $request_options->{password});
    }

    $self->set_proxy(request => $request_options, url => $url);

    if (defined($request_options->{cert_pkcs12}) && $request_options->{cert_file} ne '' && $request_options->{cert_pwd} ne '') {
        eval "use Net::SSL"; die $@ if $@;
        $ENV{HTTPS_PKCS12_FILE} = $request_options->{cert_file};
        $ENV{HTTPS_PKCS12_PASSWORD} = $request_options->{cert_pwd};
    }

    my $ssl_context;
    if (defined($request_options->{ssl}) && $request_options->{ssl} ne '') {
        $ssl_context = { SSL_version => $request_options->{ssl} };
    }
    if (defined($request_options->{cert_file}) && !defined($request_options->{cert_pkcs12})) {
        $ssl_context = {} if (!defined($ssl_context));
        $ssl_context->{SSL_use_cert} = 1;
        $ssl_context->{SSL_cert_file} = $request_options->{cert_file};
        $ssl_context->{SSL_key_file} = $request_options->{key_file} if (defined($request_options->{key_file}));
        $ssl_context->{SSL_ca_file} = $request_options->{cacert_file} if (defined($request_options->{cacert_file}));
    }

    if (defined($ssl_context)) {
        my $context = new IO::Socket::SSL::SSL_Context(%{$ssl_context});
        IO::Socket::SSL::set_default_context($context);
    }

    $response = $self->{ua}->request($req);

    # Check response
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        if (defined($request_options->{critical_status}) && $request_options->{critical_status} ne '' &&
            eval "$request_options->{critical_status}") {
            $status = 'critical';
        } elsif (defined($request_options->{warning_status}) && $request_options->{warning_status} ne '' &&
                 eval "$request_options->{warning_status}") {
            $status = 'warning';
        } elsif (defined($request_options->{unknown_status}) && $request_options->{unknown_status} ne '' &&
                 eval "$request_options->{unknown_status}") {
            $status = 'unknown';
        }
    };
    if (defined($message)) {
        $self->{output}->add_option_msg(short_msg => 'filter status issue: ' . $message);
        $self->{output}->option_exit();
    }

    if (!$self->{output}->is_status(value => $status, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $status,
                                    short_msg => $response->status_line);
        $self->{output}->display();
        $self->{output}->exit();
    }

    $self->{headers} = $response->headers();
    $self->{response} = $response;
    return $response->content;
}

sub get_header {
    my ($self, %options) = @_;

    return $self->{headers};
}

sub get_response {
    my ($self, %options) = @_;

    return $self->{response};
}

1;
