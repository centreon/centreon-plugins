#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package apps::proxmox::ve::restapi::custom::api;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
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
        $options{options}->add_options(arguments =>  {
            'hostname:s'          => { name => 'hostname' },
            'port:s'              => { name => 'port'},
            'proto:s'             => { name => 'proto' },
            'api-username:s'      => { name => 'api_username' },
            'api-password:s'      => { name => 'api_password' },
            'realm:s'             => { name => 'realm' },
            'timeout:s'           => { name => 'timeout' },
            'reload-cache-time:s' => { name => 'reload_cache_time', default => 7200 }
        });
    }
    
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{cache} = centreon::plugins::statefile->new(%options);

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
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 8006;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{realm} = (defined($self->{option_results}->{realm})) ? $self->{option_results}->{realm} : 'pam';

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

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub get_port {
    my ($self, %options) = @_;

    return $self->{option_results}->{port};
}

sub get_hostnames {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
    $self->{option_results}->{unknown_status} = '%{http_code} < 200 or %{http_code} >= 300';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/x-www-form-urlencoded');
    if (defined($self->{ticket})) {
        $self->{http}->add_header(key => 'Cookie', value => 'PVEAuthCookie=' . $self->{ticket});
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_ticket {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'proxmox_ve_api_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{option_results}->{api_username}));
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $ticket = $options{statefile}->get(name => 'ticket');
    
    if ($has_cache_file == 0 || !defined($ticket) || (($expires_on - time()) < 10)) {
        my $post_data = 'username=' . $self->{api_username} .
            '&password=' . $self->{api_password} .
            '&realm=' . $self->{realm};
        
        $self->settings();

        my $content = $self->{http}->request(
            method => 'POST', query_form_post => $post_data,
            url_path => '/api2/json/access/ticket'
        );

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->output_add(long_msg => $content, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
            $self->{output}->option_exit();
        }
        if (!defined($decoded->{data}->{ticket})) {
            $self->{output}->output_add(long_msg => $content, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Error retrieving ticket");
            $self->{output}->option_exit();
        }

        $ticket = $decoded->{data}->{ticket};
        my $datas = { last_timestamp => time(), ticket => $ticket, expires_on => time() + 7200 };
        $options{statefile}->write(data => $datas);
    }

    return $ticket;
}

sub request_api {
    my ($self, %options) = @_;

    if (!defined($self->{ticket})) {
        $self->{ticket} = $self->get_ticket(statefile => $self->{cache});
    }

    $self->settings();

    my $content = $self->{http}->request(%options);

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }
    if (!defined($decoded->{data})) {
        $self->{output}->add_option_msg(short_msg => "Error while retrieving data (add --debug option for detailed message)");
        $self->{output}->option_exit();
    }

    return $decoded->{data};
}

sub get_version {
    my ($self, %options) = @_;
    
    my $content = $self->request_api(method => 'GET', url_path =>'/api2/json/version');
    return $content->{version};
}

sub internal_api_list_vms {
    my ($self, %options) = @_;
    
    my $vm = $self->request_api(method => 'GET', url_path =>'/api2/json/cluster/resources?type=vm');
    return $vm;
}

sub api_list_vms {
  my ($self, %options) = @_;

    my $vms = {};
    my $list_vms = $self->internal_api_list_vms();
    foreach my $vm (@{$list_vms}) {
        my ($type, $vmid) = split(/\//,$vm->{id});
        $vms->{$vm->{id}} = {
            State => $vm->{status},
            Type => $type,
            Vmid => $vmid,
            Node => $vm->{node},
            Name => $vm->{name},
        };
    }

    return $vms;
}

sub internal_api_list_nodes {
    my ($self, %options) = @_;
    
    my $nodes = $self->request_api(method => 'GET', url_path =>'/api2/json/cluster/resources?type=node');
    return $nodes;
}

sub api_list_nodes {
    my ($self, %options) = @_;

    my $nodes = {};
    my $list_nodes = $self->internal_api_list_nodes();
    foreach my $node (@{$list_nodes}) {
        $nodes->{$node->{id}} = {
            State => $node->{status},
            Name => $node->{node},
        };
    }

    return $nodes;
}

sub internal_api_list_storages {
    my ($self, %options) = @_;
    
    my $storage = $self->request_api(method => 'GET', url_path =>'/api2/json/cluster/resources?type=storage');
    return $storage;
}

sub api_list_storages {
    my ($self, %options) = @_;

    my $storages = {};
    my $list_storages = $self->internal_api_list_storages();
    foreach my $storage (@{$list_storages}) {
        $storages->{$storage->{id}} = {
            State => $storage->{status},
            Node => $storage->{node},
            Name => $storage->{storage},
        };
    }

    return $storages;
}

sub cache_vms {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'cache_proxmox_vm_'.$self->{hostname} . '_' . $self->{port});
    my $timestamp_cache = $options{statefile}->get(name => 'last_timestamp');
    my $vms = $options{statefile}->get(name => 'vms');
    if ($has_cache_file == 0 || !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($options{reload_cache_time})))) {
        $vms = {};
        my $list_vms = $self->internal_api_list_vms();
        foreach my $vm (@$list_vms) {
            $vms->{$vm->{id}} = {
                State => $vm->{status},
                Node => $vm->{node},
                Name => $vm->{name}
            };
        }
        $options{statefile}->write(data => $vms);
    }

    return $vms;
}

