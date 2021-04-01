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

package apps::pfsense::fauxapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use POSIX;
use JSON::XS;
use Digest::SHA;

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
            'api-key:s'    => { name => 'api_key' },
            'api-secret:s' => { name => 'api_secret' },
            'hostname:s'        => { name => 'hostname' },
            'port:s'            => { name => 'port' },
            'proto:s'           => { name => 'proto' },
            'timeout:s'         => { name => 'timeout' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);

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
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_key} = (defined($self->{option_results}->{api_key})) ? $self->{option_results}->{api_key} : '';
    $self->{api_secret} = (defined($self->{option_results}->{api_secret})) ? $self->{option_results}->{api_secret} : '';
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';

    if (!defined($self->{hostname}) || $self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }
    if ($self->{api_key} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-key option.");
        $self->{output}->option_exit();
    }
    if ($self->{api_secret} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-secret option.");
        $self->{output}->option_exit();
    }

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{timeout} = $self->{timeout};
}

sub build_fauxapi_header {
    my ($self, %options) = @_;

    my $timestamp = POSIX::strftime('%Y%m%dZ%H%M%S', gmtime());
    my $nonce = sprintf('%08X', rand(0xFFFFFFFF));
    my $hash = Digest::SHA::sha256_hex($self->{api_secret} . $timestamp . $nonce);
    return sprintf(
        '%s:%s:%s:%s',
        $self->{api_key},
        $timestamp,
        $nonce,
        $hash
    );
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub get_port {
    my ($self, %options) = @_;

    return $self->{port};
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    my $fauxapi_auth = $self->build_fauxapi_header();
    my $content = $self->{http}->request(
        url_path => '/fauxapi/v1/?action=' . $options{action},
        unknown_status => $self->{unknown_http_status},
        warning_status => $self->{warning_http_status},
        critical_status => $self->{critical_http_status},
        curl_backend_options => { header => ['fauxapi-auth:: ' . $fauxapi_auth] },
        lwp_backend_options => { header => [':fauxapi-auth: ' . $fauxapi_auth] }
    );

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    return $decoded;
}

1;

__END__

=head1 NAME

pfsense FauxAPI

=head1 REST API OPTIONS

pfsense FauxAPI

=over 8

=item B<--hostname>

pfsense hostname.

=item B<--port>

Port used (Default: 443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--api-key>

API key.

=item B<--api-secret>

API secret.

=item B<--timeout>

Set timeout in seconds (Default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
