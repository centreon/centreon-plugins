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

package cloud::docker::restapi::custom::api;

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
            'proto:s'       => { name => 'proto' },
            'credentials'   => { name => 'credentials' },
            'basic'         => { name => 'basic' },
            'username:s'    => { name => 'username' },
            'password:s'    => { name => 'password' },
            'timeout:s'     => { name => 'timeout', default => 10 },
            'cert-file:s'   => { name => 'cert_file' },
            'key-file:s'    => { name => 'key_file' },
            'cacert-file:s' => { name => 'cacert_file' },
            'cert-pwd:s'    => { name => 'cert_pwd' },
            'cert-pkcs12'   => { name => 'cert_pkcs12' },
            'api-display'         => { name => 'api_display' },
            'api-write-file:s'    => { name => 'api_write_file' },
            'api-read-file:s'     => { name => 'api_read_file' },
            'reload-cache-time:s' => { name => 'reload_cache_time', default => 300 }
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

    return 0 if (defined($self->{option_results}->{api_read_file}) && $self->{option_results}->{api_read_file} ne '');

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

sub api_display {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{api_display})) {
        if (!defined($self->{option_results}->{api_write_file}) || $self->{option_results}->{api_write_file} eq '') {
            $self->{output}->output_add(
                severity => 'OK',
                short_msg => $options{content}
            );
            $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
            $self->{output}->exit();
        }
        
        if (!open (FH, '>', $self->{option_results}->{api_write_file})) {
            $self->output_add(
                severity => 'UNKNOWN',
                short_msg => "cannot open file  '" . $self->{option_results}->{api_write_file} . "': $!"
            );
        }

        FH->autoflush(1);
        print FH $options{content};
        close FH;
        $self->output_add(
            severity => 'OK',
            short_msg => "Data written in file '" . $self->{option_results}->{api_write_file} . "': $!"
        );
        $self->{output}->exit();
    }
}

sub api_read_file {
    my ($self, %options) = @_;

    my $file_content = do {
        local $/ = undef;
        if (!open my $fh, "<", $self->{option_results}->{api_read_file}) {
            $self->{output}->add_option_msg(short_msg => "Could not open file $self->{option_results}->{api_read_file} : $!");
            $self->{output}->option_exit();
        }
        <$fh>;
    };

    my $content;
    eval {
        $content = JSON::XS->new->utf8->decode($file_content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }
    
    return $content;
}

sub get_hostnames {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub get_port {
    my ($self, %options) = @_;

    return $self->{option_results}->{port};
}

sub internal_get_by_id{
    my ($self, %options) = @_;

    foreach my $obj (@{$options{list}}) {
        if ($obj->{ID} eq $options{Id}) {
            return $obj;
        }
    }

    return undef;
}

sub cache_containers {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'cache_docker_containers_' . join(':', @{$self->{hostname}}) . '_' . $self->{option_results}->{port});
    my $timestamp_cache = $options{statefile}->get(name => 'last_timestamp');
    my $containers = $options{statefile}->get(name => 'containers');
    if ($has_cache_file == 0 || !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($options{reload_cache_time})))) {
        $containers = {};
        my $datas = { last_timestamp => time(), containers => $containers };

        foreach my $node_name (@{$self->{node_names}}) {
            my $list_containers = $self->internal_api_list_containers(node_name => $node_name);
            foreach my $container (@$list_containers) {
                $containers->{$container->{Id}} = {
                    State => $container->{State},
                    NodeName => $node_name,
                    Name => join(':', @{$container->{Names}}),
                };
            }
        }
        $options{statefile}->write(data => $containers);
    }

    return $containers;
}

sub internal_api_list_nodes {
    my ($self, %options) = @_;
    
    my $response = $self->{http}->request(
        hostname => $options{node_name},
        url_path => '/nodes',
        unknown_status => '',
        critical_status => '',
        warning_status => ''
    );
    my $nodes;
    eval {
        $nodes = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $nodes = [];
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => "Node '$options{node_name}': cannot decode json list nodes response: $@"
        );
    } else {
        $nodes = [] if (ref($nodes) eq 'HASH'); # nodes is not in a swarm
    }
    
    return $nodes;
}

sub internal_api_info {
    my ($self, %options) = @_;
    
    my $response = $self->{http}->request(
        hostname => $options{node_name},
        url_path => '/info',
        unknown_status => '',
        critical_status => '',
        warning_status => ''
    );
    my $nodes;
    eval {
        $nodes = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $nodes = [];
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => "Node '$options{node_name}': cannot decode json info response: $@"
        );
    }

    return $nodes;
}

sub internal_api_list_containers {
    my ($self, %options) = @_;
    
    my $response = $self->{http}->request(
        hostname => $options{node_name},
        url_path => '/containers/json?all=true',
        unknown_status => '',
        critical_status => '',
        warning_status => ''
    );
    my $containers;
    eval {
        $containers = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $containers = [];
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => "Node '$options{node_name}': cannot decode json get containers response: $@"
        );
    }
    
    return $containers;
}

