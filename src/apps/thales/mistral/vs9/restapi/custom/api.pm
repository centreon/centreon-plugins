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

package apps::thales::mistral::vs9::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
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
            'api-username:s'    => { name => 'api_username' },
            'api-password:s'    => { name => 'api_password' },
            'hostname:s'        => { name => 'hostname' },
            'port:s'            => { name => 'port' },
            'proto:s'           => { name => 'proto' },
            'timeout:s'         => { name => 'timeout' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' },
            'reload-cache-time:s'    => { name => 'reload_cache_time', default => 60 }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
    $self->{cache} = centreon::plugins::statefile->new(%options);
    $self->{cache_connect} = centreon::plugins::statefile->new(output => $options{output});

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{option_results}->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 5572;
    $self->{option_results}->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{option_results}->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';

    if ($self->{option_results}->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-username option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-password option.');
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results});
    $self->{cache_connect}->check_options(option_results => $self->{option_results});

    return 0;
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{settings_done} = 1;
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{option_results}->{hostname} . ':' . $self->{option_results}->{port};
}

sub get_token {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache_connect}->read(statefile => 'thales_mistral_connect_' . md5_hex($self->get_connection_info() . '_' . $self->{api_username}));
    my $token = $self->{cache_connect}->get(name => 'token');
    my $md5_secret_cache = $self->{cache_connect}->get(name => 'md5_secret');
    my $md5_secret = md5_hex($self->{api_username} . $self->{api_password});

    if ($has_cache_file == 0 ||
        !defined($token) ||
        (defined($md5_secret_cache) && $md5_secret_cache ne $md5_secret)
        ) {
        my $json_request = {
            username => $self->{api_username},
            password => $self->{api_password}
        };
        my $encoded;
        eval {
            $encoded = encode_json($json_request);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => 'cannot encode json request');
            $self->{output}->option_exit();
        }

        $self->settings();
        my $content = $self->{http}->request(
            method => 'POST',
            url_path => '/api/auth/login',
            query_form_post => $encoded,
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status},
            header => ['Content-Type: application/json']
        );

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
            $self->{output}->option_exit();
        }

        $token = $decoded->{access_token};
        my $datas = {
            updated => time(),
            token => $token,
            md5_secret => $md5_secret
        };
        $self->{cache_connect}->write(data => $datas);
    }

    return $token;
}

sub clean_token {
    my ($self, %options) = @_;

    my $datas = { updated => time() };
    $self->{cache_connect}->write(data => $datas);
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    my $token = $self->get_token();
    my ($content) = $self->{http}->request(
        url_path => '/api' . $options{endpoint},
        get_param => $options{get_param},
        header => ['Authorization: Bearer ' . $token],
        unknown_status => '',
        warning_status => '',
        critical_status => ''	
    );

    # Maybe token is invalid. so we retry
    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->clean_token();
        $token = $self->get_token();
        $content = $self->{http}->request(
            url_path => '/api' . $options{endpoint},
            get_param => $options{get_param},
            header => ['Authorization: Bearer ' . $token],
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );
    }

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->allow_nonref(1)->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub get_clusters {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache}->read(statefile => 'thales_mistral_clusters_' . md5_hex($self->get_connection_info() . '_' . $self->{api_username}));
    my $updated = $self->{cache}->get(name => 'updated');
    my $clusters = $self->{cache}->get(name => 'clusters');
    if ($has_cache_file == 0 || !defined($updated) || ((time() - $updated) > (($self->{option_results}->{reload_cache_time} * 60)))) {
        my $cache = { updated => time() };
        my $result = $self->request_api(
            endpoint => '/clusters'
        );
        $clusters = $result;

        $cache->{clusters} = $clusters;
        $self->{cache}->write(data => $cache);
    }

    return $clusters;
}

sub get_gateway_inventory {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache}->read(statefile => 'thales_mistral_inventory_' . md5_hex($self->get_connection_info() . '_' . $self->{api_username}));
    my $updated = $self->{cache}->get(name => 'updated');
    my $inventory = $self->{cache}->get(name => 'gwInventory');
    if ($has_cache_file == 0 || !defined($updated) || ((time() - $updated) > (($self->{option_results}->{reload_cache_time} * 60)))) {
        my $cache = { updated => time() };
        my $result = $self->request_api(
            endpoint => '/ssIpsecGwHws',
            get_param => ['projection=gatewayHwData']
        );
        $inventory = $result->{content};

        $result = $self->request_api(endpoint => '/ssIpsecGwHws/status');
        for (my $i = 0; $i < scalar(@$inventory); $i++) {
            if (defined($result->{ $inventory->[$i]->{serialNumber} })) {
                $inventory->[$i]->{status} = $result->{ $inventory->[$i]->{serialNumber} };
            }
        }

        $result = $self->request_api(
            endpoint => '/certificateGws',
            get_param => ['projection=withGatewayHw']
        );
        for (my $i = 0; $i < scalar(@$inventory); $i++) {
            $inventory->[$i]->{certificates} = [];
            foreach my $cert (@{$result->{content}}) {
                if ($inventory->[$i]->{serialNumber} eq $cert->{ssIpsecGwHw}->{serialNumber}) {
                    push @{$inventory->[$i]->{certificates}}, $cert;
                    last;
                }
            }
        }

        $cache->{gwInventory} = $inventory;
        $self->{cache}->write(data => $cache);
    }

    return $inventory;
}

1;

__END__

=head1 NAME

Mistral vs9 API

=head1 REST API OPTIONS

Mistral vs9 API

=over 8

=item B<--hostname>

Set MMC hostname.

=item B<--port>

Port used (default: 5572)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--api-username>

API username.

=item B<--api-password>

API password.

=item B<--timeout>

Set timeout in seconds (default: 30).

=back

=head1 DESCRIPTION

B<custom>.

=cut
