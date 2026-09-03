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

package apps::nutanix::prism::mode::storagecontainers;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'containers',
            type             => 1,
            cb_prefix_output => 'prefix_container_output',
            message_multiple => 'All storage containers are OK',
            skipped_code     => { -10 => 1 },
        }
    ];

    $self->{maps_counters}->{containers} = [
        # Used bytes
        {
            label  => 'usage',
            nlabel => 'storage.container.usage.bytes',
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
            nlabel => 'storage.container.free.bytes',
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
        # Usage percentage
        {
            label  => 'usage-prct',
            nlabel => 'storage.container.usage.percentage',
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
        # Compression saving ratio as a percentage (0 when disabled)
        {
            label  => 'compression-savings',
            nlabel => 'storage.container.compression.savings.percentage',
            set    => {
                key_values      => [ { name => 'compression_savings_pct' }, { name => 'name' } ],
                output_template => 'compression savings: %.2f%%',
                perfdatas       => [
                    {
                        template             => '%.2f',
                        unit                 => '%',
                        min                  => 0,
                        label_extra_instance => 1,
                        instance_use         => 'name',
                    }
                ]
            }
        },
        # Deduplication saving ratio as a percentage (0 when disabled)
        {
            label  => 'dedup-savings',
            nlabel => 'storage.container.dedup.savings.percentage',
            set    => {
                key_values      => [ { name => 'dedup_savings_pct' }, { name => 'name' } ],
                output_template => 'dedup savings: %.2f%%',
                perfdatas       => [
                    {
                        template             => '%.2f',
                        unit                 => '%',
                        min                  => 0,
                        label_extra_instance => 1,
                        instance_use         => 'name',
                    }
                ]
            }
        },
    ];
}

sub prefix_container_output {
    my ($self, %options) = @_;
    return "Storage container '" . $options{instance_value}->{name} . "' ";
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

    my $result   = $options{custom}->get_storage_containers();
    my $entities = $result->{entities} // [];

    $self->{containers} = {};
    for my $container (@{$entities}) {
        my $name = $container->{name} // $container->{storage_container_uuid} // 'unknown';

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '') {
            next if $name !~ /$self->{option_results}->{filter_name}/;
        }

        my $ustats   = $container->{usage_stats} // {};
        my $capacity = $container->{max_capacity}
            // $ustats->{'storage.capacity_bytes'}
            // 0;
        my $used = $ustats->{'storage.usage_bytes'} // 0;

        # Clamp free to avoid negative perfdata on overcommitted containers.
        my $free = $capacity - $used;
        $free = 0 if $free < 0;
        my $pct = ($capacity > 0) ? ($used / $capacity * 100) : 0;

        # Savings ratios are stored as PPM; divide by 10000 for percentage.
        my $compression_pct = ($container->{compression_saving_ratio_ppm} // 0) / 10000;
        my $dedup_pct       = ($container->{dedup_saving_ratio_ppm}       // 0) / 10000;

        my $key = $container->{storage_container_uuid} // $name;
        $self->{containers}->{$key} = {
            name                  => $name,
            usage_bytes           => $used,
            free_bytes            => $free,
            usage_pct             => $pct,
            compression_savings_pct => $compression_pct,
            dedup_savings_pct     => $dedup_pct,
        };
    }

    if (scalar(keys %{$self->{containers}}) == 0) {
        $self->{output}->add_option_msg(short_msg => 'No storage container found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Monitor Nutanix storage container usage and savings through Prism REST API.

=over 8

=item B<--filter-name>

Filter storage containers by name (regexp).

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

=item B<--warning-compression-savings>

Warning threshold for compression saving ratio (%).

=item B<--critical-compression-savings>

Critical threshold for compression saving ratio (%).

=item B<--warning-dedup-savings>

Warning threshold for deduplication saving ratio (%).

=item B<--critical-dedup-savings>

Critical threshold for deduplication saving ratio (%).

=back

=cut
