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

package storage::netapp::ontap::oncommandapi::mode::listaggregates;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'filter-node:s'     => { name => 'filter_node' },
        'filter-cluster:s'  => { name => 'filter_cluster' }
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{clusters} = $options{custom}->get_objects(path => '/clusters', key => 'key', name => 'name');
    
    $self->{nodes} = $options{custom}->get_objects(path => '/nodes', key => 'key', name => 'name');

    my $result = $options{custom}->get(path => '/aggregates');

    foreach my $aggregate (@{$result}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $aggregate->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $aggregate->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_node}) && $self->{option_results}->{filter_node} ne '' &&
            defined($self->{nodes}->{$aggregate->{node_key}}) && $self->{nodes}->{$aggregate->{node_key}} !~ /$self->{option_results}->{filter_node}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $aggregate->{name} . "': no matching filter node '" . $self->{nodes}->{$aggregate->{node_key}} . "'", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_cluster}) && $self->{option_results}->{filter_cluster} ne '' &&
            defined($self->{clusters}->{$aggregate->{cluster_key}}) && $self->{clusters}->{$aggregate->{cluster_key}} !~ /$self->{option_results}->{filter_cluster}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $aggregate->{name} . "': no matching filter cluster '" . $self->{clusters}->{$aggregate->{cluster_key}} . "'", debug => 1);
            next;
        }

        $self->{aggregates}->{$aggregate->{key}} = {
            name => $aggregate->{name},
            state => $aggregate->{state},
            mirror_status => $aggregate->{mirror_status},
            raid_type => $aggregate->{raid_type},
            aggregate_type => $aggregate->{aggregate_type},
            snaplock_type => $aggregate->{snaplock_type},
            cluster => $self->{clusters}->{$aggregate->{cluster_key}},
            node => $self->{nodes}->{$aggregate->{node_key}},
        }
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $aggregate (sort keys %{$self->{aggregates}}) { 
        $self->{output}->output_add(long_msg => sprintf("[name = %s] [state = %s] [mirror_status = %s] [raid_type = %s] [aggregate_type = %s] [snaplock_type = %s] [cluster = %s] [node = %s]",
                                                         $self->{aggregates}->{$aggregate}->{name},
                                                         $self->{aggregates}->{$aggregate}->{state},
                                                         $self->{aggregates}->{$aggregate}->{mirror_status},
                                                         $self->{aggregates}->{$aggregate}->{raid_type},
                                                         $self->{aggregates}->{$aggregate}->{aggregate_type},
                                                         $self->{aggregates}->{$aggregate}->{snaplock_type},
                                                         $self->{aggregates}->{$aggregate}->{cluster},
                                                         $self->{aggregates}->{$aggregate}->{node}));
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List aggregates:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'state', 'mirror_status',
                                                   'raid_type', 'aggregate_type', 'snaplock_type']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $aggregate (sort keys %{$self->{aggregates}}) {             
        $self->{output}->add_disco_entry(
            name => $self->{aggregates}->{$aggregate}->{name},
            state => $self->{aggregates}->{$aggregate}->{state},
            mirror_status => $self->{aggregates}->{$aggregate}->{mirror_status},
            raid_type => $self->{aggregates}->{$aggregate}->{raid_type},
            aggregate_type => $self->{aggregates}->{$aggregate}->{aggregate_type},
            snaplock_type => $self->{aggregates}->{$aggregate}->{snaplock_type},
            cluster => $self->{aggregates}->{$aggregate}->{cluster},
            node => $self->{aggregates}->{$aggregate}->{node},
        );
    }
}

1;

__END__

=head1 MODE

List aggregates.

=over 8

=item B<--filter-*>

Filter aggregates.
Can be: 'name', 'node', 'cluster' (can be a regexp).

=back

=cut
