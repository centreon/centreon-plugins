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
package storage::datacore::restapi::custom::api;
use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use centreon::plugins::misc qw(empty);

sub new {
    my ($class, %options) = @_;
    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    my $self = {};
    bless $self, $class;


    $options{options}->add_options(arguments => {
        'hostname:s'             => { name => 'hostname' },
        'port:s'                 => { name => 'port', default => 443 },
        'proto:s'                => { name => 'proto', default => 'https' },
        'timeout:s'              => { name => 'timeout' },
        'username:s'             => { name => 'username' },
        'password:s'             => { name => 'password' },
        'unknown-http-status:s'  => { name => 'unknown_http_status' },
        'warning-http-status:s'  => { name => 'warning_http_status' },
        'critical-http-status:s' => { name => 'critical_http_status' }
    });

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

# hostname,username and password are required options
sub check_options {
    my ($self, %options) = @_;
    $self->{http}->set_options(%{$self->{option_results}});

    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 50;

    if (centreon::plugins::misc::is_empty($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => 'Please set hostname option');
        $self->{output}->option_exit();
    }
    if (centreon::plugins::misc::is_empty($self->{option_results}->{username})) {
        $self->{output}->add_option_msg(short_msg => 'Please set username option to authenticate against datacore rest api');
        $self->{output}->option_exit();
    }
    if (centreon::plugins::misc::is_empty($self->{option_results}->{password})) {
        $self->{output}->add_option_msg(short_msg => 'Please set password option to authenticate against datacore rest api');
        $self->{output}->option_exit();
    }

}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->{http}->add_header(key => 'ServerHost', value => $self->{option_results}->{hostname});
    $self->{http}->set_options(basic => 1, credentials => 1);
    $self->{settings_done} = 1;
}

# wrapper around centreon::plugins::http::request to add authentication and decode json.
# output : deserialized json from the api if not error found in http call.
sub request_api {
    my ($self, %options) = @_;
    $self->settings();

    # datacore api require a ServerHost header with the hostname used to query the api to respond.
    # authentication is http standard basic auth.
    my $result = $self->{http}->request(
        username        => $self->{option_results}->{username},
        password        => $self->{option_results}->{password},
        unknown_status  => $self->{option_results}->{unknown_http_status},
        warning_status  => $self->{option_results}->{warning_http_status},
        critical_status => $self->{option_results}->{critical_http_status},
        %options,
    );
    # Declare a scalar to deserialize the JSON content string into a perl data structure
    my $decoded_content;
    eval {
        $decoded_content = JSON::XS->new->decode($result);
    };
    # Catch the error that may arise in case the data received is not JSON
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode JSON result");
        $self->{output}->option_exit();
    }
    return $decoded_content;

}
1;


__END__

=head1 NAME

Datacore Sansymphony Rest API

=head1 REST API OPTIONS

Datacore Sansymphony Rest API

=over 8

=item B<--hostname>

Address of the Datacore server that hosts the API endpoint.

=item B<--port>

Port of the resource to connect to (default: 443).

=item B<--proto>

HTTP protocol, either http or https (default: 'https')

=item B<--username>

Username to access the endpoint.

=item B<--password>

Password to access the endpoint.

=item B<--timeout>

Set timeout in seconds (default: 10).

=back

=head1 DESCRIPTION

B<custom>.
