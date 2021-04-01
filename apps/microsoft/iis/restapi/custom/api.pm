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

package apps::microsoft::iis::restapi::custom::api;

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
            'api-username:s'    => { name => 'api_username' },
            'api-password:s'    => { name => 'api_password' },
            'api-token:s'       => { name => 'api_token' },
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
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 55539;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{api_token} = (defined($self->{option_results}->{api_token})) ? $self->{option_results}->{api_token} : '';
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }
    if ($self->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-username option.");
        $self->{output}->option_exit();
    }
    if ($self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-password option.");
        $self->{output}->option_exit();
    }
    if ($self->{api_token} eq '') {
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
    $self->{option_results}->{timeout} = $self->{timeout};
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->add_header(key => 'Access-Token', value => 'Bearer ' . $self->{api_token});
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    my $login = {};
    if (!defined($self->{login_done})) {
        $login = { credentials => 1, ntlmv2 => 1, username => $self->{api_username}, password => $self->{api_password} };
        $self->{login_done} = 1;
    }
    my $content = $self->{http}->request(
        url_path => $options{endpoint},
        unknown_status => $self->{unknown_http_status},
        warning_status => $self->{warning_http_status},
        critical_status => $self->{critical_http_status},
        %$login
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

sub get_application_pools {
    my ($self, %options) = @_;

    my $results = {};
    my $pools = $self->request_api(endpoint => '/api/webserver/application-pools');
    foreach (@{$pools->{app_pools}}) {
        if (defined($options{filter_name}) && $options{filter_name} ne '' &&
            $_->{name} !~ /$options{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping pool '" . $_->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $results->{ $_->{name} } = $_;
        my $detail = $self->request_api(endpoint => '/api/webserver/application-pools/' . $_->{id});
        $results->{ $_->{name} }->{auto_start} = $detail->{auto_start};

        next if (defined($options{no_monitoring}));

        my $monitor = $self->request_api(endpoint => '/api/webserver/application-pools/monitoring/' . $_->{id});
        $results->{ $_->{name} }->{requests} = $monitor->{requests};
    }

    return $results;
}

sub get_websites {
    my ($self, %options) = @_;

    my $results = {};
    my $websites = $self->request_api(endpoint => '/api/webserver/websites');
    foreach (@{$websites->{websites}}) {
        if (defined($options{filter_name}) && $options{filter_name} ne '' &&
            $_->{name} !~ /$options{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping website '" . $_->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $results->{ $_->{name} } = $_;

        next if (defined($options{no_monitoring}));

        my $monitor = $self->request_api(endpoint => '/api/webserver/websites/monitoring/' . $_->{id});
        $results->{ $_->{name} }->{network} = $monitor->{network};
    }

    return $results;
}

1;

__END__

=head1 NAME

IIS Rest API

=head1 REST API OPTIONS

IIS Rest API

=over 8

=item B<--hostname>

IIS hostname.

=item B<--port>

Port used (Default: 55539)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--api-username>

IIS API username.

=item B<--api-password>

IIS API password.

=item B<--api-token>

IIS API token.

=item B<--timeout>

Set timeout in seconds (Default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
