#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package database::oracle::mode::temptablespace;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

my $instance_mode;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    if (defined($instance_mode->{option_results}->{free})) {
        $label = 'free';
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($instance_mode->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(label => $label,
                                  value => $value_perf, unit => 'B',
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options),
                                  min => 0, max => $self->{result_values}->{total});
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($instance_mode->{option_results}->{free}));
    if ($instance_mode->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($instance_mode->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Total: %s%s Used: %s%s (%.2f%%) Free: %s%s (%.2f%%)",
                   $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
                   $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}), $self->{result_values}->{prct_used},
                   $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}), $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'tmptablespace', type => 1, cb_prefix_output => 'prefix_tablespace_output', message_multiple => 'All temporary tablespaces are OK' },
    ];

    $self->{maps_counters}->{tmptablespace} = [
        { label => 'usage', set => {
                key_values => [ { name => 'used' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_calc => \&custom_usage_calc,
                closure_custom_output => \&custom_usage_output,
                closure_custom_perfdata => \&custom_usage_perfdata,
                closure_custom_threshold_check => \&custom_usage_threshold,
            }
        },
    ];
}

sub prefix_tablespace_output {
    my ($self, %options) = @_;

    return "Temp Tablespace '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 0);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "units:s"           => { name => 'units', default => '%' },
                                  "free"              => { name => 'free' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $instance_mode = $self;
}


sub manage_selection {
    my ($self, %options) = @_;
    $self->{sql} = $options{sql};
    $self->{sql}->connect();

    my $query = q{
                WITH
                TMP as
                (
                SELECT
                    B.name,
                    C.block_size,
                    SUM (C.bytes) b_total
                 FROM
                    v$tablespace B join
                    v$tempfile C
                    using  ( ts#)
                 GROUP BY
                    B.name, C.block_size
                )
                SELECT
                    A.tablespace_name tablespace, TMP.b_total,
                    SUM (A.used_blocks * TMP.block_size) b_used,
                    TMP.b_total - SUM (A.used_blocks * TMP.block_size) / 1024 b_free
                FROM
                    v$sort_segment A join TMP on A.tablespace_name = TMP.name
                GROUP by
                    A.tablespace_name, TMP.b_total
                };

    $self->{sql}->query(query => $query);

    while (my $result = $self->{sql}->fetchrow_hashref()) {
        $self->{tmptablespace}->{$result->{TABLESPACE}} = { used => $result->{B_USED}, total => $result->{B_TOTAL}, display => lc $result->{TABLESPACE} };
    }
}

1;

__END__

=head1 MODE

Check Oracle TEMP tablespaces

=over 8

=item B<--units>

Unit of thresholds (Can be : '%' (default) or 'B')

=item B<--free>

Threshold are on free space left

=item B<--warning-usage>

Threshold warning.

=item B<--critical-usage>

Threshold critical.

=back

=cut
