#
# Copyright 2021 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and alarm monitoring for
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

package apps::monitoring::netdata::restapi::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        'Ram total: %s %s used (-buffers/cache): %s %s (%.2f%%) free: %s %s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'ram', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{ram} = [
        { label => 'usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' } ],
                output_template => 'Ram used : %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'buffer', nlabel => 'memory.buffer.bytes', set => {
                key_values => [ { name => 'buffers' } ],
                output_template => 'Buffer: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', min => 0, unit => 'B' }
                ]
            }
        },
        { label => 'cached', nlabel => 'memory.cached.bytes', set => {
                key_values => [ { name => 'cached' } ],
                output_template => 'Cached: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', min => 0, unit => 'B' }
                ]
            }
        },
        { label => 'shared', nlabel => 'memory.shared.bytes', set => {
                key_values => [ { name => 'memShared' } ],
                output_template => 'Shared: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', min => 0, unit => 'B' }
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
        'chart-statistics:s'  => { name => 'chart_statistics', default => 'average' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get_data(
        chart => 'system.ram',
        points => $self->{option_results}->{chart_point},
        after_period => $self->{option_results}->{chart_period},
        group => $self->{option_results}->{chart_statistics}
    );
    foreach my $memory_value (@{$result->{data}}) {
        foreach my $memory_label (@{$result->{labels}}) {
            $self->{ram_data}->{$memory_label} = shift @{$memory_value};
        }
    }

    my $total = $options{custom}->get_info(filter_info => 'ram_total');
    my $used = $self->{ram_data}->{used} * 1024 * 1024;
    my $free = $self->{ram_data}->{free} * 1024 * 1024;
    my $prct_used = $used * 100 / $total;
    my $prct_free = 100 - $prct_used;
    my $cached = $self->{ram_data}->{cached} * 1024 * 1024;
    my $buffers = $self->{ram_data}->{buffers} * 1024 * 1024;

    $self->{ram} = {
        total => $total,
        used => $used,
        free  => $free,
        prct_used => $prct_used,
        prct_free => $prct_free,
        cached => $cached,
        buffers => $buffers
    };
};

1;

__END__

=head1 MODE

Check *nix based servers memory using the Netdata agent RestAPI.

Example:
perl centreon-plugins/centreon_plugins.pl --plugin=apps::monitoring::netdata::restapi::plugin
--mode=memory --hostname=10.0.0.1 --chart-period=300 --warning-usage-prct=80 --critical-usage-prct=90 --verbose

More information on 'https://learn.netdata.cloud/docs/agent/web/api'.

=over 8

=item B<--chart-period>

The period in seconds on which the values are calculated
Default: 300

=item B<--chart-statistic>

The statistic calculation method used to parse the collected data.
Can be : average, sum, min, max
Default: average

=item B<--warning-usage>

Warning threshold on used memory (in B).

=item B<--critical-usage>

Critical threshold on used memory (in B)

=item B<--warning-usage-prct>

Warning threshold on used memory (in %).

=item B<--critical-usage-prct>

Critical threshold on percentage used memory (in %)

=item B<--warning-usage-free>

Warning threshold on free memory (in B).

=item B<--critical-usage-free>

Critical threshold on free memory (in B)

=item B<--warning-*>

Warning threshold (in B) on other metrics where '*' can be:
buffer,cached,shared

=item B<--critical-*>

Critical threshold (in B) on other metrics where '*' can be:
buffer,cached,shared


=back

=cut
