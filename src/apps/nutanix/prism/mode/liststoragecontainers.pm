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

package apps::nutanix::prism::mode::liststoragecontainers;

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

    my $result   = $options{custom}->get_storage_containers();
    my $entities = $result->{entities} // [];

    my @containers;
    for my $container (@{$entities}) {
        my $name = $container->{name} // $container->{storage_container_uuid} // 'unknown';
        my $id   = $container->{storage_container_uuid} // '';

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '') {
            next if $name !~ /$self->{option_results}->{filter_name}/;
        }

        my $ustats   = $container->{usage_stats} // {};
        my $capacity = $container->{max_capacity}
            // $ustats->{'storage.capacity_bytes'}
            // 0;
        my $used  = $ustats->{'storage.usage_bytes'} // 0;
        my $pct   = ($capacity > 0) ? ($used / $capacity * 100) : 0;

        push @containers, {
            name                 => $name,
            id                   => $id,
            usage_pct            => sprintf('%.2f', $pct),
            compression_enabled  => ($container->{compression_enabled}  // 0) ? 'true' : 'false',
            dedup_enabled        => ($container->{on_disk_dedup}        // 0) ? 'true' : 'false',
        };
    }

    return @containers;
}

sub run {
    my ($self, %options) = @_;

    my @containers = $self->manage_selection(%options);
    for my $c (sort { $a->{name} cmp $b->{name} } @containers) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[name: %s] [id: %s] [usage_pct: %s%%] [compression: %s] [dedup: %s]',
                $c->{name},
                $c->{id},
                $c->{usage_pct},
                $c->{compression_enabled},
                $c->{dedup_enabled},
            )
        );
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => sprintf('%d storage container(s) found', scalar @containers)
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(
        elements => [ 'name', 'id', 'usage_pct', 'compression_enabled', 'dedup_enabled' ]
    );
}

sub disco_show {
    my ($self, %options) = @_;

    my @containers = $self->manage_selection(%options);
    for my $c (@containers) {
        $self->{output}->add_disco_entry(
            name                => $c->{name},
            id                  => $c->{id},
            usage_pct           => $c->{usage_pct},
            compression_enabled => $c->{compression_enabled},
            dedup_enabled       => $c->{dedup_enabled},
        );
    }
}

1;

__END__

=head1 MODE

List Nutanix storage containers (Centreon service discovery).

=over 8

=item B<--filter-name>

Filter storage containers by name (regexp).

=back

=cut
