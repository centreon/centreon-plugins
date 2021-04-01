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

package database::sap::hana::mode::hostcpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All cpu usages are ok' },
    ];
    $self->{maps_counters}->{cpu} = [
        { label => 'user', nlabel => 'host.cpu.user.utilization.percentage', set => {
                key_values => [ { name => 'total', diff => 1 }, { name => 'user', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_data_calc'), closure_custom_calc_extra_options => { label_ref => 'user' },
                output_template => 'User %.2f %%', output_use => 'user_prct', threshold_use => 'user_prct',
                perfdatas => [
                    { label => 'user', value => 'user_prct', template => '%.2f', min => 0, max => 100, unit => '%',
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'sys', nlabel => 'host.cpu.system.utilization.percentage', set => {
                key_values => [ { name => 'total', diff => 1 }, { name => 'sys', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_data_calc'), closure_custom_calc_extra_options => { label_ref => 'sys' },
                output_template => 'System %.2f %%', output_use => 'sys_prct', threshold_use => 'sys_prct',
                perfdatas => [
                    { label => 'sys', value => 'sys_prct', template => '%.2f', min => 0, max => 100, unit => '%',
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'wait', nlabel => 'host.cpu.wait.utilization.percentage', set => {
                key_values => [ { name => 'total', diff => 1 }, { name => 'wait', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_data_calc'), closure_custom_calc_extra_options => { label_ref => 'wait' },
                output_template => 'Wait %.2f %%', output_use => 'wait_prct', threshold_use => 'wait_prct',
                perfdatas => [
                    { label => 'wait', value => 'wait_prct', template => '%.2f', min => 0, max => 100, unit => '%',
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'idle', nlabel => 'host.cpu.idle.utilization.percentage', set => {
                key_values => [ { name => 'total', diff => 1 }, { name => 'idle', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_data_calc'), closure_custom_calc_extra_options => { label_ref => 'idle' },
                output_template => 'Idle %.2f %%', output_use => 'idle_prct', threshold_use => 'idle_prct',
                perfdatas => [
                    { label => 'idle', value => 'idle_prct', template => '%.2f', min => 0, max => 100, unit => '%',
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub custom_data_calc {
    my ($self, %options) = @_;

    my $label = $options{extra_options}->{label_ref};
    my $delta_value = $options{new_datas}->{$self->{instance} . '_' . $label} - $options{old_datas}->{$self->{instance} . '_' . $label};
    my $delta_total = $options{new_datas}->{$self->{instance} . '_total'} - $options{old_datas}->{$self->{instance} . '_total'};

    $self->{result_values}->{$label . '_prct'} = 0;
    if ($delta_total > 0) {
        $self->{result_values}->{$label . '_prct'} = $delta_value * 100 / $delta_total;
    }
    return 0;
}

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{display} . "' Usage : ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});
                                
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    $options{sql}->connect();

    my $query = q{
        SELECT * FROM SYS.M_HOST_RESOURCE_UTILIZATION
    };
    $options{sql}->query(query => $query);

    $self->{cache_name} = "sap_hana_db_" . $self->{mode} . '_' . $options{sql}->get_unique_id4save() . '_' .  
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    
    $self->{cpu} = {};
    while ((my $row = $options{sql}->fetchrow_hashref())) {
        my $name = $row->{HOST};
        
        $self->{cpu}->{$name} = {
            display => $name,
            total => $row->{TOTAL_CPU_SYSTEM_TIME} + $row->{TOTAL_CPU_USER_TIME} + $row->{TOTAL_CPU_IDLE_TIME} + $row->{TOTAL_CPU_WIO_TIME},
            sys => $row->{TOTAL_CPU_SYSTEM_TIME},
            user => $row->{TOTAL_CPU_USER_TIME},
            idle => $row->{TOTAL_CPU_IDLE_TIME},
            wait => $row->{TOTAL_CPU_WIO_TIME},
        };
    }
}
    
1;

__END__

=head1 MODE

Check system CPUs.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example : --filter-counters='^idle$'

=item B<--warning-*>

Threshold warning.
Can be: 'user', 'sys', 'idle', 'wait'.

=item B<--critical-*>

Threshold critical.
Can be: 'user', 'sys', 'idle', 'wait'.

=back

=cut