sub cache_nodes {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'cache_proxmox_node_'.$self->{hostname} . '_' . $self->{port});
    my $timestamp_cache = $options{statefile}->get(name => 'last_timestamp');
    my $nodes = $options{statefile}->get(name => 'nodes');
    if ($has_cache_file == 0 || !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($options{reload_cache_time})))) {
        $nodes = {};
        my $list_nodes = $self->internal_api_list_nodes();
        foreach my $node (@{$list_nodes}) {
            $nodes->{$node->{id}} = {
                State => $node->{status},
                Name => $node->{node},
            };
        }
        $options{statefile}->write(data => $nodes);
    }

    return $nodes;
}

sub cache_storages {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'cache_proxmox_storage_'.$self->{hostname} . '_' . $self->{port});
    my $timestamp_cache = $options{statefile}->get(name => 'last_timestamp');
    my $storages = $options{statefile}->get(name => 'storages');
    if ($has_cache_file == 0 || !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($options{reload_cache_time})))) {
        $storages = {};
        my $list_storages = $self->internal_api_list_storages();
        foreach my $storage (@{$list_storages}) {
            $storages->{$storage->{id}} = {
                State => $storage->{status},
                Name => $storage->{storage},
            };
        }
        $options{statefile}->write(data => $storages);
    }

    return $storages;
}

sub internal_api_get_vm_stats {
    my ($self, %options) = @_;
    
    my $vm_stats = $self->request_api(method => 'GET', url_path => '/api2/json/nodes/' . $options{node_id} . '/' . $options{vm_id} . '/status/current');
    return $vm_stats;
}

