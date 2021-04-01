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

package snmp_standard::mode::cpudetailed;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_cpu_calc {
    my ($self, %options) = @_;

    return -10 if (!defined($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}}));
    if (!defined($options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}})) {
        $self->{error_msg} = "Buffer creation";
        return -1;
    }

    if (!defined($self->{instance_mode}->{total_cpu})) {
        $self->{instance_mode}->{total_cpu} = 0;        
        foreach (keys %{$options{new_datas}}) {
            if (/$self->{instance}_/) {
                my $new_total = $options{new_datas}->{$_};
                next if (!defined($options{old_datas}->{$_}));
                my $old_total = $options{old_datas}->{$_};

                my $diff_total = $new_total - $old_total;
                if ($diff_total < 0) {
                    $self->{instance_mode}->{total_cpu} += $old_total;
                } else {
                    $self->{instance_mode}->{total_cpu} += $diff_total;
                }
            }
        }
    }

    if ($self->{instance_mode}->{total_cpu} <= 0) {
        $self->{error_msg} = "counter not moved";
        return -12;
    }
    
    if ($options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}} > $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}}) {
        $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}} = 0;
    }
    $self->{result_values}->{prct_used} = 
        ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}} - 
         $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}}) * 100 /
        $self->{instance_mode}->{total_cpu};
    
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
                closure_custom_calc => $self->can('custom_cpu_calc'), closure_custom_calc_extra_options => { label_ref => 'ssCpuRawUser' },
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
                closure_custom_calc => $self->can('custom_cpu_calc'), closure_custom_calc_extra_options => { label_ref => 'ssCpuRawNice' },
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
                closure_custom_calc => $self->can('custom_cpu_calc'), closure_custom_calc_extra_options => { label_ref => 'ssCpuRawSystem' },
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
                closure_custom_calc => $self->can('custom_cpu_calc'), closure_custom_calc_extra_options => { label_ref => 'ssCpuRawIdle' },
                manual_keys => 1, 
                threshold_use => 'prct_used', output_use => 'prct_used',
                output_template => 'Idle %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0 , max => 100, unit => '%' },
                ],
            }
        },
        { label => 'wait', nlabel => 'cpu.wait.utilization.percentage', set => {
                key_values => [],
                closure_custom_calc => $self->can('custom_cpu_calc'), closure_custom_calc_extra_options => { label_ref => 'ssCpuRawWait' },
                manual_keys => 1, 
                threshold_use => 'prct_used', output_use => 'prct_used',
                output_template => 'Wait %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0 , max => 100, unit => '%' },
                ],
            }
        },
        { label => 'kernel', nlabel => 'cpu.kernel.utilization.percentage', set => {
                key_values => [],
                closure_custom_calc => $self->can('custom_cpu_calc'), closure_custom_calc_extra_options => { label_ref => 'ssCpuRawKernel' },
                manual_keys => 1, 
                threshold_use => 'prct_used', output_use => 'prct_used',
                output_template => 'Kernel %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0 , max => 100, unit => '%' },
                ],
            }
        },
        { label => 'interrupt', nlabel => 'cpu.interrupt.utilization.percentage', set => {
                key_values => [],
                closure_custom_calc => $self->can('custom_cpu_calc'), closure_custom_calc_extra_options => { label_ref => 'ssCpuRawInterrupt' },
                manual_keys => 1, 
                threshold_use => 'prct_used', output_use => 'prct_used',
                output_template => 'Interrupt %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0 , max => 100, unit => '%' },
                ],
            }
        },
        { label => 'softirq', nlabel => 'cpu.softirq.utilization.percentage', set => {
                key_values => [],
                closure_custom_calc => $self->can('custom_cpu_calc'), closure_custom_calc_extra_options => { label_ref => 'ssCpuRawSoftIRQ' },
                manual_keys => 1, 
                threshold_use => 'prct_used', output_use => 'prct_used',
                output_template => 'Soft Irq %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0 , max => 100, unit => '%' },
                ],
            }
        },
        { label => 'steal', nlabel => 'cpu.steal.utilization.percentage', set => {
                key_values => [],
                closure_custom_calc => $self->can('custom_cpu_calc'), closure_custom_calc_extra_options => { label_ref => 'ssCpuRawSteal' },
                manual_keys => 1, 
                threshold_use => 'prct_used', output_use => 'prct_used',
                output_template => 'Steal %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0 , max => 100, unit => '%' },
                ],
            }
        },
        { label => 'guest', nlabel => 'cpu.guest.utilization.percentage', set => {
                key_values => [],
                closure_custom_calc => $self->can('custom_cpu_calc'), closure_custom_calc_extra_options => { label_ref => 'ssCpuRawGuest' },
                manual_keys => 1, 
                threshold_use => 'prct_used', output_use => 'prct_used',
                output_template => 'Guest %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0 , max => 100, unit => '%' },
                ],
            }
        },
        { label => 'guestnice', nlabel => 'cpu.guestnice.utilization.percentage', set => {
                key_values => [],
                closure_custom_calc => $self->can('custom_cpu_calc'), closure_custom_calc_extra_options => { label_ref => 'ssCpuRawGuestNice' },
                manual_keys => 1, 
                threshold_use => 'prct_used', output_use => 'prct_used',
                output_template => 'Guest Nice %.2f %%',
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $mapping = {
    ssCpuRawUser    => { oid => '.1.3.6.1.4.1.2021.11.50' },
    ssCpuRawNice    => { oid => '.1.3.6.1.4.1.2021.11.51' },
    ssCpuRawSystem  => { oid => '.1.3.6.1.4.1.2021.11.52' },
    ssCpuRawIdle    => { oid => '.1.3.6.1.4.1.2021.11.53' },
    ssCpuRawWait    => { oid => '.1.3.6.1.4.1.2021.11.54' },
    ssCpuRawKernel  => { oid => '.1.3.6.1.4.1.2021.11.55' },
    ssCpuRawInterrupt   => { oid => '.1.3.6.1.4.1.2021.11.56' },
    ssCpuRawSoftIRQ     => { oid => '.1.3.6.1.4.1.2021.11.61' },
    ssCpuRawSteal       => { oid => '.1.3.6.1.4.1.2021.11.64' },
    ssCpuRawGuest       => { oid => '.1.3.6.1.4.1.2021.11.65' },
    ssCpuRawGuestNice   => { oid => '.1.3.6.1.4.1.2021.11.66' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_systemStats = '.1.3.6.1.4.1.2021.11';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_systemStats,
        start => $mapping->{ssCpuRawUser}->{oid},
        nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');

    $self->{cache_name} = "snmpstandard_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    $self->{global} = { %$result };
}

1;

__END__

=head1 MODE

Check system CPUs (UCD-SNMP-MIB) (User, Nice, System, Idle, Wait, Kernel, Interrupt, SoftIRQ, Steal, Guest, GuestNice)
An average of all CPUs.

=over 8

=item B<--warning-*>

Threshold warning in percent.
Can be: 'user', 'nice', 'system', 'idle', 'wait', 'kernel', 'interrupt', 'softirq', 'steal', 'guest', 'guestnice'.

=item B<--critical-*>

Threshold critical in percent.
Can be: 'user', 'nice', 'system', 'idle', 'wait', 'kernel', 'interrupt', 'softirq', 'steal', 'guest', 'guestnice'.

=back

=cut
