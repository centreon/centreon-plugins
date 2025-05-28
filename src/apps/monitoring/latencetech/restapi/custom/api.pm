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

package apps::monitoring::latencetech::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;
use Digest::MD5 qw(md5_hex);

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
            'agent-id:s'    => { name => 'agent_id' },
            'api-key:s'     => { name => 'api_key' },
            'api-path:s'    => { name => 'api_path', default => '/api/v1' },
            'customer-id:s' => { name => 'customer_id' },
            'hostname:s'    => { name => 'hostname' },
            'port:s'        => { name => 'port' },
            'proto:s'       => { name => 'proto' },
            'timeout:s'     => { name => 'timeout' }
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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : undef;
    $self->{customer_id} = (defined($self->{option_results}->{customer_id})) ? $self->{option_results}->{customer_id} : undef;
    $self->{agent_id} = (defined($self->{option_results}->{agent_id})) ? $self->{option_results}->{agent_id} : undef;
    $self->{api_key} = (defined($self->{option_results}->{api_key})) ? $self->{option_results}->{api_key} : '';
    $self->{api_path} = (defined($self->{option_results}->{api_path})) ? $self->{option_results}->{api_path} : '';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : '12099';
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';

    if (!defined($self->{hostname}) || $self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{customer_id}) || $self->{customer_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --customer-id option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{api_key}) || $self->{api_key} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-key option.");
        $self->{output}->option_exit();
    }

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
    $self->{option_results}->{unknown_status} = '%{http_code} < 200 or %{http_code} >= 500';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->add_header(key => 'x-api-key', value => $self->{api_key});
    $self->{http}->set_options(%{$self->{option_results}});
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();

    my ($json, $response);
    my $get_param = [ "customer_id=$self->{customer_id}" ];
    if (defined($self->{option_results}->{agent_id}) && $self->{option_results}->{agent_id} ne '') {
        push(@$get_param, "agent_id=$self->{option_results}->{agent_id}");
    }
    if (defined($options{get_param})) {
        push(@$get_param, @{$options{get_param}});
    }

    $response = $self->{http}->request(
        get_param => $get_param,
        method => $options{method},
        url_path => $self->{api_path} . $options{endpoint},
    );

    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->output_add(long_msg => $response);
        $self->{output}->option_exit();
    }    
    eval {
        $json = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode JSON response: $response");
        $self->{output}->option_exit();
    };

    return $json;
}

1;

__END__

=head1 NAME

LatenceTech Rest API

=head1 REST API OPTIONS

LatenceTech Rest API

=over 8

=item B<--hostname>

Set Latencetech hostname or IP address

=item B<--port>

Port used (default: 12099)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--api-path>

Set API path (default: '/api/v1')

=item B<--api-key>

Set API key (mandatory)

=item B<--customer-id>

Set cutomer/network ID (mandatory)

=item B<--agent-id>

Set Agent ID (for modes that require it).

=item B<--timeout>

Set timeout in seconds (default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
