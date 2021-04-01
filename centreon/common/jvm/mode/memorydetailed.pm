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

package centreon::common::jvm::mode::memorydetailed;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my %mapping_memory = (
    'Eden Space' => 'eden',
    'Par Eden Space' => 'eden',
    'PS Eden Space' => 'eden',
    'Survivor Space' => 'survivor',
    'Par Survivor Space' => 'survivor',
    'PS Survivor Space' => 'survivor',
    'CMS Perm Gen' => 'permanent',
    'PS Perm Gen' => 'permanent',
    'Perm Gen' => 'permanent',
    'Metaspace' => 'permanent',
    'JIT data cache' => 'permanent',
    'Code Cache' => 'code',
    'JIT Code Cache' => 'code',
    'CMS Old Gen' => 'tenured',
    'PS Old Gen' => 'tenured',
    'Tenured Gen' => 'tenured',
);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'mem', type => 1, cb_prefix_output => 'prefix_mem_output', message_multiple => 'All memories within bounds', skipped_code => { -12 => 1 } },
    ];
    
    $self->{maps_counters}->{mem} = [
        { label => 'eden', set => {
                key_values => [ { name => 'used' }, { name => 'max' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
            }
        },
        { label => 'tenured', set => {
                key_values => [ { name => 'used' }, { name => 'max' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
            }
        },
        { label => 'survivor', set => {
                key_values => [  { name => 'used' }, { name => 'max' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
            }
        },
        { label => 'permanent', set => {
                key_values => [ { name => 'used' }, { name => 'max' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
            }
        },
        { label => 'code', set => {
                key_values => [ { name => 'used' }, { name => 'max' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
            }
        },
    ];
}

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

    $self->{output}->perfdata_add(label => $self->{label}, unit => 'B',
                                  value => $value_perf,
                                  warning => $use_th == 1 ? $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options) : undef,
                                  critical => $use_th == 1 ? $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options) : undef,
                                  min => 0, max => $self->{result_values}->{max} > 0 ? $self->{result_values}->{max} : undef);
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
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my $msg;
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    if ($self->{result_values}->{max} > 0) {
        my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{max});
        my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{max} - $self->{result_values}->{used});
        $msg = sprintf("Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                   $total_free_value . " " . $total_free_unit, 100 - $self->{result_values}->{prct_used});
    } else {
        $msg = sprintf("Used: %s", $total_used_value . " " . $total_used_unit);
    }
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    if ($mapping_memory{$options{new_datas}->{$self->{instance} . '_display'}} ne $self->{label}) {
        return -12;
    }
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{max} = $options{new_datas}->{$self->{instance} . '_max'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    if ($self->{result_values}->{max} > 0) {
        $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{max};
    }

    return 0;
}

sub prefix_mem_output {
    my ($self, %options) = @_;

    return "Memory '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "units:s"       => { name => 'units', default => '%' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{request} = [
         { mbean => "java.lang:type=MemoryPool,name=*", attributes => [ { name => 'Usage' } ] }
    ];
    
    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 1);

    $self->{mem} = {};
    foreach my $key (keys %$result) {
        $key =~ /(?:[:,])name=(.*?)(?:,|$)/;
        my $memtype = $1;
        
        if (!defined($mapping_memory{$memtype})) {
            $self->{output}->output_add(long_msg => "unknown memory type: " . $memtype, debug => 1);
            next;
        }
        
        $self->{mem}->{$memtype} = {
            display => $memtype,
            used => $result->{"java.lang:name=" . $memtype . ",type=MemoryPool"}->{Usage}->{used},
            max => $result->{"java.lang:name=".$memtype.",type=MemoryPool"}->{Usage}->{max},
        };
    }
}

1;

__END__

=head1 MODE

Check JVM Memory Pools :

Eden Space           (heap)     (-eden)      : The pool from which memory is initially allocated for most objects.
Survivor Space       (heap)     (-survivor)  : The pool containing objects that have survived the garbage collection of the Eden space.
Tenured Generation   (heap)     (-tenured)   : The pool containing objects that have existed for some time in the survivor space.
Permanent Generation (non-heap) (-permanent) : The pool containing all the reflective data of the virtual machine itself, such as class and method objects. 
Code Cache           (non-heap) (-code)      : The HotSpot Java VM also includes a code cache, containing memory that is used for compilation and storage of native code.

Example:
perl centreon_plugins.pl --plugin=apps::tomcat::jmx::plugin --custommode=jolokia --url=http://10.30.2.22:00/jolokia-war --mode=memory-detailed --warning-eden 60 --critical-eden 75 --warning-survivor 65 --critical-survivor 75

=over 8

=item B<--warning-eden>

Threshold warning of Heap 'Eden Space' memory usage

=item B<--critical-eden>

Threshold critical of Heap 'Survivor Space' memory usage

=item B<--warning-tenured>

Threshold warning of Heap 'Tenured Generation'  memory usage

=item B<--critical-tenured>

Threshold critical of Heap 'Tenured Generation'  memory usage

=item B<--warning-survivor>

Threshold warning of Heap 'Survivor Space' memory usage

=item B<--critical-survivor>

Threshold critical of Heap 'Survivor Space' memory usage

=item B<--warning-permanent>

Threshold warning of NonHeap 'Permanent Generation' memory usage

=item B<--critical-permanent>

Threshold critical of NonHeap 'Permanent Generation' memory usage

=item B<--warning-code>

Threshold warning of NonHeap 'Code Cache' memory usage

=item B<--critical-code>

Threshold critical of NonHeap 'Code Cache' memory usage

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=back

=cut
