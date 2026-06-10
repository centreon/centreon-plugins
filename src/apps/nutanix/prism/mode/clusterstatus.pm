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

package apps::nutanix::prism::mode::clusterstatus;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;
    return sprintf(
        "cluster '%s' state is '%s' [version: %s]",
        $self->{result_values}->{name},
        $self->{result_values}->{state},
        $self->{result_values}->{version}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'clusters',
            type             => 1,
            cb_prefix_output => 'prefix_cluster_output',
            message_multiple => 'All clusters are OK',
            skipped_code     => { -10 => 1 },
        }
    ];

    $self->{maps_counters}->{clusters} = [
        # Compteur de type "status" (type => 2) : vérifie un état via une expression
        {
            label => 'status',
            type  => 2,
            # Seuil warning par défaut : état différent de "COMPLETE"
            warning_default => '%{state} ne "COMPLETE"',
            set   => {
                key_values => [
                    { name => 'name' },
                    { name => 'state' },
                    { name => 'version' },
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        },
        # Compteur numérique : nombre de nœuds
        {
            label  => 'nodes-count',
            nlabel => 'cluster.nodes.count',
            set    => {
                key_values      => [ { name => 'num_nodes' }, { name => 'name' } ],
                output_template => 'nodes: %d',
                perfdatas       => [
                    {
                        template      => '%d',
                        label_extra_instance => 1,
                        instance_use  => 'name',
                        min           => 0,
                    }
                ]
            }
        },
    ];
}

sub prefix_cluster_output {
    my ($self, %options) = @_;
    return "Cluster '" . $options{instance_value}->{name} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'filter-name:s' => { name => 'filter_name' },
        }
    );

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # Appel au module custom (api.pm) via $options{custom}
    my $result = $options{custom}->get_clusters();

    # L'API v2.0 retourne { entities => [...], metadata => {...} }
    my $entities = $result->{entities} // [];

    $self->{clusters} = {};
    for my $cluster (@{$entities}) {
        my $name = $cluster->{name} // 'unknown';

        # Filtrage optionnel par nom (regex)
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '') {
            next if $name !~ /$self->{option_results}->{filter_name}/;
        }

        # On stocke les données dans le hash $self->{clusters}
        # La clé est unique par instance (ici le nom du cluster)
        $self->{clusters}->{$name} = {
            name      => $name,
            # cluster_state est dans les stats internes de Prism v2
            state     => $cluster->{cluster_state} // 'UNKNOWN',
            version   => $cluster->{version} // 'N/A',
            num_nodes => $cluster->{num_nodes} // 0,
        };
    }

    if (scalar(keys %{$self->{clusters}}) == 0) {
        $self->{output}->add_option_msg(short_msg => 'No cluster found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Monitor Nutanix cluster status through Prism REST API.

=over 8

=item B<--filter-name>

Filter clusters by name (regexp). Example: C<--filter-name='^Prod'>

=item B<--warning-status>

Warning threshold for cluster state.
Default: C<%{state} ne "COMPLETE">

Variables: C<%{name}>, C<%{state}>, C<%{version}>

=item B<--critical-status>

Critical threshold for cluster state.

=item B<--warning-nodes-count>

Warning threshold for node count.

=item B<--critical-nodes-count>

Critical threshold for node count.

=back

=cut
