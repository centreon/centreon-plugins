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

package storage::emc::isilon::snmp::mode::clustercpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_cpu_calc {
    my ($self, %options) = @_;

    return -10 if (!defined($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}}));
    $self->{result_values}->{prct_used} = 
        ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}}) / 10;
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_cpu_output', skipped_code => { -10 => 1 } },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'user', nlabel => 'cpu.user.utilization.percentage', set => {
                key_values => [],
                closure_custom_calc => $self->can('custom_cpu_calc'), closure_custom_calc_extra_options => { label_ref => 'clusterCPUUser' },
                manual_keys => 1,
                threshold_use => 'prct_used', output_use => 'prct_used',
                output_template => 'User %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0 , max => 100, unit => '%' },
                ],
            }
        },
        { label => 'nice', nlabel => 'cpu.nice.utilization.percentage', set => {
                key_values => [],
                closure_custom_calc => $self->can('custom_cpu_calc'), closure_custom_calc_extra_options => { label_ref => 'clusterCPUNice' },
                manual_keys => 1,
                threshold_use => 'prct_used', output_use => 'prct_used',
                output_template => 'Nice %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0 , max => 100, unit => '%' },
                ],
            }
        },
        { label => 'system', nlabel => 'cpu.system.utilization.percentage', set => {
                key_values => [],
                closure_custom_calc => $self->can('custom_cpu_calc'), closure_custom_calc_extra_options => { label_ref => 'clusterCPUSystem' },
                manual_keys => 1,
                threshold_use => 'prct_used', output_use => 'prct_used',
                output_template => 'System %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0 , max => 100, unit => '%' },
                ],
            }
        },
        { label => 'idle', nlabel => 'cpu.idle.utilization.percentage', set => {
                key_values => [],
                closure_custom_calc => $self->can('custom_cpu_calc'), closure_custom_calc_extra_options => { label_ref => 'clusterCPUIdlePct' },
                manual_keys => 1,
                threshold_use => 'prct_used', output_use => 'prct_used',
                output_template => 'Idle %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0 , max => 100, unit => '%' },
                ],
            }
        },
        { label => 'interrupt', nlabel => 'cpu.interrupt.utilization.percentage', set => {
                key_values => [],
                closure_custom_calc => $self->can('custom_cpu_calc'), closure_custom_calc_extra_options => { label_ref => 'clusterCPUInterrupt' },
                manual_keys => 1,
                threshold_use => 'prct_used', output_use => 'prct_used',
                output_template => 'Interrupt %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0 , max => 100, unit => '%' },
                ],
            }
        },
    ];
}

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return 'CPU Usage: ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $mapping = {
    clusterCPUUser      => { oid => '.1.3.6.1.4.1.12124.1.2.3.1' },
    clusterCPUNice      => { oid => '.1.3.6.1.4.1.12124.1.2.3.2' },
    clusterCPUSystem    => { oid => '.1.3.6.1.4.1.12124.1.2.3.3' },
    clusterCPUInterrupt => { oid => '.1.3.6.1.4.1.12124.1.2.3.4' },
    clusterCPUIdlePct   => { oid => '.1.3.6.1.4.1.12124.1.2.3.5' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_clusterCPUPerf = '.1.3.6.1.4.1.12124.1.2.3';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_clusterCPUPerf,
        nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');

    $self->{global} = { %$result };
}

1;

__END__

=head1 MODE

Check cluster CPU usage (User, Nice, System, Idle, Interrupt).

=over 8

=item B<--warning-*>

Warning threshold in percent.
Can be: 'user', 'nice', 'system', 'idle', 'interrupt'.

=item B<--critical-*>

Critical threshold in percent.
Can be: 'user', 'nice', 'system', 'idle', 'interrupt'.

=back

=cut