sub internal_api_get_container_stats {
    my ($self, %options) = @_;

    my $response = $self->{http}->request(
        hostname => $options{node_name},
        url_path => '/containers/' . $options{container_id} . '/stats?stream=false',
        unknown_status => '',
        critical_status => '',
        warning_status => ''
    );
    my $container_stats;
    eval {
        $container_stats = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $container_stats = {};
        $self->output_add(
            severity => 'UNKNOWN',
            short_msg => "Node '$options{node_name}': cannot decode json get container stats response: $@"
        );
    }

    return $container_stats;
}

sub internal_api_list_services {
    my ($self, %options) = @_;

    my $response = $self->{http}->request(
        hostname => $options{node_name},
        url_path => '/services',
        unknown_status => '', critical_status => '', warning_status => '');
    my $services;
    eval {
        $services = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $services = [];
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => "Service '$options{node_name}': cannot decode json list services response: $@"
        );
    }

    return $services;
}

sub internal_api_list_tasks {
    my ($self, %options) = @_;

    my $response = $self->{http}->request(
        hostname => $options{node_name},
        url_path => '/tasks',
        unknown_status => '',
        critical_status => '',
        warning_status => ''
    );
    my $tasks;
    eval {
        $tasks = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $tasks = [];
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => "Task '$options{node_name}': cannot decode json list services response: $@"
        );
    }

    return $tasks;
}

sub api_list_services {
    my ($self, %options) = @_;

    my $services = {};
    foreach my $node_name (@{$self->{node_names}}) {
        # 406 or 503 - node is not part of a swarm
        my $list_tasks = $self->internal_api_list_tasks(node_name => $node_name);
        next if ($self->{http}->get_code() == 406 || $self->{http}->get_code() == 503);

        my $list_services = $self->internal_api_list_services(node_name => $node_name);
        foreach my $task (@$list_tasks) {
            $services->{ $task->{ServiceID} } = {} if (!defined($services->{ $task->{ServiceID} }));
            my $service = $self->internal_get_by_id(list => $list_services, Id => $task->{ServiceID});
            $services->{ $task->{ServiceID} }->{ $task->{ID} } = {
                node_id => $task->{NodeID},
                node_name => $node_name,
                service_name => $service->{Spec}->{Name},
                container_id => $task->{Status}->{ContainerStatus}->{ContainerID},
                desired_state => defined($task->{DesiredState}) && $task->{DesiredState} ne '' ? $task->{DesiredState} : '-',
                state => defined($task->{Status}->{State}) && $task->{Status}->{State} ne '' ? $task->{Status}->{State} : '-',
                state_message => defined($task->{Status}->{Message}) && $task->{Status}->{Message} ne '' ? $task->{Status}->{Message} : '-'
            };
        }
    }

    return $services;
}

sub api_list_containers {
    my ($self, %options) = @_;

    my $containers = {};
    foreach my $node_name (@{$self->{node_names}}) {
        my $list_containers = $self->internal_api_list_containers(node_name => $node_name);
        foreach my $container (@$list_containers) {
            $containers->{$container->{Id}} = {
                State => $container->{State},
                NodeName => $node_name,
                Name => join(':', @{$container->{Names}}),
            };
        }
    }

    return $containers;
}

sub api_list_nodes {
    my ($self, %options) = @_;

    my $nodes = {};
    foreach my $node_name (@{$self->{node_names}}) {
        my $info_node = $self->internal_api_info(node_name => $node_name);
        my $list_nodes = $self->internal_api_list_nodes(node_name => $node_name);
        $nodes->{$node_name} = { nodes => [], 
            containers_running => $info_node->{ContainersRunning},
            containers_stopped => $info_node->{ContainersStopped},
            containers_paused => $info_node->{ContainersPaused},
        };
        foreach my $node (@$list_nodes) {
            push @{$nodes->{$node_name}->{nodes}}, { Status => $node->{Status}->{State}, ManagerStatus => $node->{ManagerStatus}->{Reachability}, Addr => $node->{Status}->{Addr} };
        }
    }

    return $nodes;
}

sub api_get_containers {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{api_read_file}) && $self->{option_results}->{api_read_file} ne '') {
        return $self->api_read_file();
    }

    my $content_total = $self->cache_containers(statefile => $options{statefile});
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

    $self->api_display();
    return $content_total;
}

1;

__END__

=head1 NAME

Docker REST API

=head1 SYNOPSIS

Docker Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

IP Addr/FQDN of the docker node (can be multiple).

=item B<--port>

Port used (Default: 8080)

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--credentials>

Specify this option if you access server-status page with authentication

=item B<--username>

Specify username for authentication (Mandatory if --credentials is specified)

=item B<--password>

Specify password for authentication (Mandatory if --credentials is specified)

=item B<--basic>

Specify this option if you access server-status page over basic authentication and don't want a '401 UNAUTHORIZED' error to be logged on your webserver.

Specify this option if you access server-status page over hidden basic authentication or you'll get a '404 NOT FOUND' error.

(Use with --credentials)

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

=item B<--api-display>

Print json api.

=item B<--api-write-display>

Print json api in a file (to be used with --api-display).

=item B<--api-read-file>

Read API from file.

=item B<--reload-cache-time>

Time in seconds before reloading list containers cache (default: 300)

=back

=head1 DESCRIPTION

B<custom>.

=cut
