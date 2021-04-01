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

package apps::openweathermap::restapi::custom::api;

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
            'hostname:s'  => { name => 'hostname' },
            'url-path:s'  => { name => 'url_path' },
            'port:s'      => { name => 'port' },
            'proto:s'     => { name => 'proto' },
            'api-token:s' => { name => 'api_token' },
            'timeout:s'   => { name => 'timeout' }
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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : 'api.openweathermap.org';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{url_path} = (defined($self->{option_results}->{url_path})) ? $self->{option_results}->{url_path} : '/data/2.5';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_token} = (defined($self->{option_results}->{api_token})) ? $self->{option_results}->{api_token} : '';

    if (!defined($self->{api_token}) || $self->{api_token} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-token option.");
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
    $self->{option_results}->{url_path} = $self->{url_path};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');

    $self->{http}->set_options(%{$self->{option_results}});
}

sub set_token {
    my ($self, %options) = @_;
    push @{$self->{get_param}}, 'APPID=' . $self->{api_token};
}

sub request_api {
    my ($self, %options) = @_;

    $self->set_token();
    $self->settings;

    foreach my $get_param (@{$options{get_param}}) {
        push @{$self->{get_param}}, $get_param;
    }
    my $content = $self->{http}->request(
        url_path => $self->{url_path} . $options{url_path},
        get_param => \@{$self->{get_param}}
    );

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }
    if (!defined($decoded->{cod}) || $decoded->{cod} != 200) {
        $self->{output}->output_add(long_msg => "Error message : " . $decoded->{errorDetails}, debug => 1);
        $self->{output}->add_option_msg(short_msg => "API return error code '" . $decoded->{result} . "' (add --debug option for detailed message)");
        $self->{output}->option_exit();
    }
    return $decoded;
}

1;

__END__

=head1 NAME

OpenWeatherMap Rest API

=head1 SYNOPSIS

OpenWeatherMap Rest API custom mode

=head1 REST API OPTIONS

OpenWeatherMap Rest API

=over 8

=item B<--hostname>

OpenWeatherMap API hostname (Default: 'api.openweathermap.org')

=item B<--port>

API port (Default: 443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--url-path>

API URL path (Default: '/data/2.5')

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
