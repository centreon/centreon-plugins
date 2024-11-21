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

package centreon::vmware::http::http;

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    $self->{logger} = $options{logger};
    $self->{options} = {
        proto => 'http',
        url_path => '/',
        timeout => 5,
        method => 'GET',
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

sub mymodule_load {
    my ($self, %options) = @_;
    my $file;
    ($file = ($options{module} =~ /\.pm$/ ? $options{module} : $options{module} . '.pm')) =~ s{::}{/}g;

    eval {
        local $SIG{__DIE__} = 'IGNORE';
        require $file;
        $file =~ s{/}{::}g;
        $file =~ s/\.pm$//;
    };
    if ($@) {
        $self->{logger}->writeLogError('[core] ' . $options{error_msg} . ' - ' . $@);
        return 1;
    }
    return wantarray ? (0, $file) : 0;
}

sub check_options {
    my ($self, %options) = @_;

    $options{request}->{http_backend} = 'curl'
        if (!defined($options{request}->{http_backend}) || $options{request}->{http_backend} eq '');
    $self->{http_backend} = $options{request}->{http_backend};
    if ($self->{http_backend} !~ /^\s*lwp|curl\s*$/i) {
        $self->{logger}->writeLogError("Unsupported http backend specified '" . $self->{http_backend} . "'.");
        return 1;
    }

    if (!defined($self->{backend_lwp}) && !defined($self->{backend_curl})) {
        if ($options{request}->{http_backend} eq 'lwp' && $self->mymodule_load(
            logger => $options{logger}, module => 'centreon::vmware::http::backend::lwp',
            error_msg => "Cannot load module 'centreon::vmware::http::backend::lwp'."
            ) == 0) {
            $self->{backend_lwp} = centreon::vmware::http::backend::lwp->new(%options, logger => $self->{logger});
        }

        if ($options{request}->{http_backend} eq 'curl' && $self->mymodule_load(
            logger => $options{logger}, module => 'centreon::vmware::http::backend::curl',
            error_msg => "Cannot load module 'centreon::vmware::http::backend::curl'."
            ) == 0) {
            $self->{backend_curl} = centreon::vmware::http::backend::curl->new(%options, logger => $self->{logger});
        }
    }

    if (($options{request}->{proto} ne 'http') && ($options{request}->{proto} ne 'https')) {
        $self->{logger}->writeLogError("Unsupported protocol specified '" . $self->{option_results}->{proto} . "'.");
        return 1;
    }
    if (!defined($options{request}->{hostname})) {
        $self->{logger}->writeLogError("Please set the hostname option");
        return 1;
    }
    if ((defined($options{request}->{credentials})) && (!defined($options{request}->{username}) || !defined($options{request}->{password}))) {
        $self->{logger}->writeLogError("You need to set --username= and --password= options when --credentials is used");
        return 1;
    }
    if ((defined($options{request}->{cert_pkcs12})) && (!defined($options{request}->{cert_file}) && !defined($options{request}->{cert_pwd}))) {
        $self->{logger}->writeLogError("You need to set --cert-file= and --cert-pwd= options when --pkcs12 is used");
        return 1;
    }

    $options{request}->{port_force} = $self->get_port();

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
            $options{request}->{$method . '_params'} = {};
            foreach (@{$options{request}->{$method . '_param'}}) {
                if (/^([^=]+)={0,1}(.*)$/) {
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
    
    $self->{ 'backend_' . $self->{http_backend} }->check_options(%options);
    return 0;
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
    return 1 if ($self->check_options(request => $request_options));

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
