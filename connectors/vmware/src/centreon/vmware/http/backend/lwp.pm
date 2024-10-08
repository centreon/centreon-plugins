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

package centreon::vmware::http::backend::lwp;

use strict;
use warnings;
use centreon::vmware::http::backend::useragent;
use URI;
use IO::Socket::SSL;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    $self->{logger} = $options{logger};
    $self->{ua} = undef;
    $self->{debug_handlers} = 0;
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;

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

    if (defined($options{request}->{proxyurl}) && $options{request}->{proxyurl} ne '') {
        $self->{ua}->proxy(['http', 'https'], $options{request}->{proxyurl});
    }
}

sub request {
    my ($self, %options) = @_;

    my $request_options = $options{request};
    if (!defined($self->{ua})) {
        $self->{ua} = centreon::plugins::backend::http::useragent->new(
            keep_alive => 1, protocols_allowed => ['http', 'https'], timeout => $request_options->{timeout},
            credentials => $request_options->{credentials}, username => $request_options->{username}, password => $request_options->{password});
    }
    
    if ($self->{logger}->is_debug() && $self->{debug_handlers} == 0) {
        $self->{debug_handlers} = 1;
        $self->{ua}->add_handler("request_send", sub {
            my ($response, $ua, $handler) = @_;

            $self->{logger}->writeLogDebug("======> request send");
            $self->{logger}->writeLogDebug($response->as_string);
            return ; 
        });
        $self->{ua}->add_handler("response_done", sub { 
            my ($response, $ua, $handler) = @_;

            $self->{logger}->writeLogDebug("======> response done");
            $self->{logger}->writeLogDebug($response->as_string);
            return ;
        });
    }
    
    if (defined($request_options->{no_follow})) {
        $self->{ua}->requests_redirectable(undef);
    } else {
        $self->{ua}->requests_redirectable([ 'GET', 'HEAD', 'POST' ]);
    }
    if (defined($request_options->{http_peer_addr})) {
        push @LWP::Protocol::http::EXTRA_SOCK_OPTS, PeerAddr => $request_options->{http_peer_addr};
    }

    my ($req, $url);
    if (defined($request_options->{full_url})) {
        $url = $request_options->{full_url};
    } elsif (defined($request_options->{port}) && $request_options->{port} =~ /^[0-9]+$/) {
        $url = $request_options->{proto}. "://" . $request_options->{hostname} . ':' . $request_options->{port} . $request_options->{url_path};
    } else {
        $url = $request_options->{proto}. "://" . $request_options->{hostname} . $request_options->{url_path};
    }

    my $uri = URI->new($url);
    if (defined($request_options->{get_params})) {
        $uri->query_form($request_options->{get_params});
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
            if (defined($request_options->{post_params})) {
                $uri_post->query_form($request_options->{post_params});
            }
            $req->content_type('application/x-www-form-urlencoded');
            $req->content($uri_post->query);
        }
    }

    if (defined($request_options->{credentials}) && defined($request_options->{basic})) {
        $req->authorization_basic($request_options->{username}, $request_options->{password});
    }

    $self->set_proxy(request => $request_options, url => $url);

    if (defined($request_options->{cert_pkcs12}) && $request_options->{cert_file} ne '' && $request_options->{cert_pwd} ne '') {
        eval "use Net::SSL"; die $@ if $@;
        $ENV{HTTPS_PKCS12_FILE} = $request_options->{cert_file};
        $ENV{HTTPS_PKCS12_PASSWORD} = $request_options->{cert_pwd};
    }

    if (defined($self->{ssl_context}) && $self->{ssl_context} ne '') {
        my $context = new IO::Socket::SSL::SSL_Context(eval $self->{ssl_context});
        IO::Socket::SSL::set_default_context($context);
    }

    $self->{response} = $self->{ua}->request($req);

    $self->{headers} = $self->{response}->headers();
    return (0, $self->{response}->content);
}

sub get_headers {
    my ($self, %options) = @_;
    
    my $headers = '';
    foreach ($options{response}->header_field_names()) {
        $headers .= "$_: " . $options{response}->header($_) . "\n";
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