sub internal_api_get_node_stats {
    my ($self, %options) = @_;

    my (undef, $node) = split(/\//, $options{node_id});

    my $node_stats = $self->request_api(method => 'GET', url_path => '/api2/json/nodes/' . $node . '/status');
    return $node_stats;
}

sub internal_api_get_storage_stats {
    my ($self, %options) = @_;

    my (undef, $node, $storage) = split(/\//, $options{storage_id});

    my $storage_stats = $self->request_api(method => 'GET', url_path => '/api2/json/nodes/' . $node . '/storage/' . $storage . '/status');
    return $storage_stats;
}

sub internal_api_get_vm_node {
    my ($self, %options) = @_;

    my $list_vms = $self->internal_api_list_vms();
    my $node = '';
    foreach my $vm (@{$list_vms}) {
        if ($vm->{id} eq $options{vm_id}) {
            $node = $vm->{node};
            last;
        }
    }
    return $node;
}

sub api_get_vms {
    my ($self, %options) = @_;

    my $content_total = $self->cache_vms(statefile => $options{statefile});

    if (defined($options{vm_id}) && $options{vm_id} ne '') {
        if (defined($content_total->{ $options{vm_id} })) {
            $content_total->{ $options{vm_id} }->{Stats} = $self->internal_api_get_vm_stats(
                node_id => $content_total->{ $options{vm_id} }->{Node},
                vm_id => $options{vm_id}
            );
        }
    } elsif (defined($options{vm_name}) && $options{vm_name} ne '') {
        my $vm_id;
        foreach (keys %$content_total) {
            if ($content_total->{$_}->{Name} eq $options{vm_name}) {
                $vm_id = $_;
                last;
            }
        }
        if (defined($vm_id)) {
            $content_total->{$vm_id}->{Stats} = $self->internal_api_get_vm_stats(node_id => $content_total->{$vm_id}->{Node}, vm_id => $vm_id);
        }
    } else {
        foreach my $vm_id (keys %$content_total) {
            $content_total->{$vm_id}->{Stats} = $self->internal_api_get_vm_stats(node_id => $content_total->{$vm_id}->{Node}, vm_id => $vm_id);
        }
    }

    return $content_total;
}

sub api_get_nodes {
    my ($self, %options) = @_;

    my $content_total = $self->cache_nodes(statefile => $options{statefile});

    if (defined($options{node_id}) && $options{node_id} ne '') {
        if (defined($content_total->{$options{node_id}})) {
            $content_total->{$options{node_id}}->{Stats} = $self->internal_api_get_node_stats(node_id => $options{node_id});
        }
    } elsif (defined($options{node_name}) && $options{node_name} ne '') {
        my $node_id;
        foreach (keys %{$content_total}) {
            if ($content_total->{$_}->{Name} eq $options{node_name}) {
                $node_id = $_;
                last;
            }
        }
        if (defined($node_id)) {
            $content_total->{$node_id}->{Stats} = $self->internal_api_get_node_stats(node_id => $node_id);
        }
    } else {
        foreach my $node_id (keys %{$content_total}) {
            $content_total->{$node_id}->{Stats} = $self->internal_api_get_node_stats(node_id => $node_id);
        }
    }

    return $content_total;
}

sub api_get_storages {
    my ($self, %options) = @_;
    
    my $content_total = $self->cache_storages(statefile => $options{statefile});

    if (defined($options{storage_id}) && $options{storage_id} ne '') {
        if (defined($content_total->{$options{storage_id}})) {
            $content_total->{$options{storage_id}}->{Stats} = $self->internal_api_get_storage_stats(storage_id => $options{storage_id});
        }
    } elsif (defined($options{storage_name}) && $options{storage_name} ne '') {
        my $storage_id;
        foreach (keys %{$content_total}) {
            if ($content_total->{$_}->{Name} eq $options{storage_name}) {
                $storage_id = $_;
                last;
            }
        }
        if (defined($storage_id)) {
            $content_total->{$storage_id}->{Stats} = $self->internal_api_get_storage_stats(storage_id => $storage_id);
        }
    } else {
        foreach my $storage_id (keys %{$content_total}) {
            $content_total->{$storage_id}->{Stats} = $self->internal_api_get_storage_stats(storage_id => $storage_id);
        }
    }

    return $content_total;
}

1;

__END__

=head1 NAME

Proxmox VE Rest API

=head1 REST API OPTIONS

Proxmox Rest API

More Info about Proxmox VE API on https://pve.proxmox.com/wiki/Proxmox_VE_API

=over 8

=item B<--hostname>

Set hostname or IP of Proxmox VE Cluster node

=item B<--port>

Set Proxmox VE Port (Default: '8006')

=item B<--proto>

Specify https if needed (Default: 'https').

=item B<--api-username>

Set Proxmox VE Username
API user need to have this privileges
'VM.Monitor, VM.Audit, Datastore.Audit, Sys.Audit, Sys.Syslog'

=item B<--api-password>

Set Proxmox VE Password

=item B<--realm>

Set Proxmox VE Realm (pam, pve or custom) (Default: 'pam').

=item B<--timeout>

Threshold for HTTP timeout.

=back

=cut
