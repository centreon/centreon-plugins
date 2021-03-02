#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package centreon::plugins::backend::http::lwp;

use strict;
use warnings;
use centreon::plugins::backend::http::useragent;
use URI;
use IO::Socket::SSL;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{noptions}) || $options{noptions} != 1) {
        $options{options}->add_options(arguments => {
            'ssl:s'      => { name => 'ssl' },
            'ssl-opt:s@' => { name => 'ssl_opt' },
        });
        $options{options}->add_help(package => __PACKAGE__, sections => 'BACKEND LWP OPTIONS', once => 1);
    }

    $self->{output} = $options{output};
    $self->{ua} = undef;
    $self->{debug_handlers} = 0;

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    foreach (('unknown_status', 'warning_status', 'critical_status')) {
        if (defined($options{request}->{$_})) {
            $options{request}->{$_} =~ s/%\{http_code\}/\$self->{response}->code/g;
        }
    }

    $self->{ssl_context} = '';
    if (!defined($options{request}->{ssl_opt})) {
        $options{request}->{ssl_opt} = [];
    }
    if (defined($options{request}->{ssl}) && $options{request}->{ssl} ne '') {
        push @{$options{request}->{ssl_opt}}, 'SSL_version => ' . $options{request}->{ssl};
    }
    if (defined($options{request}->{cert_file}) && !defined($options{request}->{cert_pkcs12})) {
        push @{$options{request}->{ssl_opt}}, 'SSL_use_cert => 1';
        push @{$options{request}->{ssl_opt}}, 'SSL_cert_file => "' . $options{request}->{cert_file} . '"';
        push @{$options{request}->{ssl_opt}}, 'SSL_key_file => "' . $options{request}->{key_file} . '"'
             if (defined($options{request}->{key_file}));
        push @{$options{request}->{ssl_opt}}, 'SSL_ca_file => "' . $options{request}->{cacert_file} . '"'
            if (defined($options{request}->{cacert_file}));
    }
    if ($options{request}->{insecure}) {
        push @{$options{request}->{ssl_opt}}, 'SSL_verify_mode => SSL_VERIFY_NONE';
    }

    my $append = '';
    foreach (@{$options{request}->{ssl_opt}}) {
        if ($_ ne '') {
            $self->{ssl_context} .= $append . $_;
            $append = ', ';
        }
    }
}

sub set_proxy {
    my ($self, %options) = @_;

    if (defined($options{request}->{proxypac}) && $options{request}->{proxypac} ne '') {
        centreon::plugins::misc::mymodule_load(
            output => $self->{output}, module => 'HTTP::ProxyPAC',
            error_msg => "Cannot load module 'HTTP::ProxyPAC'."
        );
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
        my $proxyurl = $options{request}->{proxyurl};
        if ($options{request}->{proto} eq "https" ||
            (defined($options{request}->{full_url}) && $options{request}->{full_url} =~ /^https/)) {
            $proxyurl = 'connect://' . $2 if ($proxyurl =~ /^(http|https):\/\/(.*)/);
        }
        $self->{ua}->proxy(['http', 'https'], $proxyurl);
    }
}

