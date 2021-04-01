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

package network::cyberoam::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(
        label => $self->{result_values}->{label} . '_used', unit => 'B',
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    
    return sprintf(
        "Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_used'} + $options{new_datas}->{$self->{instance} . '_free'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_free'};
    $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    return 0;
}

sub prefix_memory_output {
    my ($self, %options) = @_;
    
    return "Physical memory ";
}

sub prefix_swap_output {
    my ($self, %options) = @_;
    
    return "Swap memory ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'memory', type => 0, cb_prefix_output => 'prefix_memory_output' },
        { name => 'swap', type => 0, cb_prefix_output => 'prefix_swap_output' }
    ];
    
    $self->{maps_counters}->{memory} = [
        { label => 'physical-usage', set => {
                key_values => [ { name => 'free' }, { name => 'used' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'physical' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                threshold_use => 'prct_used'
            }
        }
    ];

    $self->{maps_counters}->{swap} = [
        { label => 'swap-usage', set => {
                key_values => [ { name => 'free' }, { name => 'used' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'swap' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                threshold_use => 'prct_used'
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});
    
    return $self;
}

sub add_counters {
    my ($self, %options) = @_;

    return if (!defined($options{result}->{memory_total}));

    my $memory_used = $options{result}->{memory_used_prct} * $options{result}->{memory_total} * 1024 * 1024 / 100;
    my $swap_used = $options{result}->{swap_used_prct} * $options{result}->{swap_total} * 1024 * 1024 / 100;
    $self->{memory} = {
        free => $options{result}->{memory_total} * 1024 * 1024 - $memory_used,
        used => $memory_used
    };
    $self->{swap} = {
        free => $options{result}->{swap_total} * 1024 * 1024 - $swap_used,
        used => $swap_used
    };
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        v17 => {
            memory_total     => { oid => '.1.3.6.1.4.1.21067.2.1.2.4.1' }, # memoryCapacity - MB
            memory_used_prct => { oid => '.1.3.6.1.4.1.21067.2.1.2.4.2' }, # memoryPercentUsage
            swap_total       => { oid => '.1.3.6.1.4.1.21067.2.1.2.4.3' }, # swapCapacity - MB
            swap_used_prct   => { oid => '.1.3.6.1.4.1.21067.2.1.2.4.4' }  # swapPercentUsage
        },
        v18 => {
            memory_total     => { oid => '.1.3.6.1.4.1.2604.5.1.2.5.1' }, # sfosMemoryCapacity - MB
            memory_used_prct => { oid => '.1.3.6.1.4.1.2604.5.1.2.5.2' }, # sfosMemoryPercentUsage
            swap_total       => { oid => '.1.3.6.1.4.1.2604.5.1.2.5.3' }, # sfosSwapCapacity - MB
            swap_used_prct   => { oid => '.1.3.6.1.4.1.2604.5.1.2.5.4' }  # sfosSwapPercentUsage
        }
    };

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%{$mapping->{v17}}), values(%{$mapping->{v18}})) ],
        nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping->{v17}, results => $snmp_result, instance => 0);
    $self->add_counters(result => $result);
    $result = $options{snmp}->map_instance(mapping => $mapping->{v18}, results => $snmp_result, instance => 0);
    $self->add_counters(result => $result);
}

1;

__END__

=head1 MODE

Check memory usages.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example : --filter-counters='^physical-usage$'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'physical-usage' (%), 'swap-usage' (%).

=back

=cut
