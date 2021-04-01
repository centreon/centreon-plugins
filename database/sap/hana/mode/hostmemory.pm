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

package database::sap::hana::mode::hostmemory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => 'used', unit => 'B',
        nlabel => $self->{nlabel},
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct_used}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    
    my $msg = sprintf("Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                      $total_size_value . " " . $total_size_unit,
                      $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                      $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
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

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'memory', type => 1, cb_prefix_output => 'prefix_memory_output', message_multiple => 'All physical memories are ok' },
        { name => 'swap', type => 1, cb_prefix_output => 'prefix_swap_output', message_multiple => 'All swap memories are ok' },
    ];
    
    $self->{maps_counters}->{memory} = [
        { label => 'physical-usage', nlabel => 'host.memory.usage.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'physical' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
    $self->{maps_counters}->{swap} = [
        { label => 'swap-usage', nlabel => 'host.swap.usage.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'swap' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub prefix_memory_output {
    my ($self, %options) = @_;
    
    return "Physical memory '" . $options{instance_value}->{display} . "' ";
}

sub prefix_swap_output {
    my ($self, %options) = @_;
    
    return "Swap memory '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    $options{sql}->connect();

    my $query = q{
        SELECT * FROM SYS.M_HOST_RESOURCE_UTILIZATION
    };
    $options{sql}->query(query => $query);
    $self->{swap} = {};
    $self->{memory} = {};

    while ((my $row = $options{sql}->fetchrow_hashref())) {
        my $name = $row->{HOST};
        
        $self->{memory}->{$name} = {
            display => $name,
            free => $row->{FREE_PHYSICAL_MEMORY},
            used => $row->{USED_PHYSICAL_MEMORY},
        };
        $self->{swap}->{$name} = {
            display => $name,
            free => $row->{FREE_SWAP_SPACE},
            used => $row->{USED_SWAP_SPACE},
        };
    }    
}

1;

__END__

=head1 MODE

Check memory usages.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example : --filter-counters='^physical-usage$'

=item B<--warning-*>

Threshold warning.
Can be: 'physical-usage' (%), 'swap-usage' (%).

=item B<--critical-*>

Threshold critical.
Can be: 'physical-usage' (%), 'swap-usage' (%).

=back

=cut
