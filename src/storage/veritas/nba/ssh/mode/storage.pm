#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package storage::veritas::nba::ssh::mode::storage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(trim is_excluded convert_bytes);

sub custom_space_usage_output {
    my ($self, %options) = @_;

    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_value . ' ' . $total_unit,
        $used_value . ' ' . $used_unit, $self->{result_values}->{prct_used},
        $free_value . ' ' . $free_unit, $self->{result_values}->{prct_free}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'partitions',
            type => COUNTER_TYPE_INSTANCE,
            prefix_output => "Partition '%{name}' ",
            message_multiple => 'All partitions are ok',
            skipped_code => { NO_VALUE() => 1 }
        }
    ];

    $self->{maps_counters}->{partitions} = [
        { label => 'status', type => COUNTER_KIND_TEXT, warning_default => '%{status} =~ /Degraded/i', critical_default => '%{status} =~ /Not Accessible/i', set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'space-usage', nlabel => 'partition.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'space-usage-free', nlabel => 'partition.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'space-usage-prct', nlabel => 'partition.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'name' }
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
        'include-name:s' => { name => 'include_name' },
        'exclude-name:s' => { name => 'exclude_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($result) = $options{custom}->execute_scenario(
        request => {
            interactive => 1,
            pty => {
                rows => 800,
                cols => 80
            },
            scenario => [
                { cmd => 'waitfor', options => { Match => 'Main_Menu>', Timeout => 30 } },
                { cmd => 'put', options => { String => "Manage\n" } },
                { cmd => 'waitfor', options => { Match => 'Manage>', Timeout => 5 } },
                { cmd => 'put', options => { String => "Storage\n" } },
                { cmd => 'waitfor', options => { Match => 'Storage>', Timeout => 5 } },
                { cmd => 'put', options => { String => "Show ALL\n" } },
                { cmd => 'waitfor', options => { Match => 'to quit|Waiting for data', Timeout => 20 } },
                { cmd => 'close' }
            ]
        }
    );

    # Partition      | Total      | Available  | Used       | %Used | Status
    # -------------------------------------------------------------------------------
    # MSDP           | 251 TB     | 80.49 TB   | 170.51 TB  | 68    | Optimal
    # Share          | 0 GB       | 0 GB       | 0 GB       | 0     | Not Configured
    # Unallocated    | 18.44 TB   | -          | -          | -     | -
    #
    # The per-volume tables that follow the partition summary have the same
    # header but are preceded by a title line instead of a blank line.
    $self->{output}->option_exit(short_msg => 'Cannot find the partition summary table in the output')
        if ($result !~ /\n[ \t]*\n-+\nPartition\s*\|\s*Total\s*\|[^\n]*\n-+\n(.*?)(?:\n[ \t]*\n|\z)/s);

    my $pattern = '^([0-9.]+)\s*([a-zA-Z]+)$';
    $self->{partitions} = {};
    foreach my $line (split(/\n/, $1)) {
        my ($name, $total, $free, $used, undef, $status) = map { trim($_) } split(/\|/, $line);
        next if (!defined($status) || $status eq '-');
        next if (is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}));

        $self->{partitions}->{$name} = { name => $name, status => $status };

        $total = convert_bytes(value => $total, pattern => $pattern);
        $used = convert_bytes(value => $used, pattern => $pattern);
        $free = convert_bytes(value => $free, pattern => $pattern);
        next if (!defined($total) || !defined($used) || !defined($free) || $total <= 0);

        $self->{partitions}->{$name}->{total} = $total;
        $self->{partitions}->{$name}->{used} = $used;
        $self->{partitions}->{$name}->{free} = $free;
        $self->{partitions}->{$name}->{prct_used} = $used * 100 / $total;
        $self->{partitions}->{$name}->{prct_free} = $free * 100 / $total;
    }

    $self->{output}->option_exit(short_msg => 'No partition found. Please check filters.')
        if (scalar(keys %{$self->{partitions}}) <= 0);
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ 'name', 'status' ]);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (sort keys %{$self->{partitions}}) {
        $self->{output}->add_disco_entry(name => $_, status => $self->{partitions}->{$_}->{status});
    }
}

1;

__END__

=head1 MODE

Check partitions (status and space usage).

This mode also supports service discovery (C<--disco-format>, C<--disco-show>).

=over 8

=item B<--filter-counters>

Define which counters (filtered by regular expression) should be monitored.
Can be: status, space-usage, space-usage-free, space-usage-prct.
Example: --filter-counters='status'

=item B<--include-name>

Filter partitions by name (regexp).

=item B<--exclude-name>

Exclude partitions by name (regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: C<'%{status} =~ /Degraded/i'>).
You can use the following variables: C<%{status}>, C<%{name}>

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{status} =~ /Not Accessible/i'>).
You can use the following variables: C<%{status}>, C<%{name}>

=item B<--warning-space-usage>

Threshold in bytes.

=item B<--critical-space-usage>

Threshold in bytes.

=item B<--warning-space-usage-free>

Threshold in bytes.

=item B<--critical-space-usage-free>

Threshold in bytes.

=item B<--warning-space-usage-prct>

Threshold in percentage.

=item B<--critical-space-usage-prct>

Threshold in percentage.

=back

=cut
