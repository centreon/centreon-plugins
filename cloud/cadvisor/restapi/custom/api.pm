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

package cloud::cadvisor::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::http;
use JSON::XS;
use FileHandle;

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
            'hostname:s@'   => { name => 'hostname' },
            'port:s'        => { name => 'port', default => 8080 },
            'proto:s'       => { name => 'proto', default => 'http' },
            'path:s'        => { name => 'path', default => '/containers/docker/' },
            'credentials'   => { name => 'credentials' },
            'username:s'    => { name => 'username' },
            'password:s'    => { name => 'password' },
            'timeout:s'     => { name => 'timeout', default => 10 },
            'cert-file:s'   => { name => 'cert_file' },
            'key-file:s'    => { name => 'key_file' },
            'cacert-file:s' => { name => 'cacert_file' },
            'cert-pwd:s'    => { name => 'cert_pwd' },
            'cert-pkcs12'   => { name => 'cert_pkcs12' },
            'api-version:s' => { name => 'api_version', default => 'v1.3' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{http} = centreon::plugins::http->new(%options);
    $self->{output} = $options{output};

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

    if (!defined($self->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
        $self->{output}->option_exit();
    }
    
    $self->{node_names} = [];
    foreach my $node_name (@{$self->{hostname}}) {
        if ($node_name ne '') {
            push @{$self->{node_names}}, $node_name;
        }
    }
    
    $self->{http}->set_options(%{$self->{option_results}});

    return 0;
}

sub get_hostnames {
    my ($self, %options) = @_;
    
    return $self->{hostname};
}

sub get_port {
    my ($self, %options) = @_;
    
    return $self->{option_results}->{port};
}

sub internal_api_list_nodes {
    my ($self, %options) = @_;
    
    my $response = $self->{http}->request(
        hostname => $options{node_name},
        url_path => '/api/' . $self->{option_results}->{api_version} . $self->{option_results}->{path},
        unknown_status => '', critical_status => '', warning_status => '');
    my $nodes;
    eval {
        $nodes = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $nodes = {};
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => "Node '$options{node_name}': cannot decode json list nodes response: $@");
    } else {
        $nodes = {} if (ref($nodes) eq 'ARRAY'); # nodes is not in a swarm
    }
    
    return $nodes;
}

sub internal_api_info {
    my ($self, %options) = @_;
    
    my $response = $self->{http}->request(
        hostname => $options{node_name},
        url_path => '/api/' . $self->{option_results}->{api_version} . '/machine/',
        unknown_status => '', critical_status => '', warning_status => '');
    my $nodes;
    eval {
        $nodes = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $nodes = [];
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => "Node '$options{node_name}': cannot decode json info response: $@");
    }
    
    return $nodes;
}

sub internal_api_list_containers {
    my ($self, %options) = @_;
    
    my $response = $self->{http}->request(
        hostname => $options{node_name},
        url_path => '/api/' . $self->{option_results}->{api_version} . $self->{option_results}->{path},
        unknown_status => '', critical_status => '', warning_status => '');
    my $containers = [];
    my $containers_ids;
    eval {
        $containers_ids = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $containers = [];
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => "Node '$options{node_name}': cannot decode json get containers response: $@");
    }
    foreach my $container (@{$containers_ids->{subcontainers}}) {
        my $json_response = JSON::XS->new->utf8->decode(
            $self->{http}->request(
                hostname => $options{node_name},
                url_path => '/api/' . $self->{option_results}->{api_version} . '/containers/' . $container->{name}
            )
        );
        
        push @$containers, {
            id => defined($json_response->{id}) ? $json_response->{id} : $json_response->{name}, 
            names => defined($json_response->{aliases}) ? $json_response->{aliases} : [$json_response->{name}],
            node => $options{node_name} 
        };
    }
    
    return $containers;
}

sub internal_api_get_machine_stats {
    my ($self, %options) = @_;
    my $response = $self->{http}->request(
        hostname => $options{node_name},
        url_path => '/api/' . $self->{option_results}->{api_version} . '/machine',
        unknown_status => '', critical_status => '', warning_status => '');
    my $machine_stats;
    my $full_machine_stats;
    eval {
        $full_machine_stats = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $machine_stats = {};
        $self->output_add(severity => 'UNKNOWN',
                          short_msg => "Node '$options{node_name}': cannot decode json get container stats response: $@");
    } else {
        $machine_stats->{num_cores} = $full_machine_stats->{num_cores};
        $machine_stats->{memory_capacity} = $full_machine_stats->{memory_capacity};
    }
    return $machine_stats;
}

