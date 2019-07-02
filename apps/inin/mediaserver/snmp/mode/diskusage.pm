#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package apps::inin::mediaserver::snmp::mode::diskusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'disktracelog', type => 0 },
        { name => 'diskhttpcache', type => 0 },
    ];

    $self->{maps_counters}->{disktracelog} = [
        { label => 'tracelog-usage', set => {
                key_values => [ { name => 'free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
    $self->{maps_counters}->{diskhttpcache} = [
        { label => 'httpcache-usage', set => {
                key_values => [ { name => 'free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = 'used_' . $self->{result_values}->{display};
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        $label = 'free_' . $self->{result_values}->{display};
        $value_perf = $self->{result_values}->{free};
    }
    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(label => $label, unit => 'B',
                                  value => $value_perf,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options),
                                  min => 0, max => $self->{result_values}->{total});
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my $msg = sprintf("Disk '%s' Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                    $self->{result_values}->{display},
                    $total_size_value . " " . $total_size_unit,
                    $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                    $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_free'};
    $self->{result_values}->{used} = $self->{result_values}->{total} - $self->{result_values}->{free};
    
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "units:s"   => { name => 'units', default => '%' },
        "free"      => { name => 'free' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $oid_i3MsGeneralInfoTracelogFreeDiskSpace = '.1.3.6.1.4.1.2793.8227.1.12.0'; # MiB
    my $oid_i3MsGeneralInfoTracelogTotalDiskSpace = '.1.3.6.1.4.1.2793.8227.1.13.0'; # MiB
    my $oid_i3MsGeneralInfoHttpCacheFreeDiskSpace = '.1.3.6.1.4.1.2793.8227.1.15.0'; # MiB
    my $oid_i3MsGeneralInfoHttpCacheTotalDiskSpace = '.1.3.6.1.4.1.2793.8227.1.16.0'; # MiB

    my $snmp_result = $options{snmp}->get_leef(oids => [
            $oid_i3MsGeneralInfoTracelogFreeDiskSpace, $oid_i3MsGeneralInfoTracelogTotalDiskSpace,
            $oid_i3MsGeneralInfoHttpCacheFreeDiskSpace, $oid_i3MsGeneralInfoHttpCacheTotalDiskSpace
        ], nothing_quit => 1);

    $self->{disktracelog} = { 
        free => $snmp_result->{$oid_i3MsGeneralInfoTracelogFreeDiskSpace} * 1024 * 1024,
        total => $snmp_result->{$oid_i3MsGeneralInfoTracelogTotalDiskSpace} * 1024 * 1024,
        display => 'tracelog'
    };
    $self->{diskhttpcache} = {
        free => $snmp_result->{$oid_i3MsGeneralInfoHttpCacheFreeDiskSpace} * 1024 * 1024,
        total => $snmp_result->{$oid_i3MsGeneralInfoHttpCacheTotalDiskSpace} * 1024 * 1024,
        display => 'httpcache'
    };
}

1;

__END__

=head1 MODE

Check disk usages.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'httpcache-usage', 'tracelog-usage'.

=item B<--critical-*>

Threshold critical.
Can be: 'httpcache-usage', 'tracelog-usage'.

=item B<--units>

Default is '%', can be 'B'

=item B<--free>

Thresholds are on free space left.

=back

=cut
