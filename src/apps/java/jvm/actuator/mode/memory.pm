#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package apps::java::jvm::actuator::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    my $use_th = 1;
    $use_th = 0 if ($self->{instance_mode}->{option_results}->{units} eq '%' && $self->{result_values}->{max} <= 0);

    my $value_perf = $self->{result_values}->{used};
    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%' && $self->{result_values}->{max} > 0) {
        $total_options{total} = $self->{result_values}->{max};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 'B',
        value => $value_perf,
        warning => $use_th == 1 ? $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options) : undef,
        critical => $use_th == 1 ? $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options) : undef,
        min => 0, max => $self->{result_values}->{max} > 0 ? $self->{result_values}->{max} : undef
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    # Cannot use percent without total
    return 'ok' if ($self->{result_values}->{max} <= 0 && $self->{instance_mode}->{option_results}->{units} eq '%');
    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
    }
    $exit = $self->{perfdata}->threshold_check(
        value => $threshold_value, threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my $msg;
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    if ($self->{result_values}->{max} > 0) {
        my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{max});
        my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{max} - $self->{result_values}->{used});
        $msg = sprintf(
            "%s Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)", $self->{result_values}->{label},
            $total_size_value . " " . $total_size_unit,
            $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
            $total_free_value . " " . $total_free_unit, 100 - $self->{result_values}->{prct_used}
        );
    } else {
        $msg = sprintf(
            "%s Used: %s",
            $self->{result_values}->{label},
            $total_used_value . " " . $total_used_unit
        );
    }

    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{label} = $options{new_datas}->{$self->{label} . '_label'};    
    $self->{result_values}->{max} = $options{new_datas}->{$self->{instance} . '_max'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};

    if ($self->{result_values}->{max} > 0) {
        $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{max};
    }
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'heap', type => 0 },
        { name => 'nonheap', type => 0 }
    ];

    $self->{maps_counters}->{heap} = [
        { label => 'heap', nlabel => 'memory.heap.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'max' }, { name => 'label' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold')
            }
        },
    ];

    $self->{maps_counters}->{nonheap} = [
        { label => 'nonheap', nlabel => 'memory.nonheap.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'max' }, { name => 'label' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'units:s' => { name => 'units', default => '%' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(endpoint => '/metrics/jvm.memory.max', get_param => ['tag=area:heap']);
    $self->{heap} = { label => 'HeapMemory', max => $result->{measurements}->[0]->{value} };
    $result = $options{custom}->request_api(endpoint => '/metrics/jvm.memory.used', get_param => ['tag=area:heap']);
    $self->{heap}->{used} = $result->{measurements}->[0]->{value};

    $result = $options{custom}->request_api(endpoint => '/metrics/jvm.memory.max', get_param => ['tag=area:nonheap']);
    $self->{nonheap} = { label => 'NonHeapMemoryUsage', max => $result->{measurements}->[0]->{value} };
    $result = $options{custom}->request_api(endpoint => '/metrics/jvm.memory.used', get_param => ['tag=area:nonheap']);
    $self->{nonheap}->{used} = $result->{measurements}->[0]->{value};
}

1;

__END__

=head1 MODE

Check Java Heap and NonHeap memory usage.

=over 8

=item B<--warning-heap>

Warning threshold of Heap memory usage

=item B<--critical-heap>

Critical threshold of Heap memory usage

=item B<--warning-nonheap>

Warning threshold of NonHeap memory usage

=item B<--critical-nonheap>

Critical threshold of NonHeap memory usage

=item B<--units>

Units of thresholds (default: '%') ('%', 'B').

=back

=cut
