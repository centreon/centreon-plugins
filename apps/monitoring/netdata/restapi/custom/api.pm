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

package apps::monitoring::netdata::restapi::custom::api;

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
            'hostname:s' => { name => 'hostname' },
            'port:s'     => { name => 'port' },
            'proto:s'    => { name => 'proto' },
            'timeout:s'  => { name => 'timeout' },
            'endpoint:s' => { name => 'endpoint'}
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
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 19999;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'http';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{endpoint} = (defined($self->{option_results}->{endpoint})) ? $self->{option_results}->{endpoint} : '/api/v1';

    if ($self->{hostname} eq '') {
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
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
    $self->{option_results}->{unknown_status} = '%{http_code} < 200 or %{http_code} >= 400';
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    my $content = $self->{http}->request(%options);

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
    if (defined($decoded->{error_code})) {
        $self->{output}->output_add(long_msg => "Error message : " . $decoded->{error}, debug => 1);
        $self->{output}->add_option_msg(short_msg => "API returns error code '" . $decoded->{error_code} . "' (add --debug option for detailed message)");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub get_alarms {
    my ($self, %options) = @_;

    my $url_path = $self->{endpoint} . '/alarms';
    my $response = $self->request_api(method => 'GET', url_path => $url_path);

    return $response;
}

sub list_charts {
    my ($self, %options) = @_;

    my $url_path = $self->{endpoint} . '/charts';
    my $response = $self->request_api(
        method => 'GET',
        url_path => $url_path
    );

    return $response;
}

sub get_chart_properties {
    my ($self, %options) = @_;

    my $url_path = $self->{endpoint} . '/chart';
    my $response = $self->request_api(
        method => 'GET',
        url_path => $url_path,
        get_param => ['chart=' . $options{chart}]
    );
    my $filter_info = defined ($options{filter_info}) ? $options{filter_info} : '';

    return defined ($filter_info) ? $response->{$filter_info} : $response;
}

sub get_data {
    my ($self, %options) = @_;

    my $url_path = $self->{endpoint} . '/data';
    my $get_param = [
        'chart=' . $options{chart},
        'options=null2zero',
        'after=-' . $options{after_period},
        'group=' . $options{group},
        defined($options{points}) ? 'points=' . $options{points} : 'points=1'
    ];
    push @$get_param, 'options=abs' if (defined($options{absolute}));
    push @$get_param, 'dimensions=' . $options{dimensions} if (defined($options{dimensions}));

    my $response = $self->request_api(
        method => 'GET',
        url_path => $url_path,
        get_param => $get_param
    );

    return $response;
}

sub get_info {
     my ($self, %options) = @_;

    my $url_path = $self->{endpoint} . '/info';
    my $response = $self->request_api(method => 'GET', url_path => $url_path);
    my $filter_info = defined ($options{filter_info}) ? $options{filter_info} : '';
    return defined ($filter_info) ? $response->{$filter_info} : $response;
}

1;

__END__

=head1 NAME

Netdata Rest API

=head1 REST API OPTIONS

Netdata Rest API

=over 8

=item B<--hostname>

Netdata API hostname (server address)

=item B<--port>

Port used (Default: 19999)

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--timeout>

Set timeout in seconds (Default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
