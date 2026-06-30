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

package apps::nutanix::prism::mode::storageusage;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'storage_pools',
            type             => 1,
            cb_prefix_output => 'prefix_pool_output',
            message_multiple => 'All storage pools are OK',
            skipped_code     => { -10 => 1 },
        }
    ];

    $self->{maps_counters}->{storage_pools} = [
        # Used bytes
        {
            label  => 'usage',
            nlabel => 'storage.pool.usage.bytes',
            set    => {
                key_values          => [ { name => 'usage_bytes' }, { name => 'name' } ],
                output_template     => 'used: %s',
                output_change_bytes => 1,
                perfdatas           => [
                    {
                        template             => '%d',
                        unit                 => 'B',
                        min                  => 0,
                        label_extra_instance => 1,
                        instance_use         => 'name',
                    }
                ]
            }
        },
        # Free bytes
        {
            label  => 'free',
            nlabel => 'storage.pool.free.bytes',
            set    => {
                key_values          => [ { name => 'free_bytes' }, { name => 'name' } ],
                output_template     => 'free: %s',
                output_change_bytes => 1,
                perfdatas           => [
                    {
                        template             => '%d',
                        unit                 => 'B',
                        min                  => 0,
                        label_extra_instance => 1,
                        instance_use         => 'name',
                    }
                ]
            }
        },
        # Computed usage percentage
        {
            label  => 'usage-prct',
            nlabel => 'storage.pool.usage.percentage',
            set    => {
                key_values      => [ { name => 'usage_pct' }, { name => 'name' } ],
                output_template => 'usage: %.2f%%',
                perfdatas       => [
                    {
                        template             => '%.2f',
                        unit                 => '%',
                        min                  => 0,
                        max                  => 100,
                        label_extra_instance => 1,
                        instance_use         => 'name',
                    }
                ]
            }
        },
    ];
}

sub prefix_pool_output {
    my ($self, %options) = @_;
    return "Storage pool '" . $options{instance_value}->{name} . "' ";
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

    my $result   = $options{custom}->get_storage_pools();
    my $entities = $result->{entities} // [];

    $self->{storage_pools} = {};
    for my $pool (@{$entities}) {
        my $name = $pool->{name} // $pool->{storage_pool_uuid} // 'unknown';

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '') {
            next if $name !~ /$self->{option_results}->{filter_name}/;
        }

        my $capacity = $pool->{capacity_bytes} // 0;
        my $used     = $pool->{usage_bytes}    // 0;

        # Clamp free to 0 to avoid negative perfdata under thin-provisioning overcommit.
        my $free = $capacity - $used;
        $free = 0 if $free < 0;
        my $pct = ($capacity > 0) ? ($used / $capacity * 100) : 0;

        $self->{storage_pools}->{$name} = {
            name        => $name,
            usage_bytes => $used,
            free_bytes  => $free,
            usage_pct   => $pct,
        };
    }

    if (scalar(keys %{$self->{storage_pools}}) == 0) {
        $self->{output}->add_option_msg(short_msg => 'No storage pool found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Monitor Nutanix storage pool usage through Prism REST API.

=over 8

=item B<--filter-name>

Filter storage pools by name (regexp).

=item B<--warning-usage>

Warning threshold for used space (bytes).

=item B<--critical-usage>

Critical threshold for used space (bytes).

=item B<--warning-usage-prct>

Warning threshold for usage percentage (%).

=item B<--critical-usage-prct>

Critical threshold for usage percentage (%). Example: C<--critical-usage-prct=90>

=item B<--warning-free>

Warning threshold for free space (bytes).

=item B<--critical-free>

Critical threshold for free space (bytes).

=back

=cut
