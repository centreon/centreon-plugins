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

package storage::hitachi::eseries::local::mode::pool;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($used_value,  $used_unit)  = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($free_value,  $free_unit)  = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});

    return sprintf(
        'Usage - Total: %s Used: %s (%.1f%%) Free: %s (%.1f%%)',
        $total_value . ' ' . $total_unit,
        $used_value  . ' ' . $used_unit,  $self->{result_values}->{prct_used},
        $free_value  . ' ' . $free_unit,  $self->{result_values}->{prct_free}
    );
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{total}     = $options{new_datas}->{ $self->{instance} . '_total' };
    $self->{result_values}->{used}      = $options{new_datas}->{ $self->{instance} . '_used' };
    $self->{result_values}->{free}      = $options{new_datas}->{ $self->{instance} . '_free' };
    $self->{result_values}->{prct_used} = $options{new_datas}->{ $self->{instance} . '_prct_used' };
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};

    return NOT_PROCESSED unless $self->{result_values}->{total};
    return RUN_OK;
}

sub prefix_pool_output {
    my ($self, %options) = @_;
    return "Pool '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'pools', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_pool_output',
          message_multiple => 'All pools are ok', skipped_code => { NOT_PROCESSED() => 1 } }
    ];

    $self->{maps_counters}->{pools} = [
        { label => 'status', type => COUNTER_KIND_TEXT, critical_default => '%{status} ne "POLN"', set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                output_template => 'Status: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'usage', nlabel => 'storage.pool.space.usage.bytes', set => {
                key_values => [
                    { name => 'total' }, { name => 'used' }, { name => 'free' },
                    { name => 'prct_used' }, { name => 'display' }
                ],
                closure_custom_calc   => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas             => [
                    { value => 'used', template => '%d', unit => 'B',
                      min => 0, max => 'total', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-prct', nlabel => 'storage.pool.space.usage.percentage', set => {
                key_values      => [ { name => 'prct_used' }, { name => 'display' } ],
                output_template => 'Usage: %.1f%%',
                perfdatas       => [
                    { value => 'prct_used', template => '%.1f', unit => '%',
                      min => 0, max => 100, label_extra_instance => 1 }
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
        'include-pid:s' => { name => 'include_pid', default => '' },
        'exclude-pid:s' => { name => 'exclude_pid', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # https://docs.hitachivantara.com/r/en-us/command-control-interface/01-87-03/mk-90rd7009/configuration-setting-commands/raidcom-get-pool
    my ($stdout) = $options{custom}->execute_command(
        command         => 'raidcom',
        command_options => 'get pool -I' . $options{custom}->get_instance_id()
    );

    # Columns: PID POLS U(%) SSCNT Av(MB) Tp(MB) Seq# Num LDEV# H TH ...
    $self->{pools} = {};
    foreach my $line (split /\n/, $stdout) {
        next if $line =~ /^PID/;
        next if $line =~ /^\s*$/;

        my @fields = split /\s+/, $line;
        next unless @fields > 5;

        my ($pid, $pols, $usage_prct, $capa_available_mb, $capacity_mb) =
            ($fields[0], $fields[1], $fields[2], $fields[4], $fields[5]);

        next unless defined($pid) && $pid =~ /^\d+$/;

        next if is_excluded($pid, $self->{option_results}->{include_pid}, $self->{option_results}->{exclude_pid});

        my $capacity_b  = $capacity_mb * 1024 * 1024;
        my $available_b = $capa_available_mb * 1024 * 1024;
        my $used_b      = $capacity_b - $available_b;

        $self->{pools}->{$pid} = {
            display   => $pid,
            status    => $pols,
            total     => $capacity_b,
            used      => $used_b,
            free      => $available_b,
            prct_used => $usage_prct
        };
    }

    $self->{output}->option_exit(short_msg => "No pool found.")
        unless keys %{$self->{pools}};
}

1;

__END__

=head1 MODE

Check Hitachi E-Series pool status and capacity.

Command used: C<raidcom get pool -I<instance-id>>

=over 8

=item B<--include-pid>

Filter pools by PID (regexp).

=item B<--exclude-pid>

Exclude pools by PID (regexp).

=item B<--warning-status>

Warning threshold for pool status.

=item B<--critical-status>

Critical threshold for pool status (default: C<'%{status} ne "POLN"'>).

=item B<--warning-usage>

Warning threshold in bytes for pool space usage.

=item B<--critical-usage>

Critical threshold in bytes for pool space usage.

=item B<--warning-usage-prct>

Warning threshold in percentage for pool space usage.

=item B<--critical-usage-prct>

Critical threshold in percentage for pool space usage.

=back

=cut
