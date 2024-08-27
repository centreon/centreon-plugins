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

package cloud::kubernetes::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

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

    if ($self->{option_results}->{resource_type} !~ /^node|namespace$/) {
        $self->{output}->add_option_msg(short_msg => 'unknown resource type');
        $self->{output}->option_exit();
    }
}

sub discovery_node {
    my ($self, %options) = @_;

    my $nodes = $options{custom}->kubernetes_list_nodes();

    my $disco_data = [];
    foreach my $node (@$nodes) {
        my %entry;
        $entry{name} = $node->{metadata}->{name};
        $entry{uid} = $node->{metadata}->{uid};
        $entry{os_image} = $node->{status}->{nodeInfo}->{osImage};
        $entry{kubelet_version} = $node->{status}->{nodeInfo}->{kubeletVersion};
        if (defined($node->{metadata}->{labels}->{'node-role.kubernetes.io/control-plane'})) {
            $entry{node_role} = "control-plane";
        } elsif (defined($node->{metadata}->{labels}->{'node-role.kubernetes.io/master'})) {
            $entry{node_role} = "master";
        } else {
            $entry{node_role} = "worker";
        }

        foreach my $address (@{$node->{status}->{addresses}}) {
            $entry{internal_ip} = $address->{address} if ($address->{type} eq "InternalIP");
            $entry{external_ip} = $address->{address} if ($address->{type} eq "ExternalIP");
            $entry{hostname} = $address->{address} if ($address->{type} eq "Hostname");
        }
                
        push @$disco_data, \%entry;    
    }

    return $disco_data;
}

sub discovery_namespace {
    my ($self, %options) = @_;

    my $namespaces = $options{custom}->kubernetes_list_namespaces();

    my $disco_data = [];
    foreach my $namespace (@$namespaces) {
        my %entry;
        $entry{name} = $namespace->{metadata}->{name};
        $entry{uid} = $namespace->{metadata}->{uid};
                
        push @$disco_data, \%entry;    
    }

    return $disco_data;
}

sub run {
    my ($self, %options) = @_;

    my @disco_data;
    my $disco_stats;

    $disco_stats->{start_time} = time();

    my $results = [];
    if ($self->{option_results}->{resource_type} eq 'node') {
        $results = $self->discovery_node(
            custom => $options{custom}
        );
    } elsif ($self->{option_results}->{resource_type} eq 'namespace') {
        $results = $self->discovery_namespace(
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

Nodes discovery.

=over 8

=item B<--resource-type>

Choose the type of resources to discover (can be: 'node', 'namespace').

=item B<--prettify>

Prettify JSON output.

=back

=cut
