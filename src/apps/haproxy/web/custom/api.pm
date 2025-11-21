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

package apps::haproxy::web::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;

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
            'basic'                  => { name => 'basic' },
            'credentials'            => { name => 'credentials' },
            'hostname:s'             => { name => 'hostname' },
            'ntlmv2'                 => { name => 'ntlmv2' },
            'password:s'             => { name => 'password' },
            'port:s'                 => { name => 'port' },
            'proto:s'                => { name => 'proto' },
            'timeout:s'              => { name => 'timeout' },
            'urlpath:s'              => { name => 'url_path' },
            'username:s'             => { name => 'username' },
            'critical-http-status:s' => { name => 'critical_http_status' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' }
        });
    }

    $options{options}->add_help(package => __PACKAGE__, sections => 'API OPTIONS', once => 1);

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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : undef;
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 8404;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'http';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{url_path} = (defined($self->{option_results}->{url_path})) ? $self->{option_results}->{url_path} : '/stats;json;';
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '(%{http_code} < 200 or %{http_code} >= 300) and %{http_code} != 424';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';

    if (!defined($self->{hostname}) || $self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
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

sub get_stats {
    my ($self, %options) = @_;
    $self->settings();
    my $response = $self->{http}->request(method => 'GET', url_path  => $self->{url_path});

    if (!defined($response) || $response eq '') {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->decode($response);
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->{output}->add_option_msg(short_msg => 'API request error (add --debug option to display returned content)');
        $self->{output}->option_exit();
    }

    return $decoded;
}

1;

__END__

=head1 NAME

HAProxy HTTP custom mode for web json stats

=head1 API OPTIONS

HAProxy web stats

=over 8

=item B<--hostname>

IP address or FQDN of the HAProxy server.

=item B<--port>

Port used by the web server

=item B<--proto>

Specify https if needed (default: 'http')

=item B<--urlpath>

Define the path of the web page to get (default: '/stats;json;').

=item B<--credentials>

Specify this option if you are accessing a web page using authentication.

=item B<--username>

Specify the username for authentication (mandatory if --credentials is specified).

=item B<--password>

Specify the password for authentication (mandatory if --credentials is specified).

=item B<--basic>

Specify this option if you are accessing a web page using basic authentication and don't want a '401 UNAUTHORIZED' error to be logged on your web server.

Specify this option if you are accessing a web page using hidden basic authentication or you'll get a '404 NOT FOUND' error.

(use with --credentials)

=item B<--ntlmv2>

Specify this option if you are accessing a web page using NTLMv2 authentication (use with C<--credentials> and C<--port> options).

=item B<--timeout>

Define the timeout in seconds (default: 5).


=back

=cut