sub internal_api_get_container_stats {
    my ($self, %options) = @_;
    my $response = $self->{http}->request(
        hostname => $options{node_name},
        url_path => '/api/' . $self->{option_results}->{api_version} . $self->{option_results}->{path} . '/' . $options{container_id},
        unknown_status => '', critical_status => '', warning_status => '');
    my $container_stats;
    my $full_container_stats;
    eval {
        $full_container_stats = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $container_stats = [];
        $self->output_add(severity => 'UNKNOWN',
                          short_msg => "Node '$options{node_name}': cannot decode json get container stats response: $@");
    } else {
        $container_stats->[0] = $full_container_stats->{stats}[0];
        $container_stats->[1] = $full_container_stats->{stats}[scalar(@{$full_container_stats->{stats}}) - 1];
    }
    return $container_stats;
}

sub api_list_containers {
    my ($self, %options) = @_;
    
    my $containers = {};
    foreach my $node_name (@{$self->{node_names}}) {
        my $list_containers = $self->internal_api_list_containers(node_name => $node_name);
        foreach my $container (@$list_containers) {
            $containers->{$container->{id}} = {
                NodeName => $node_name,
                Name => $container->{names}->[0],
            };
        }
    }
    
    return $containers;
}

sub api_get_machine_stats {
    my ($self, %options) = @_;
    
    my $machine_stats = {};
    foreach my $node_name (@{$self->{node_names}}) {
        $machine_stats->{$node_name} = $self->internal_api_get_machine_stats(node_name => $node_name);
    }
    return $machine_stats;
}

sub api_list_nodes {
    my ($self, %options) = @_;
    
    my $nodes = {};
    foreach my $node_name (@{$self->{node_names}}) {
        my $info_node = $self->internal_api_info(node_name => $node_name);
        my $list_nodes = $self->internal_api_list_nodes(node_name => $node_name);
        $nodes->{$node_name} = { nodes => [], 
            num_cores => $info_node->{num_cores},
            cpu_frequency_khz => $info_node->{cpu_frequency_khz},
            memory_capacity => $info_node->{memory_capacity},
        };
        foreach my $node (@{$list_nodes->{subcontainers}}) {
            push @{$nodes->{$node_name}->{nodes}}, { 
                name => $node->{name}
            }
        }
    }
    
    return $nodes;
}

sub api_get_containers {
    my ($self, %options) = @_;

    my $content_total = $self->api_list_containers();
    if (defined($options{container_id}) && $options{container_id} ne '') {
        if (defined($content_total->{$options{container_id}})) {
            $content_total->{$options{container_id}}->{Stats} = $self->internal_api_get_container_stats(node_name => $content_total->{$options{container_id}}->{NodeName}, container_id => $options{container_id});
        }
    } elsif (defined($options{container_name}) && $options{container_name} ne '') {
        my $container_id;
        
        foreach (keys %$content_total) {
            if ($content_total->{$_}->{Name} eq $options{container_name}) {
                $container_id = $_;
                last;
            }
        }
        
        if (defined($container_id)) {
            $content_total->{$container_id}->{Stats} = $self->internal_api_get_container_stats(node_name => $content_total->{$container_id}->{NodeName}, container_id => $container_id);
        }
    } else {
        foreach my $container_id (keys %{$content_total}) {
            $content_total->{$container_id}->{Stats} = $self->internal_api_get_container_stats(node_name => $content_total->{$container_id}->{NodeName}, container_id => $container_id);
        }
    }
    
    return $content_total;
}

1;

__END__

=head1 NAME

cadvisor REST API

=head1 SYNOPSIS

CAdvisor Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

IP Addr/FQDN of the cadvisor node (can be multiple).

=item B<--port>

Port used (Default: 8080)

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--path>

Path used (Default: '/containers/docker')

=item B<--credentials>

Specify this option if you access webpage over basic authentification

=item B<--username>

Specify username for basic authentification (Mandatory if --credentials is specidied)

=item B<--password>

Specify password for basic authentification (Mandatory if --credentials is specidied)

=item B<--timeout>

Threshold for HTTP timeout (Default: 10)

=item B<--cert-file>

Specify certificate to send to the webserver

=item B<--key-file>

Specify key to send to the webserver

=item B<--cacert-file>

Specify root certificate to send to the webserver

=item B<--cert-pwd>

Specify certificate's password

=item B<--cert-pkcs12>

Specify type of certificate (PKCS12)

=back

=head1 DESCRIPTION

B<custom>.

=cut
