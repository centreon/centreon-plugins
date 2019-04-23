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

package snmp_standard::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }
    
    $self->{output}->perfdata_add(label => 'used',
                                  unit => 'B',
                                  value => $self->{result_values}->{used},
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
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value,
                                               threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' },
                                                              { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Ram Total: %s %s Used (-buffers/cache): %s %s (%.2f%%)",
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_memTotalReal'};
    $self->{result_values}->{available} = $options{new_datas}->{$self->{instance} . '_memAvailReal'};
    $self->{result_values}->{buffer} = $options{new_datas}->{$self->{instance} . '_memBuffer'};
    $self->{result_values}->{cached} = $options{new_datas}->{$self->{instance} . '_memCached'};

    if ($self->{result_values}->{total} != 0) {
        $self->{result_values}->{physical_used} = $self->{result_values}->{total} - $self->{result_values}->{available};
        $self->{result_values}->{used} = $self->{result_values}->{physical_used} - $self->{result_values}->{buffer} - $self->{result_values}->{cached};
        $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    } else {
        $self->{result_values}->{used} = '0';
        $self->{result_values}->{prct_used} = '0';
    }

    return 0;
}

sub custom_swap_perfdata {
    my ($self, %options) = @_;

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }
    
    $self->{output}->perfdata_add(label => 'swap',
                                  unit => 'B',
                                  value => $self->{result_values}->{used},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options),
                                  min => 0, max => $self->{result_values}->{total});
}

sub custom_swap_threshold {
    my ($self, %options) = @_;
    
    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{available} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_available} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value,
                                               threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' },
                                                              { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_swap_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Swap Total: %s %s Used: %s %s (%.2f%%) Free: %s %s (%.2f%%)",
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{available}),
        $self->{result_values}->{prct_available});
    return $msg;
}

sub custom_swap_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_memTotalSwap'};
    $self->{result_values}->{available} = $options{new_datas}->{$self->{instance} . '_memAvailSwap'};

    if ($self->{result_values}->{total} != 0) {
        $self->{result_values}->{used} = $self->{result_values}->{total} - $self->{result_values}->{available};
        $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
        $self->{result_values}->{prct_available} = 100 - $self->{result_values}->{prct_used};
    } else {
        $self->{result_values}->{used} = '0';
        $self->{result_values}->{prct_used} = '0';
        $self->{result_values}->{prct_available} = '0';
    }

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'ram', type => 0 },
        { name => 'swap', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{ram} = [
        { label => 'usage', set => {
                key_values => [ { name => 'memTotalReal' }, { name => 'memAvailReal' }, { name => 'memTotalFree' },
                     { name => 'memBuffer' }, { name => 'memCached' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata')
            }
        },
        { label => 'buffer', set => {
                key_values => [ { name => 'memBuffer' } ],
                output_template => 'Buffer: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'buffer', value => 'memBuffer_absolute', template => '%d',
                      min => 0, unit => 'B' },
                ],
            }
        },
        { label => 'cached', set => {
                key_values => [ { name => 'memCached' } ],
                output_template => 'Cached: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'cached', value => 'memCached_absolute', template => '%d',
                      min => 0, unit => 'B' },
                ],
            }
        },
        { label => 'shared', set => {
                key_values => [ { name => 'memShared' } ],
                output_template => 'Shared: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'shared', value => 'memShared_absolute', template => '%d',
                      min => 0, unit => 'B' },
                ],
            }
        },
    ];
    $self->{maps_counters}->{swap} = [
        { label => 'swap', set => {
                key_values => [ { name => 'memTotalSwap' }, { name => 'memAvailSwap' } ],
                closure_custom_calc => $self->can('custom_swap_calc'),
                closure_custom_output => $self->can('custom_swap_output'),
                closure_custom_threshold_check => $self->can('custom_swap_threshold'),
                closure_custom_perfdata => $self->can('custom_swap_perfdata')
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments => { 
        "units:s"       => { name => 'units', default => '%' },
        "free"          => { name => 'free' },
        "swap"          => { name => 'check_swap' },
        "no-swap:s"     => { name => 'no_swap' }, # legacy
    });
    
    return $self;
}

my $mapping = {
    memTotalSwap => { oid => '.1.3.6.1.4.1.2021.4.3' },
    memAvailSwap => { oid => '.1.3.6.1.4.1.2021.4.4' },
    memTotalReal => { oid => '.1.3.6.1.4.1.2021.4.5' },
    memAvailReal => { oid => '.1.3.6.1.4.1.2021.4.6' },
    memTotalFree => { oid => '.1.3.6.1.4.1.2021.4.11' },
    memShared => { oid => '.1.3.6.1.4.1.2021.4.13' },
    memBuffer => { oid => '.1.3.6.1.4.1.2021.4.14' },
    memCached => { oid => '.1.3.6.1.4.1.2021.4.15' },
};

my $oid_memory = '.1.3.6.1.4.1.2021.4';

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_table(oid => $oid_memory);

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => 0);
    
    $self->{ram} = {
        memTotalReal => ($result->{memTotalReal}) ? $result->{memTotalReal} * 1024 : 0,
        memAvailReal => ($result->{memAvailReal}) ? $result->{memAvailReal} * 1024 : 0,
        memTotalFree => ($result->{memTotalFree}) ? $result->{memTotalFree} * 1024 : 0,
        memShared => ($result->{memShared}) ? $result->{memShared} * 1024 : 0,
        memBuffer => ($result->{memBuffer}) ? $result->{memBuffer} * 1024 : 0,
        memCached => ($result->{memCached}) ? $result->{memCached} * 1024 : 0,
    };

    if (defined($self->{option_results}->{check_swap})) {
        $self->{swap} = {
            memTotalSwap => ($result->{memTotalSwap}) ? $result->{memTotalSwap} * 1024 : 0,
            memAvailSwap => ($result->{memAvailSwap}) ? $result->{memAvailSwap} * 1024 : 0,
        };
    }
}

1;

__END__

=head1 MODE

Check memory usage (UCD-SNMP-MIB).

=over 8

=item B<--units>

Units of thresholds (Default: '%') ('%', 'absolute').

=item B<--free>

Thresholds are on free space left.

=item B<--swap>

Check swap also.

=item B<--warning-*>

Threshold warning.
Can be: 'usage', 'swap', 'buffer' (absolute),
'cached' (absolute), 'shared' (absolute).

=item B<--critical-*>

Threshold critical.
Can be: 'usage', 'swap', 'buffer' (absolute),
'cached' (absolute), 'shared' (absolute).

=back

=cut
