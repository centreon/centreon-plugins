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

package cloud::prometheus::alertmanager::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;
use centreon::plugins::misc qw/is_empty json_decode/;
use centreon::plugins::constants qw(:messages);

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
        $options{options}->add_options(arguments => {
            'hostname:s'             => { name => 'hostname' },
            'url-path:s'             => { name => 'url_path', default => '/api/v2' },
            'port:s'                 => { name => 'port', default => 9093 },
            'proto:s'                => { name => 'proto', default => 'http' },
            'credentials'            => { name => 'credentials' },
            'basic'                  => { name => 'basic' },
            'username:s'             => { name => 'username' },
            'password:s'             => { name => 'password' },
            'timeout:s'              => { name => 'timeout', default => 10 },
            'unknown-http-status:s'  => { name => 'unknown_http_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
            'warning-http-status:s'  => { name => 'warning_http_status', default => '' },
            'critical-http-status:s' => { name => 'critical_http_status', default => '' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    if (is_empty($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
        $self->{output}->option_exit();
    }

    return 0;
}

sub settings {
    my ($self, %options) = @_;

    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{option_results}->{hostname} . ":" . $self->{option_results}->{port};
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{option_results}->{hostname};
}

sub get_port {
    my ($self, %options) = @_;

    return $self->{option_results}->{port};
}

sub get_endpoint {
    my ($self, %options) = @_;

    $self->settings();
    my $response = $self->{http}->request(
        url_path        => $self->{option_results}->{url_path} . $options{endpoint},
        unknown_status  => $self->{option_results}->{unknown_http_status},
        warning_status  => $self->{option_results}->{warning_http_status},
        critical_status => $self->{option_results}->{critical_http_status}
    );

    my $content = json_decode($response,
                              errstr => MSG_JSON_DECODE_ERROR,
                              output => $self->{output});

    return $content;
}

1;

__END__

=head1 NAME

Prometheus Alertmanager Rest API.

=head1 SYNOPSIS

Prometheus Alertmanager Rest API custom mode.

=head1 REST API OPTIONS

Prometheus Alertmanager Rest API.

=over 8

=item B<--hostname>

Prometheus hostname.

=item B<--url-path>

API url path (default: '/api/v2').

=item B<--port>

API port (default: 9093).

=item B<--proto>

Specify the protocol (default: 'http').

=item B<--credentials>

Specify this option if you access the API with authentication.

=item B<--username>

Specify the username for authentication (mandatory if C<--credentials> is specified).

=item B<--password>

Specify the password for authentication (mandatory if C<--credentials> is specified).

=item B<--basic>

Specify this option if you access the API over basic authentication and don't want a C<401 UNAUTHORIZED> error to be logged on your web server.

Specify this option if you access the API over hidden basic authentication or you'll get a C<404 NOT FOUND> error.

(use with C<--credentials>).

=item B<--timeout>

Set HTTP timeout.

=back

=head1 DESCRIPTION

B<custom>.

=cut
