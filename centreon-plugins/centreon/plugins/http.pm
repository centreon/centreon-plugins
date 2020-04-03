#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{noptions}) || $options{noptions} != 1) {
        $options{options}->add_options(arguments => {
            'http-peer-addr:s'  => { name => 'http_peer_addr' },
            'proxyurl:s'        => { name => 'proxyurl' },
            'proxypac:s'        => { name => 'proxypac' },
            'http-backend:s'    => { name => 'http_backend', default => 'lwp' },
        });
        $options{options}->add_help(package => __PACKAGE__, sections => 'HTTP GLOBAL OPTIONS');
    }

    centreon::plugins::misc::mymodule_load(
        output => $options{output},
        module => 'centreon::plugins::backend::http::lwp',
        error_msg => "Cannot load module 'centreon::plugins::backend::http::lwp'."
    );
    $self->{backend_lwp} = centreon::plugins::backend::http::lwp->new(%options);

    centreon::plugins::misc::mymodule_load(
        output => $options{output},
        module => 'centreon::plugins::backend::http::curl',
        error_msg => "Cannot load module 'centreon::plugins::backend::http::curl'."
    );
    $self->{backend_curl} = centreon::plugins::backend::http::curl->new(%options);

    $self->{output} = $options{output};
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

sub remove_header {
    my ($self, %options) = @_;

    delete $self->{add_headers}->{$options{key}} if (defined($self->{add_headers}->{$options{key}}));
}

sub check_options {
    my ($self, %options) = @_;

    $options{request}->{http_backend} = 'lwp'
        if (!defined($options{request}->{http_backend}) || $options{request}->{http_backend} eq '');
    $self->{http_backend} = $options{request}->{http_backend};
    if ($self->{http_backend} !~ /^\s*lwp|curl\s*$/i) {
        $self->{output}->add_option_msg(short_msg => "Unsupported http backend specified '" . $self->{http_backend} . "'.");
        $self->{output}->option_exit();
    }

    if (defined($options{request}->{$self->{http_backend} . '_backend_options'})) {
        foreach (keys %{$options{request}->{$self->{http_backend} . '_backend_options'}}) {
            $options{request}->{$_} = $options{request}->{$self->{http_backend} . '_backend_options'}->{$_};
        }
    }

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
    if ((defined($options{request}->{cert_pkcs12})) && (!defined($options{request}->{cert_file}) && !defined($options{request}->{cert_pwd}))) {
        $self->{output}->add_option_msg(short_msg => "You need to set --cert-file= and --cert-pwd= options when --pkcs12 is used");
        $self->{output}->option_exit();
    }

    $options{request}->{port_force} = $self->get_port();

    $options{request}->{headers} = {};
    if (defined($options{request}->{header})) {
        foreach (@{$options{request}->{header}}) {
            if (/^(:.+?|.+?):(.*)/) {
                $options{request}->{headers}->{$1} = $2;
            }
        }
    }
    foreach (keys %{$self->{add_headers}}) {
        $options{request}->{headers}->{$_} = $self->{add_headers}->{$_};
    }

    foreach my $method (('get', 'post')) {
        if (defined($options{request}->{$method . '_param'})) {
            $options{request}->{$method . '_params'} = {};
            foreach (@{$options{request}->{$method . '_param'}}) {
                if (/^([^=]+)={0,1}(.*)$/s) {
                    my $key = $1;
                    my $value = defined($2) ? $2 : 1;
                    if (defined($options{request}->{$method . '_params'}->{$key})) {
                        if (ref($options{request}->{$method . '_params'}->{$key}) ne 'ARRAY') {
                            $options{request}->{$method . '_params'}->{$key} = [ $options{request}->{$method . '_params'}->{$key} ];
                        }
                        push @{$options{request}->{$method . '_params'}->{$key}}, $value;
                    } else {
                        $options{request}->{$method . '_params'}->{$key} = $value;
                    }
                }
            }
        }
    }

    $self->{'backend_' . $self->{http_backend}}->check_options(%options);
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

sub request {
    my ($self, %options) = @_;

    my $request_options = { %{$self->{options}} };
    foreach (keys %options) {
        $request_options->{$_} = $options{$_} if (defined($options{$_}));
    }
    $self->check_options(request => $request_options);

    return $self->{'backend_' . $self->{http_backend}}->request(request => $request_options);
}

sub get_first_header {
    my ($self, %options) = @_;

    return $self->{'backend_' . $self->{http_backend}}->get_first_header(%options);
}

sub get_header {
    my ($self, %options) = @_;

    return $self->{'backend_' . $self->{http_backend}}->get_header(%options);
}

sub get_code {
    my ($self, %options) = @_;

    return $self->{'backend_' . $self->{http_backend}}->get_code();
}

sub get_message {
    my ($self, %options) = @_;

    return $self->{'backend_' . $self->{http_backend}}->get_message();
}

1;

__END__

=head1 NAME

HTTP abstraction layer.

=head1 SYNOPSIS

HTTP abstraction layer for lwp and curl backends

=head1 HTTP GLOBAL OPTIONS

=over 8

=item B<--http-peer-addr>

Set the address you want to connect (Useful if hostname is only a vhost. no ip resolve)

=item B<--proxyurl>

Proxy URL

=item B<--proxypac>

Proxy pac file (can be an url or local file)

=item B<--http-backend>

Set the backend used (Default: 'lwp')
For curl: --http-backend=curl

=back

=head1 DESCRIPTION

B<http>.

=cut
