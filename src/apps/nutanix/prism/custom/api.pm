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

package apps::nutanix::prism::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;
use MIME::Base64;

sub new {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->option_exit(short_msg => "Class Custom: Need to specify 'options' argument.");
    }

    if (!defined($options{noptions})) {
        $options{options}->add_options(
            arguments => {
                'hostname:s' => { name => 'hostname' },
                'port:s'     => { name => 'port',    default => '9440' },
                'proto:s'    => { name => 'proto',   default => 'https' },
                'username:s' => { name => 'username' },
                'password:s' => { name => 'password' },
                'timeout:s'  => { name => 'timeout', default => 30 },
            }
        );
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http}   = centreon::plugins::http->new(%options, default_backend => 'curl');

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
    $self->{port}     = $self->{option_results}->{port};
    $self->{proto}    = $self->{option_results}->{proto};
    $self->{username} = (defined($self->{option_results}->{username})) ? $self->{option_results}->{username} : '';
    $self->{password} = (defined($self->{option_results}->{password})) ? $self->{option_results}->{password} : '';
    $self->{timeout}  = $self->{option_results}->{timeout};

    if ($self->{hostname} eq '') {
        $self->{output}->option_exit(short_msg => "Need to specify --hostname option.");
    }
    if ($self->{username} eq '') {
        $self->{output}->option_exit(short_msg => "Need to specify --username option.");
    }
    if ($self->{password} eq '') {
        $self->{output}->option_exit(short_msg => "Need to specify --password option.");
    }

    return 0;
}

sub _get_auth_header {
    my ($self) = @_;

    my $auth = MIME::Base64::encode_base64($self->{username} . ':' . $self->{password});
    chomp $auth;
    return 'Authorization: Basic ' . $auth;
}

sub request_api {
    my ($self, %options) = @_;

    # Prism utilise le port 9440 par défaut et un préfixe /api/nutanix/v2.0
    my $url = $self->{proto} . '://' . $self->{hostname} . ':' . $self->{port};

    $self->{option_results}->{hostname}        = $self->{hostname};
    $self->{option_results}->{port}            = $self->{port};
    $self->{option_results}->{proto}           = $self->{proto};
    $self->{option_results}->{timeout}         = $self->{timeout};
    $self->{option_results}->{warning_status}  = '';
    $self->{option_results}->{critical_status} = '';
    $self->{option_results}->{unknown_status}  = '%{http_code} < 200 or %{http_code} >= 300';

    $self->{http}->set_options(%{$self->{option_results}});

    my $method = (defined($options{method})) ? $options{method} : 'GET';
    my @headers = (
        $self->_get_auth_header(),
        'Content-Type: application/json',
        'Accept: application/json',
    );

    my ($content) = $self->{http}->request(
        method          => $method,
        url_path        => $options{endpoint},
        header          => \@headers,
        get_param       => $options{get_param},
        query_form_post => $options{query_form_post},
        insecure        => 1,  # Les déploiements Nutanix utilisent souvent des certs auto-signés
    );

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(
            short_msg => "API returned empty content [code: '"
                . $self->{http}->get_code() . "'] [message: '"
                . $self->{http}->get_message() . "']"
        );
        $self->{output}->option_exit();
    }

    my $decoded;
    eval { $decoded = decode_json($content) };
    if ($@) {
        $self->{output}->add_option_msg(
            short_msg => "Cannot decode JSON response: $@ [content: $content]"
        );
        $self->{output}->option_exit();
    }

    return $decoded;
}

# Retourne les infos du/des clusters Nutanix
sub get_clusters {
    my ($self, %options) = @_;
    return $self->request_api(endpoint => '/api/nutanix/v2.0/clusters');
}

# Retourne la liste des hôtes physiques
sub get_hosts {
    my ($self, %options) = @_;
    return $self->request_api(endpoint => '/api/nutanix/v2.0/hosts');
}

# Retourne la liste des VMs
sub get_vms {
    my ($self, %options) = @_;
    return $self->request_api(endpoint => '/api/nutanix/v2.0/vms');
}

# Retourne les pools de stockage
sub get_storage_pools {
    my ($self, %options) = @_;
    return $self->request_api(endpoint => '/api/nutanix/v2.0/storage_pools');
}

1;

__END__

=head1 NAME

apps::nutanix::prism::custom::api - Custom module for Nutanix Prism REST API.

=head1 SYNOPSIS

    use apps::nutanix::prism::custom::api;

=head1 DESCRIPTION

This module handles authentication and HTTP requests to the Nutanix Prism REST API.
It uses HTTP Basic Auth (username:password in Base64) on every request.
The default port is 9440 and the protocol is HTTPS.
Self-signed certificates are accepted (insecure => 1).

=head1 REST API OPTIONS

=over 4

=item B<--hostname>

Nutanix Prism hostname or IP address.

=item B<--port>

API port (default: 9440).

=item B<--proto>

Protocol (default: https).

=item B<--username>

API username.

=item B<--password>

API password.

=item B<--timeout>

HTTP request timeout in seconds (default: 30).

=back

=cut
