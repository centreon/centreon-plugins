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

package apps::nutanix::prism::mode::listprotectiondomains;

use strict;
use warnings;
use base qw(centreon::plugins::mode);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'filter-name:s' => { name => 'filter_name' },
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result   = $options{custom}->get_protection_domains();
    my $entities = $result->{entities} // [];

    my @pds;
    for my $pd (@{$entities}) {
        my $name = $pd->{name} // 'unknown';

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '') {
            next if $name !~ /$self->{option_results}->{filter_name}/;
        }

        # Derive replication health from replication_links array.
        my $replication_status = 'N/A';
        my @links = @{ $pd->{replication_links} // [] };
        if (@links) {
            my @degraded = grep { ($_->{replication_status} // 'Healthy') ne 'Healthy' } @links;
            $replication_status = @degraded ? 'Degraded' : 'Healthy';
        }

        my $vstore_count = $pd->{vstore_count}
            // scalar(@{ $pd->{vstore_names} // [] });

        push @pds, {
            name                      => $name,
            active                    => ($pd->{active} // 0) ? 'true' : 'false',
            replication_status        => $replication_status,
            vstore_count              => $vstore_count,
            pending_replication_count => $pd->{pending_replication_count} // 0,
        };
    }

    return @pds;
}

sub run {
    my ($self, %options) = @_;

    my @pds = $self->manage_selection(%options);
    for my $pd (sort { $a->{name} cmp $b->{name} } @pds) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[name: %s] [active: %s] [replication: %s] [vstores: %d] [pending_replications: %d]',
                $pd->{name},
                $pd->{active},
                $pd->{replication_status},
                $pd->{vstore_count},
                $pd->{pending_replication_count},
            )
        );
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => sprintf('%d protection domain(s) found', scalar @pds)
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(
        elements => [ 'name', 'active', 'replication_status', 'vstore_count', 'pending_replication_count' ]
    );
}

sub disco_show {
    my ($self, %options) = @_;

    my @pds = $self->manage_selection(%options);
    for my $pd (@pds) {
        $self->{output}->add_disco_entry(
            name                      => $pd->{name},
            active                    => $pd->{active},
            replication_status        => $pd->{replication_status},
            vstore_count              => $pd->{vstore_count},
            pending_replication_count => $pd->{pending_replication_count},
        );
    }
}

1;

__END__

=head1 MODE

List Nutanix protection domains (Centreon service discovery).

=over 8

=item B<--filter-name>

Filter protection domains by name (regexp).

=back

=cut
