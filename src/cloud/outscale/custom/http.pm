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

package cloud::outscale::custom::http;

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
            'osc-secret-key:s'  => { name => 'osc_secret_key' },
            'osc-access-key:s'  => { name => 'osc_access_key' },
            'region:s'          => { name => 'region' },
            'port:s'            => { name => 'port' },
            'proto:s'           => { name => 'proto' },
            'timeout:s'         => { name => 'timeout' },
            'api-path:s'        => { name => 'api_path' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
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

    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 50;
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';
    $self->{api_path} = (defined($self->{option_results}->{api_path})) ? $self->{option_results}->{api_path} : '/api/v1';

    if (!defined($self->{option_results}->{region}) || $self->{option_results}->{region} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --region option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{osc_access_key}) || $self->{option_results}->{osc_access_key} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --osc-access-key option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{osc_secret_key}) || $self->{option_results}->{osc_secret_key} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --osc-secret-key option.");
        $self->{output}->option_exit();
    }

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

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
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    my $content = $self->{http}->request(
        hostname => 'api.' . $self->{option_results}->{region} . '.outscale.com',
        method => $options{method},
        url_path => $self->{api_path} . $options{endpoint},
        get_param => $options{get_param},
        header => $options{header},
        query_form_post => $options{query_form_post},
        credentials => 1,
        username => $self->{option_results}->{osc_access_key},
        password => $self->{option_results}->{osc_secret_key},
        curl_opt => ["CURLOPT_AWS_SIGV4 => 'osc'"],
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
        $decoded = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub load_balancer_read {
    my ($self, %options) = @_;

    my $raw_results = $self->request_api(
        method => 'POST',
        endpoint => '/ReadLoadBalancers',
        header => ['Content-Type: application/json'],
        query_form_post => ''
    );

    return $raw_results->{LoadBalancers};
}

sub read_vms_health {
    my ($self, %options) = @_;

    my $post;
    eval {
        $post = JSON::XS->new->utf8->encode({ LoadBalancerName => $options{load_balancer_name} });
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => 'cannot encode json request');
        $self->{output}->option_exit();
    }

    my $raw_results = $self->request_api(
        method => 'POST',
        endpoint => '/ReadVmsHealth',
        header => ['Content-Type: application/json'],
        query_form_post => $post
    );

    return $raw_results->{BackendVmHealth};
}

sub read_vms {
    my ($self, %options) = @_;

    my $raw_results = $self->request_api(
        method => 'POST',
        endpoint => '/ReadVms',
        header => ['Content-Type: application/json'],
        query_form_post => ''
    );

    return $raw_results->{Vms};
}

sub read_client_gateways {
    my ($self, %options) = @_;

    my $raw_results = $self->request_api(
        method => 'POST',
        endpoint => '/ReadClientGateways',
        header => ['Content-Type: application/json'],
        query_form_post => ''
    );

    return $raw_results->{ClientGateways};
}

sub read_consumption_account {
    my ($self, %options) = @_;

    my $post;
    eval {
        $post = JSON::XS->new->utf8->encode({ FromDate => $options{from_date}, ToDate => $options{to_date} });
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => 'cannot encode json request');
        $self->{output}->option_exit();
    }

    my $raw_results = $self->request_api(
        method => 'POST',
        endpoint => '/ReadConsumptionAccount',
        header => ['Content-Type: application/json'],
        query_form_post => $post
    );

    return $raw_results->{ConsumptionEntries};
}

sub read_virtual_gateways {
    my ($self, %options) = @_;

    my $raw_results = $self->request_api(
        method => 'POST',
        endpoint => '/ReadVirtualGateways',
        header => ['Content-Type: application/json'],
        query_form_post => ''
    );

    return $raw_results->{VirtualGateways};
}

sub read_vpn_connections {
    my ($self, %options) = @_;

    my $raw_results = $self->request_api(
        method => 'POST',
        endpoint => '/ReadVpnConnections',
        header => ['Content-Type: application/json'],
        query_form_post => ''
    );

    return $raw_results->{VpnConnections};
}

sub read_volumes {
    my ($self, %options) = @_;

    my $raw_results = $self->request_api(
        method => 'POST',
        endpoint => '/ReadVolumes',
        header => ['Content-Type: application/json'],
        query_form_post => ''
    );

    return $raw_results->{Volumes};
}

sub read_nets {
    my ($self, %options) = @_;

    my $raw_results = $self->request_api(
        method => 'POST',
        endpoint => '/ReadNets',
        header => ['Content-Type: application/json'],
        query_form_post => ''
    );

    return $raw_results->{Nets};
}

sub read_quotas {
    my ($self, %options) = @_;

    my $raw_results = $self->request_api(
        method => 'POST',
        endpoint => '/ReadQuotas',
        header => ['Content-Type: application/json'],
        query_form_post => ''
    );

    return $raw_results->{QuotaTypes};
}

sub read_subnets {
    my ($self, %options) = @_;

    my $raw_results = $self->request_api(
        method => 'POST',
        endpoint => '/ReadSubnets',
        header => ['Content-Type: application/json'],
        query_form_post => ''
    );

    return $raw_results->{Subnets};
}

sub read_route_tables {
    my ($self, %options) = @_;

    my $raw_results = $self->request_api(
        method => 'POST',
        endpoint => '/ReadRouteTables',
        header => ['Content-Type: application/json'],
        query_form_post => ''
    );

    return $raw_results->{RouteTables};
}

sub read_internet_services {
    my ($self, %options) = @_;

    my $raw_results = $self->request_api(
        method => 'POST',
        endpoint => '/ReadInternetServices',
        header => ['Content-Type: application/json'],
        query_form_post => ''
    );

    return $raw_results->{InternetServices};
}

sub read_nat_services {
    my ($self, %options) = @_;

    my $raw_results = $self->request_api(
        method => 'POST',
        endpoint => '/ReadNatServices',
        header => ['Content-Type: application/json'],
        query_form_post => ''
    );

    return $raw_results->{NatServices};
}

1;

__END__

=head1 NAME

Outscale Rest API

=head1 REST API OPTIONS

Outscale Rest API

=over 8

=item B<--osc-secret-key>

Set Outscale secret key.

=item B<--osc-access-key>

Set Outscale access key.

=item B<--region>

Set the region name (required).

=item B<--port>

Port used (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--token>

API token.

=item B<--timeout>

Set timeout in seconds (default: 50).

=back

=head1 DESCRIPTION

B<custom>.

=cut
