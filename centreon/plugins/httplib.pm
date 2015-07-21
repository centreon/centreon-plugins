#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package centreon::plugins::httplib;

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Cookies;
use URI;
use IO::Socket::SSL;

sub get_port {
    my ($self, %options) = @_;

    my $cache_port = '';
    if (defined($self->{option_results}->{port}) && $self->{option_results}->{port} ne '') {
        $cache_port = $self->{option_results}->{port};
    } else {
        $cache_port = 80 if ($self->{option_results}->{proto} eq 'http');
        $cache_port = 443 if ($self->{option_results}->{proto} eq 'https');
    }

    return $cache_port;
}

sub connect {
    my ($self, %options) = @_;
    my $method = defined($options{method}) ? $options{method} : 'GET';
    my $connection_exit = defined($options{connection_exit}) ? $options{connection_exit} : 'unknown';

    my $ua = LWP::UserAgent->new(keep_alive => 1, protocols_allowed => ['http', 'https'], timeout => $self->{option_results}->{timeout},
                                 requests_redirectable => [ 'GET', 'HEAD', 'POST' ]);
    if (defined($options{cookies_file})) {
        $ua->cookie_jar(HTTP::Cookies->new(file => $options{cookies_file},
                                           autosave => 1));
    }

    my ($response, $content);
    my ($req, $url);
    if (defined($self->{option_results}->{port}) && $self->{option_results}->{port} =~ /^[0-9]+$/) {
        $url = $self->{option_results}->{proto}. "://" . $self->{option_results}->{hostname}.':'. $self->{option_results}->{port} . $self->{option_results}->{url_path};
    } else {
        $url = $self->{option_results}->{proto}. "://" . $self->{option_results}->{hostname} . $self->{option_results}->{url_path};
    }

    my $uri = URI->new($url);
    if (defined($options{query_form_get})) {
        $uri->query_form($options{query_form_get});
    }
    $req = HTTP::Request->new($method => $uri);

    my $content_type_forced;
    if (defined($options{headers})) {
        foreach my $key (keys %{$options{headers}}) {
            if ($key !~ /content-type/i) {
                $req->header($key => $options{headers}->{$key});
            } else {
                $content_type_forced = $options{headers}->{$key};
            }
        }
    }

    if ($method eq 'POST') {
        if (defined($content_type_forced)) {
            $req->content_type($content_type_forced);
            $req->content($options{query_form_post});
        } else {
            my $uri_post = URI->new();
            if (defined($options{query_form_post})) {
                $uri_post->query_form($options{query_form_post});
            }
            $req->content_type('application/x-www-form-urlencoded');
            $req->content($uri_post->query);
        }
    }

    if (defined($self->{option_results}->{credentials}) && defined($self->{option_results}->{ntlm})) {
        $ua->credentials($self->{option_results}->{hostname} . ':' . $self->{option_results}->{port}, '', $self->{option_results}->{username}, $self->{option_results}->{password});
    } elsif (defined($self->{option_results}->{credentials})) {
        $req->authorization_basic($self->{option_results}->{username}, $self->{option_results}->{password});
    }

    if (defined($self->{option_results}->{proxyurl})) {
        $ua->proxy(['http', 'https'], $self->{option_results}->{proxyurl});
    }

    if (defined($self->{option_results}->{cert_pkcs12}) && $self->{option_results}->{cert_file} ne '' && $self->{option_results}->{cert_pwd} ne '') {
        eval "use Net::SSL"; die $@ if $@;
        $ENV{HTTPS_PKCS12_FILE} = $self->{option_results}->{cert_file};
        $ENV{HTTPS_PKCS12_PASSWORD} = $self->{option_results}->{cert_pwd};
    }

    my $ssl_context;
    if (defined($self->{option_results}->{ssl}) && $self->{option_results}->{ssl} ne '') {
        $ssl_context = { SSL_version => $self->{option_results}->{ssl} };
    }
    if (defined($self->{option_results}->{cert_file}) && !defined($self->{option_results}->{cert_pkcs12})) {
        $ssl_context = {} if (!defined($ssl_context));
        $ssl_context->{SSL_use_cert} = 1;
        $ssl_context->{SSL_cert_file} = $self->{option_results}->{cert_file};
        $ssl_context->{SSL_key_file} = $self->{option_results}->{key_file} if (defined($self->{option_results}->{key_file}));
        $ssl_context->{SSL_ca_file} = $self->{option_results}->{cacert_file} if (defined($self->{option_results}->{cacert_file}));
    }
    
    if (defined($ssl_context)) {
        my $context = new IO::Socket::SSL::SSL_Context(%{$ssl_context});
        IO::Socket::SSL::set_default_context($context);
    }

    $response = $ua->request($req);

    if ($response->is_success) {
        $content = $response->content;
        return $content;
    }

    $self->{output}->output_add(severity => $connection_exit,
                                short_msg => $response->status_line);
    $self->{output}->display();
    $self->{output}->exit();
}

1;
