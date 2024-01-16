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

package os::as400::connector::custom::api;

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
            'connector-api-username:s' => { name => 'connector_api_username' },
            'connector-api-password:s' => { name => 'connector_api_password' },
            'connector-hostname:s'     => { name => 'connector_hostname' },
            'connector-port:s'         => { name => 'connector_port' },
            'connector-proto:s'        => { name => 'connector_proto' },
            'connector-timeout:s'      => { name => 'connector_timeout' },
            'unknown-http-status:s'    => { name => 'unknown_http_status' },
            'warning-http-status:s'    => { name => 'warning_http_status' },
            'critical-http-status:s'   => { name => 'critical_http_status' },
            'as400-hostname:s'         => { name => 'as400_hostname' },
            'as400-username:s'         => { name => 'as400_username' },
            'as400-password:s'         => { name => 'as400_password' }
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

    $self->{connector_hostname} = (defined($self->{option_results}->{connector_hostname})) ? $self->{option_results}->{connector_hostname} : '127.0.0.1';
    $self->{connector_port} = (defined($self->{option_results}->{connector_port})) ? $self->{option_results}->{connector_port} : 8091;
    $self->{connector_proto} = (defined($self->{option_results}->{connector_proto})) ? $self->{option_results}->{connector_proto} : 'http';
    $self->{connector_timeout} = (defined($self->{option_results}->{connector_timeout})) ? $self->{option_results}->{connector_timeout} : 50;
    $self->{connector_api_username} = (defined($self->{option_results}->{connector_api_username})) ? $self->{option_results}->{connector_api_username} : '';
    $self->{connector_api_password} = (defined($self->{option_results}->{connector_api_password})) ? $self->{option_results}->{connector_api_password} : '';
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';
    $self->{as400_hostname} = (defined($self->{option_results}->{as400_hostname})) ? $self->{option_results}->{as400_hostname} : '';
    $self->{as400_username} = (defined($self->{option_results}->{as400_username})) ? $self->{option_results}->{as400_username} : '';
    $self->{as400_password} = (defined($self->{option_results}->{as400_password})) ? $self->{option_results}->{as400_password} : '';

    if ($self->{connector_hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --connector-hostname option.");
        $self->{output}->option_exit();
    }
    if ($self->{connector_api_username} ne '' && $self->{connector_api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --connector-api-password option.");
        $self->{output}->option_exit();
    }
    if ($self->{as400_hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --as400-hostname option.");
        $self->{output}->option_exit();
    }
    if ($self->{as400_username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --as400-username option.");
        $self->{output}->option_exit();
    }
    if ($self->{as400_password} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --as400-password option.");
        $self->{output}->option_exit();
    }

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{connector_hostname};
    $self->{option_results}->{timeout} = $self->{connector_timeout};
    $self->{option_results}->{port} = $self->{connector_port};
    $self->{option_results}->{proto} = $self->{connector_proto};
    $self->{option_results}->{timeout} = $self->{connector_timeout};
    if ($self->{connector_api_username} ne '') {
        $self->{option_results}->{credentials} = 1;
        $self->{option_results}->{basic} = 1;
        $self->{option_results}->{username} = $self->{connector_api_username};
        $self->{option_results}->{password} = $self->{connector_api_password};
    }
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{as400_hostname};
}

sub request_api {
    my ($self, %options) = @_;

    my $post = {
        host => $self->{as400_hostname},
        login => $self->{as400_username},
        password => $self->{as400_password},
        command => $options{command}
    };
    $post->{args} = $options{args} if (defined($options{args}));
    my $encoded;
    eval {
        $encoded = encode_json($post);
    };

    $self->settings();
    my $content = $self->{http}->request(
        method => 'POST',
        query_form_post => $encoded,
        url_path => '/',
        unknown_status => $self->{unknown_http_status},
        warning_status => $self->{warning_http_status},
        critical_status => $self->{critical_http_status}
    );

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->decode($self->{output}->decode($content));
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }
    if (defined($decoded->{code}) && $decoded->{code} != 0) {
        $self->{output}->add_option_msg(short_msg => $decoded->{message});
        $self->{output}->option_exit();
    }

    return $decoded;
}

1;

__END__

=head1 NAME

Centreon AS400 connector Rest API

=head1 REST API OPTIONS

Centreon AS400 connector Rest API

=over 8

=item B<--connector-hostname>

Centreon connector hostname (default: 127.0.0.1)

=item B<--connector-port>

Port used (default: 8091)

=item B<--connector-proto>

Specify https if needed (default: 'http')

=item B<--connector-username>

API username.

=item B<--connector-password>

API password.

=item B<--connector-timeout>

Set timeout in seconds (default: 50)

=item B<--as400-hostname>

AS/400 hostname (required)

=item B<--as400-username>

AS/400 username (required)

=item B<--as400-password>

AS/400 password (required)

=back

=head1 DESCRIPTION

B<custom>.

=cut
