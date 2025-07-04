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

package apps::podman::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::misc;
use JSON::XS;

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
            'hostname:s' => { name => 'hostname' },
            'port:s'     => { name => 'port' },
            'proto:s'    => { name => 'proto' },
            'url-path:s' => { name => 'url_path' },
            'timeout:s'  => { name => 'timeout' }
        });
        # curl --cacert /path/to/ca.crt --cert /path/to/podman.crt --key /path/to/podman.key https://localhost:8080/v5.0.0/libpod/info
        # curl --unix-socket $XDG_RUNTIME_DIR/podman/podman.sock 'http://d/v5.0.0/libpod/pods/stats?namesOrIDs=blog' | jq
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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{url_path} = (defined($self->{option_results}->{url_path})) ? $self->{option_results}->{url_path} : '/v5.0.0/libpod/';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify hostname option.');
        $self->{output}->option_exit();
    }

    $self->{http}->set_options(%{$self->{option_results}});

    return 0;
}

sub json_decode {
    my ($self, %options) = @_;

    $options{content} =~ s/\r//mg;
    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($options{content});
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{timeout} = $self->{timeout};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
}

sub request {
    my ($self, %options) = @_;

    my $endpoint = $options{full_endpoint};
    if (!defined($endpoint)) {
        $endpoint = $self->{url_path} . $options{endpoint};
    }

    $self->settings();

    my $content = $self->{http}->request(
        method          => $options{method},
        url_path        => $endpoint,
        get_param       => $options{get_param},
        header          => [
            'Accept: application/json'
        ],
        warning_status  => '',
        unknown_status  => '',
        critical_status => ''
    );

    my $decoded = $self->json_decode(content => $content);
    if (!defined($decoded)) {
        $self->{output}->add_option_msg(short_msg => 'Error while retrieving data (add --debug option for detailed message)');
        $self->{output}->option_exit();
    }
    return $decoded;
}

sub system_info {
    my ($self, %options) = @_;

    my $results = $self->request(
        endpoint => 'info',
        method   => 'GET'
    );

    return $results;
}

sub list_containers {
    my ($self, %options) = @_;

    my $results = $self->request(
        endpoint => 'containers/json',
        method   => 'GET'
    );

    my $containers = {};
    foreach my $container (@{$results}) {
        $containers->{$container->{Id}} = {
            Name    => $container->{Names}->[0],
            PodName => $container->{PodName},
            State   => $container->{State}
        };
    }

    return $containers;
}

sub list_pods {
    my ($self, %options) = @_;

    my $results = $self->request(
        endpoint => 'pods/json',
        method   => 'GET'
    );

    my $pods = {};
    foreach my $pod (@{$results}) {
        $pods->{$pod->{Id}} = {
            Name   => $pod->{Name},
            Status => $pod->{Status}
        };
    }

    return $pods;
}

sub get_pod_infos {
    my ($self, %options) = @_;

    my $inspect = $self->request(
        endpoint => 'pods/' . $options{pod_name} . '/json',
        method   => 'GET'
    );

    my $stats = $self->request(
        endpoint => 'pods/stats?namesOrIDs=' . $options{pod_name},
        method   => 'GET'
    );

    my $pod = {
        cpu                => 0,
        memory             => 0,
        running_containers => 0,
        stopped_containers => 0,
        paused_containers  => 0,
        state              => $inspect->{State}
    };

    foreach my $container (@{$inspect->{Containers}}) {
        $pod->{running_containers}++ if ($container->{State} eq 'running');
        $pod->{stopped_containers}++ if ($container->{State} eq 'exited');
        $pod->{paused_containers}++ if ($container->{State} eq 'paused');
    }

    foreach my $container (@{$stats}) {
        my $cpu = $container->{CPU};
        if ($cpu =~ /^(\d+\.\d+)%/) {
            $pod->{cpu} += $1;
        }
        my $memory = $container->{MemUsage};
        if ($memory =~ /^(\d+\.?\d*)([a-zA-Z]+)/) {
            $memory = centreon::plugins::misc::convert_bytes(value => $1, unit => $2);
        }
        $pod->{memory} += $memory;
    }

    return $pod;
}

sub get_container_infos {
    my ($self, %options) = @_;

    my $stats = $self->request(
        endpoint => 'containers/stats',
        get_param => [
            'stream=false',
            'containers=' . $options{container_name}
        ],
        method   => 'GET'
    );

    my $container_info;
    my $state = 'unknown';
    foreach my $stat (@{$stats->{Stats}}) {
        next if ($stat->{Name} ne $options{container_name});
        $container_info = {
            cpu_usage    => $stat->{CPU},
            memory_usage => $stat->{MemUsage},
            io_read      => $stat->{BlockInput},
            io_write     => $stat->{BlockOutput},
            network_in   => $stat->{NetInput},
            network_out  => $stat->{NetOutput}
        };
    }
    my $containers = $self->list_containers();
    foreach my $container_id (sort keys %{$containers}) {
        next if ($containers->{$container_id}->{Name} ne $options{container_name});
        $container_info->{state} = $containers->{$container_id}->{State};
    }
    return $container_info;
}

1;

__END__

=head1 NAME

Podman REST API.

=head1 SYNOPSIS

Podman Rest API custom mode.
To connect to the API with a socket, you must add the following command:
C<--curl-opt="CURLOPT_UNIX_SOCKET_PATH => 'PATH_TO_THE_SOCKET'">
If you use a certificate, you must add the following commands:
C<--curl-opt="CURLOPT_CAINFO = 'PATH_TO_THE_CA_CERTIFICATE'">
C<--curl-opt="CURLOPT_SSLCERT => 'PATH_TO_THE_CERTIFICATE'">
C<--curl-opt="CURLOPT_SSLKEY => 'PATH_TO_THE_KEY'">

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Podman Rest API hostname.

=item B<--port>

Port used (Default: 443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--url-path>

Set path to get Podman Rest API information (Default: '/v5.0.0/libpod/')

=item B<--timeout>

Set timeout in seconds (Default: 30)

=back

=head1 DESCRIPTION

B<custom>.

=cut
