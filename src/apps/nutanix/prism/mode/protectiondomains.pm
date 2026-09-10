#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package apps::nutanix::prism::mode::protectiondomains;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;
    return sprintf(
        "protection domain '%s' role is '%s' [replication: %s]",
        $self->{result_values}->{name},
        $self->{result_values}->{role},
        $self->{result_values}->{replication_status}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'pds',
            type             => 1,
            cb_prefix_output => 'prefix_pd_output',
            message_multiple => 'All protection domains are OK',
            skipped_code     => { -10 => 1 },
        }
    ];

    $self->{maps_counters}->{pds} = [
        # Replication health status
        {
            label            => 'status',
            type             => 2,
            critical_default => '%{replication_status} ne "Healthy" and %{replication_status} ne "N/A"',
            set              => {
                key_values => [
                    { name => 'name'               },
                    { name => 'role'               },
                    { name => 'replication_status' },
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        },
        # Pending replication snapshots
        {
            label  => 'pending-replications',
            nlabel => 'protection_domain.replications.pending.count',
            set    => {
                key_values      => [ { name => 'pending_replication_count' }, { name => 'name' } ],
                output_template => 'pending replications: %d',
                perfdatas       => [
                    {
                        template             => '%d',
                        min                  => 0,
                        label_extra_instance => 1,
                        instance_use         => 'name',
                    }
                ]
            }
        },
        # Number of vStores protected
        {
            label  => 'vstore-count',
            nlabel => 'protection_domain.vstores.count',
            set    => {
                key_values      => [ { name => 'vstore_count' }, { name => 'name' } ],
                output_template => 'vStores: %d',
                perfdatas       => [
                    {
                        template             => '%d',
                        min                  => 0,
                        label_extra_instance => 1,
                        instance_use         => 'name',
                    }
                ]
            }
        },
    ];
}

sub prefix_pd_output {
    my ($self, %options) = @_;
    return "Protection domain '" . $options{instance_value}->{name} . "' ";
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

    my $result   = $options{custom}->get_protection_domains();
    my $entities = $result->{entities} // [];

    $self->{pds} = {};
    for my $pd (@{$entities}) {
        my $name = $pd->{name} // 'unknown';

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '') {
            next if $name !~ /$self->{option_results}->{filter_name}/;
        }

        # Derive replication health from replication_links array.
        # Any non-Healthy link marks the whole PD as Degraded.
        my $replication_status = 'N/A';
        my @links = @{ $pd->{replication_links} // [] };
        if (@links) {
            my @degraded = grep { ($_->{replication_status} // 'Healthy') ne 'Healthy' } @links;
            $replication_status = @degraded ? 'Degraded' : 'Healthy';
        }

        # active=true means this is the active (primary) site; false means standby.
        my $role = ($pd->{active} // 0) ? 'Active' : 'Standby';

        # vstore_count may be an integer or we derive it from the vstore_names array.
        my $vstore_count = $pd->{vstore_count}
            // scalar(@{ $pd->{vstore_names} // [] });

        $self->{pds}->{$name} = {
            name                    => $name,
            role                    => $role,
            replication_status      => $replication_status,
            pending_replication_count => $pd->{pending_replication_count} // 0,
            vstore_count            => $vstore_count,
        };
    }

    if (scalar(keys %{$self->{pds}}) == 0) {
        $self->{output}->add_option_msg(short_msg => 'No protection domain found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Monitor Nutanix protection domain replication status through Prism REST API.

=over 8

=item B<--filter-name>

Filter protection domains by name (regexp). Example: C<--filter-name='^PD-Prod'>

=item B<--warning-status>

Warning threshold for replication status.
Variables: C<%{name}>, C<%{role}>, C<%{replication_status}>

=item B<--critical-status>

Critical threshold for replication status.
Default: C<%{replication_status} ne "Healthy" and %{replication_status} ne "N/A">

=item B<--warning-pending-replications>

Warning threshold for pending replication count.

=item B<--critical-pending-replications>

Critical threshold for pending replication count.

=item B<--warning-vstore-count>

Warning threshold for vStore count.

=item B<--critical-vstore-count>

Critical threshold for vStore count.

=back

=cut
