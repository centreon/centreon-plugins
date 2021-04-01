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

package apps::monitoring::netdata::restapi::mode::disks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        'total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub prefix_diskpath_output {
    my ($self, %options) = @_;

    return "Partition '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'diskpath', type => 1, cb_prefix_output => 'prefix_diskpath_output', message_multiple => 'All partitions are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'count', nlabel => 'storage.partitions.count', display_ok => 0, set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Partitions count : %d',
                perfdatas => [ { label => 'count', value => 'count', template => '%d', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{diskpath} = [
        { label => 'usage', nlabel => 'storage.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'free', display_ok => 0, nlabel => 'storage.space.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'storage.space.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'display' } ],
                output_template => 'used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'chart-period:s'      => { name => 'chart_period', default => '300' },
        'chart-statistics:s'  => { name => 'chart_statistics', default => 'average' },
        'fs-name:s'           => { name => 'fs_name' },
        'space-reservation'   => { name => 'space_reservation'}
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $full_list = $options{custom}->list_charts();

    foreach my $chart (values %{$full_list->{charts}}) {
        next if ($chart->{name} !~ 'disk_space._');
        push @{$self->{fs_list}}, $chart->{name};
    }

    foreach my $fs (@{$self->{fs_list}}) {
        my $result = $options{custom}->get_data(
            chart => $fs,
            dimensions => 'used,avail,reserved_for_root',
            after_period => $self->{option_results}->{chart_period},
            group => $self->{option_results}->{chart_statistics}
        );

        $fs =~ s/disk_space.//;
        $fs =~ s/_/\//g;

        next if (defined($self->{option_results}->{fs_name}) &&
            $self->{option_results}->{fs_name} ne '' &&
            $fs !~ /$self->{option_results}->{fs_name}/
        );

        foreach my $fs_value (@{$result->{data}}) {
            foreach my $fs_label (@{$result->{labels}}) {
                $self->{fs}->{$fs}->{$fs_label} = shift @{$fs_value};
            }
        }

        my $reserved_space = defined($self->{option_results}->{space_reservation}) ? $self->{fs}->{$fs}->{'reserved for root'} * (1024 ** 3) : '0';
        my $used = $self->{fs}->{$fs}->{used} * (1024 ** 3);
        my $free = $self->{fs}->{$fs}->{avail} * (1024 ** 3);
        my $total = $used + $free + $reserved_space;
        my $prct_used = $used * 100 / $total;
        my $prct_free = 100 - $prct_used;

        if ($prct_used > 100) {
            $free = 0;
            $prct_used = 100;
            $prct_free = 0;
        }

        $self->{diskpath}->{$fs} = {
            display => $fs,
            used => $used,
            total => $total,
            free => $free,
            prct_used => $prct_used,
            prct_free => $prct_free
        };
        $self->{global}->{count}++;
    }
};

1;

__END__

=head1 MODE

Check disks FS usage of *nix based servers using the Netdata agent RestAPI.

Example:
perl centreon_plugins.pl --plugin=apps::monitoring::netdata::restapi::plugin
--mode=disks --hostname=10.0.0.1 --chart-period=300 --chart-statistics=average --warning-usage-prct=80 --critical-usage-prct=90 --verbose

More information on'https://learn.netdata.cloud/docs/agent/web/api'.

=over 8

=item B<--chart-period>

The period in seconds on which the values are calculated
Default: 300

=item B<--chart-statistic>

The statistic calculation method used to parse the collected data.
Can be : average, sum, min, max
Default: average

=item B<--fs-name>

Filter on one or more specific FS. Regexp can be used
Example: --fs-name='(^/$|^/boot$)'

=item B<--warning-usage>

Warning threshold on FS space usage (in B).

=item B<--critical-usage>

Critical threshold on FS space usage (in B).

=item B<--warning-usage-prct>

Warning threshold on FS percentage space usage (in %).

=item B<--critical-usage-prct>

Critical threshold on FS percentage space usage (in %).

=item B<--warning-free>

Warning threshold on FS free space.

=item B<--critical-free>

Critical threshold on FS free space.

=item B<--space-reservation>

On specific systems, partitions can have reserved space (like ext4 for root).
This option will consider this space in the calculation (like for the 'df' command).

=back

=cut