sub request {
    my ($self, %options) = @_;

    my %user_agent_params = (keep_alive => 1);
    if (defined($options{request}->{certinfo}) && $options{request}->{certinfo} == 1) {
        centreon::plugins::misc::mymodule_load(
            output => $self->{output}, module => 'LWP::ConnCache',
            error_msg => "Cannot load module 'LWP::ConnCache'."
        );
        $self->{cache} = LWP::ConnCache->new();
        $self->{cache}->total_capacity(1);
        %user_agent_params = (conn_cache => $self->{cache});
    }

    my $request_options = $options{request};
    if (!defined($self->{ua})) {
        my $timeout;
        $timeout = $1 if (defined($request_options->{timeout}) && $request_options->{timeout} =~ /(\d+)/);
        $self->{ua} = centreon::plugins::backend::http::useragent->new(
            %user_agent_params,
            protocols_allowed => ['http', 'https'], 
            timeout => $timeout,
            credentials => $request_options->{credentials},
            username => $request_options->{username}, 
            password => $request_options->{password}
        );
        if (defined($request_options->{cookies_file})) {
            centreon::plugins::misc::mymodule_load(
                output => $self->{output},
                module => 'HTTP::Cookies',
                error_msg => "Cannot load module 'HTTP::Cookies'."
            );
            $self->{ua}->cookie_jar(
                HTTP::Cookies->new(
                    file => $request_options->{cookies_file},
                    autosave => 1
                )
            );
        }
    }

    if ($self->{output}->is_debug() && $self->{debug_handlers} == 0) {
        $self->{debug_handlers} = 1;
        $self->{ua}->add_handler('request_send', sub {
            my ($response, $ua, $handler) = @_;

            $self->{output}->output_add(long_msg => '======> request send', debug => 1);
            $self->{output}->output_add(long_msg => $response->as_string, debug => 1);
            return ; 
        });
        $self->{ua}->add_handler("response_done", sub { 
            my ($response, $ua, $handler) = @_;

            $self->{output}->output_add(long_msg => '======> response done', debug => 1);
            $self->{output}->output_add(long_msg => $response->as_string, debug => 1);
            return ;
        });
    }

    if (defined($request_options->{no_follow})) {
        $self->{ua}->requests_redirectable(undef);
    } else {
        $self->{ua}->requests_redirectable([ 'GET', 'HEAD', 'POST', 'PUT', 'DELETE', 'PATCH' ]);
    }
    if (defined($request_options->{http_peer_addr})) {
        push @LWP::Protocol::http::EXTRA_SOCK_OPTS, PeerAddr => $request_options->{http_peer_addr};
    }

    my ($req, $url);
    if (defined($request_options->{full_url})) {
        $url = $request_options->{full_url};
    } elsif (defined($request_options->{port}) && $request_options->{port} =~ /^[0-9]+$/) {
        $url = $request_options->{proto}. '://' . $request_options->{hostname} . ':' . $request_options->{port} . $request_options->{url_path};
    } else {
        $url = $request_options->{proto}. '://' . $request_options->{hostname} . $request_options->{url_path};
    }

    my $uri = URI->new($url);
    if (defined($request_options->{get_params})) {
        $uri->query_form($request_options->{get_params});
    }
    $req = HTTP::Request->new($request_options->{method}, $uri);

    my $content_type_forced = 0;
    foreach my $key (keys %{$request_options->{headers}}) {
        $req->header($key => $request_options->{headers}->{$key});
        if ($key =~ /content-type/i) {
            $content_type_forced = 1;
        }
    }

    if ($content_type_forced == 1) {
        $req->content($request_options->{query_form_post});
    } elsif (defined($options{request}->{post_params})) {
        my $uri_post = URI->new();
        $uri_post->query_form($request_options->{post_params});
        $req->content_type('application/x-www-form-urlencoded');
        $req->content($uri_post->query);
    }

    if (defined($request_options->{credentials}) && defined($request_options->{ntlmv2})) {
        centreon::plugins::misc::mymodule_load(
            output => $self->{output},
            module => 'Authen::NTLM',
            error_msg => "Cannot load module 'Authen::NTLM'."
        );
        Authen::NTLM::ntlmv2(1);
    }

    if (defined($request_options->{credentials}) && defined($request_options->{basic})) {
        $req->authorization_basic($request_options->{username}, $request_options->{password});
    }

    $self->set_proxy(request => $request_options, url => $url);

    if (defined($request_options->{cert_pkcs12}) && $request_options->{cert_file} ne '' && $request_options->{cert_pwd} ne '') {
        eval 'use Net::SSL'; die $@ if $@;
        $ENV{HTTPS_PKCS12_FILE} = $request_options->{cert_file};
        $ENV{HTTPS_PKCS12_PASSWORD} = $request_options->{cert_pwd};
    }

    if (defined($self->{ssl_context}) && $self->{ssl_context} ne '') {
        my $context = new IO::Socket::SSL::SSL_Context(eval $self->{ssl_context});
        IO::Socket::SSL::set_default_context($context);
    }

    $self->{response} = $self->{ua}->request($req);

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
        my $short_msg = $self->{response}->status_line;
        if ($short_msg =~ /^401/) {
            $short_msg .= ' (' . $1 . ' authentication expected)' if (defined($self->{response}->www_authenticate) &&
                $self->{response}->www_authenticate =~ /(\S+)/);
        }

        $self->{output}->output_add(
            severity => $status,
            short_msg => $short_msg
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    $self->{headers} = $self->{response}->headers();
    return $self->{response}->content;
}

sub get_headers {
    my ($self, %options) = @_;

    my $headers = '';
    foreach ($options{response}->header_field_names()) {
        my $value = $options{response}->header($_);
        $headers .= "$_: " . (defined($value) ? $value : '') . "\n";
    }

    return $headers;
}

sub get_first_header {
    my ($self, %options) = @_;

    my @redirects = $self->{response}->redirects();
    if (!defined($options{name})) {
        return $self->get_headers(response => defined($redirects[0]) ? $redirects[0] : $self->{response});
    }

    return
        defined($redirects[0]) ? 
        $redirects[0]->headers()->header($options{name}) :
        $self->{headers}->header($options{name})
    ;
}

sub get_header {
    my ($self, %options) = @_;

    if (!defined($options{name})) {
        return $self->get_headers(response => $self->{response});
    }
    return $self->{headers}->header($options{name});
}

sub get_code {
    my ($self, %options) = @_;

    return $self->{response}->code();
}

sub get_message {
    my ($self, %options) = @_;

    return $self->{response}->message();
}

sub get_certificate {
    my ($self, %options) = @_;

    my ($con) = $self->{cache}->get_connections('https');
    return ('socket', $con);
}

1;

__END__

=head1 NAME

HTTP LWP backend layer.

=head1 SYNOPSIS

HTTP LWP backend layer.

=head1 BACKEND LWP OPTIONS

=over 8

=item B<--ssl-opt>

Set SSL Options (--ssl-opt="SSL_version => TLSv1" --ssl-opt="SSL_verify_mode => SSL_VERIFY_NONE").

=item B<--ssl>

Set SSL version (--ssl=TLSv1).

=back

=head1 DESCRIPTION

B<http>.

=cut
