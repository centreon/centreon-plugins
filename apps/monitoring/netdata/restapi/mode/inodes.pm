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

package apps::monitoring::netdata::restapi::mode::inodes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'inodes', type => 1, cb_prefix_output => 'prefix_inodes_output', message_multiple => 'All inode partitions are ok' }
    ];

    $self->{maps_counters}->{inodes} = [
        { label => 'usage-prct', nlabel => 'storage.inodes.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'display' } ],
                output_template => 'Used: %.2f %%',
                perfdatas => [
                    { template => '%d', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ]
            }
        }
    ];
}

sub prefix_inodes_output {
    my ($self, %options) = @_;

    return "Inodes partition '" . $options{instance_value}->{display} . "' ";
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
        next if ($chart->{name} !~ 'disk_inodes._');
        push @{$self->{fs_list}}, $chart->{name};
    }

    foreach my $fs (@{$self->{fs_list}}) {
        my $result = $options{custom}->get_data(
            chart => $fs,
            dimensions => 'used,avail,reserved_for_root',
            points => $self->{option_results}->{chart_point},
            after_period => $self->{option_results}->{chart_period},
            group => $self->{option_results}->{chart_statistics}
        );

        $fs =~ s/disk_inodes.//;
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

        my $reserved_space = defined($self->{option_results}->{space_reservation}) ? $self->{fs}->{$fs}->{"reserved for root"}  : '0';
        my $used = $self->{fs}->{$fs}->{used};
        my $free = $self->{fs}->{$fs}->{avail};
        my $total = $used + $free + $reserved_space;
        my $prct_used = $used * 100 / $total;
        my $prct_free = 100 - $prct_used;

        $self->{inodes}->{$fs} = {
            display => $fs,
            used => $used,
            total => $total,
            free => $free,
            prct_used => $prct_used,
            prct_free => $prct_free
        };
        $self->{global}->{count}++;
    }

    if (scalar(keys %{$self->{inodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'Issue with disk path information (see details)');
        $self->{output}->option_exit();
    }
};

1;

__END__

=head1 MODE

Check disks FS inodes of *nix based servers using the Netdata agent RestAPI.

Example:
perl centreon_plugins.pl --plugin=apps::monitoring::netdata::restapi::plugin
--mode=inodes --hostname=10.0.0.1 --chart-period=300 --chart-statistics=average --warning-usage-prct=80 --critical-usage-prct=90 --verbose

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

=item B<--warning-usage-prct>

Warning threshold on FS used Inodes  (in %).

=item B<--critical-usage-prct>

Critical threshold on FS used Inodes (in %).

=item B<--space-reservation>

On specific systems, partitions can have reserved space/inodes (like ext4 for root).
This option will consider this space in the calculation (like for the 'df' command).

=back

=cut
