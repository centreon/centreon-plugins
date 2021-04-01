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

package apps::oracle::ovm::api::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'resource-type:s' => { name => 'resource_type' },
        'prettify'        => { name => 'prettify' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{resource_type}) || $self->{option_results}->{resource_type} eq '') {
        $self->{option_results}->{resource_type} = 'server';
    }
    if ($self->{option_results}->{resource_type} !~ /^server|vm$/) {
        $self->{output}->add_option_msg(short_msg => 'unknown resource type');
        $self->{output}->option_exit();
    }
}

sub discovery_vm {
    my ($self, %options) = @_;

    my $vms = $options{custom}->request_api(endpoint => '/Vm');

    my $disco_data = [];
    foreach my $vm (@$vms) {
        my $node = {};
        $node->{uuid} = $vm->{id}->{value};
        $node->{name} = $vm->{name};
        $node->{description} = $vm->{description};
        $node->{running_state} = lc($vm->{vmRunState});
        $node->{os_type} = $vm->{osType};
        $node->{server_pool_uuid} = $vm->{serverPoolId}->{value};
        $node->{server_pool_name} = $vm->{serverPoolId}->{name};
        $node->{server_uuid} = $vm->{serverId}->{value};
        $node->{server_name} = $vm->{serverId}->{name};

        push @$disco_data, $node;
    }

    return $disco_data;
}

sub discovery_server {
    my ($self, %options) = @_;

    my $servers = $options{custom}->request_api(endpoint => '/Server');

    my $disco_data = [];
    foreach my $server (@$servers) {
        my $node = {};
        $node->{uuid} = $server->{id}->{value};
        $node->{name} = $server->{name};
        $node->{description} = $server->{description};
        $node->{running_state} = lc($server->{serverRunState});
        $node->{ip_address} = $server->{ipAddress};
        $node->{hostname} = $server->{hostname};
        $node->{serial_number} = $server->{serialNumber};
        $node->{server_pool_uuid} = $server->{serverPoolId}->{value};
        $node->{server_pool_name} = $server->{serverPoolId}->{name};

        push @$disco_data, $node;
    }

    return $disco_data;
}

sub run {
    my ($self, %options) = @_;

    my $disco_stats;
    $disco_stats->{start_time} = time();

    my $results = [];
    if ($self->{option_results}->{resource_type} eq 'vm') {
        $results = $self->discovery_vm(
            custom => $options{custom}
        );
    } else {
        $results = $self->discovery_server(
            custom => $options{custom}
        );
    }

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = scalar(@$results);
    $disco_stats->{results} = $results;

    my $encoded_data;
    eval {
        if (defined($self->{option_results}->{prettify})) {
            $encoded_data = JSON::XS->new->utf8->pretty->encode($disco_stats);
        } else {
            $encoded_data = JSON::XS->new->utf8->encode($disco_stats);
        }
    };
    if ($@) {
        $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}';
    }
    
    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Resources discovery.

=over 8

=item B<--resource-type>

Choose the type of resources to discover (Can be: 'vm', 'server').

=back

=cut
