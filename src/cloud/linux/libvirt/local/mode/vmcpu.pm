#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package cloud::linux::libvirt::local::mode::vmcpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded);
use Digest::SHA qw(sha256_hex);

# cpu.time is in nanoseconds
# CPU% vs 1 physical core = delta_ns / 1e9 / delta_seconds * 100
sub custom_cpu_calc {
    my ($self, %options) = @_;

    my $delta_cpu_ns = $options{new_datas}->{$self->{instance} . '_cpu_time'}
                     - $options{old_datas}->{$self->{instance} . '_cpu_time'};

    $self->{result_values}->{cpu_prct} = ($delta_cpu_ns / 1_000_000_000) / $options{delta_time} * 100;

    my $vcpus = $options{new_datas}->{$self->{instance} . '_vcpus'} // 0;
    $self->{result_values}->{cpu_prct_alloc} = $self->{result_values}->{cpu_prct} / $vcpus
        if $vcpus;

    return RUN_OK;
}

sub custom_vcpu_calc {
    my ($self, %options) = @_;

    my $delta_cpu_ns = $options{new_datas}->{$self->{instance} . '_cpu_time'}
                     - $options{old_datas}->{$self->{instance} . '_cpu_time'};

    $self->{result_values}->{cpu_prct} = ($delta_cpu_ns / 1_000_000_000) / $options{delta_time} * 100;

    return RUN_OK;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vms', type => COUNTER_TYPE_MULTIPLE, cb_prefix_output => 'prefix_vm_output',
          cb_long_output => 'vm_long_output', indent_long_output => '    ',
          message_multiple => 'All VMs CPU usage are ok',
          group => [
              { name => 'global_cpu', cb_prefix_output => 'prefix_global_cpu_output',
                type => COUNTER_TYPE_GLOBAL,
                skipped_code => { NO_VALUE() => 1, BUFFER_CREATION() => 1 } },
              { name => 'cpu', display_long => 0, cb_prefix_output => 'prefix_cpu_output',
                message_multiple => 'All vCPUs are ok', type => COUNTER_TYPE_INSTANCE,
                skipped_code => { NO_VALUE() => 1, BUFFER_CREATION() => 1 } }
          ]
        }
    ];

    $self->{maps_counters}->{global_cpu} = [
        { label => 'cpu-utilization', nlabel => 'vm.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_time', diff => 1 }, { name => 'vcpus' } ],
                closure_custom_calc => $self->can('custom_cpu_calc'),
                output_template => 'usage: %.2f %%',
                output_use => 'cpu_prct', threshold_use => 'cpu_prct',
                perfdatas => [
                    { value => 'cpu_prct', template => '%.2f',
                      unit => '%', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'cpu-utilization-vcpu', nlabel => 'vm.cpu.utilization.vcpu.percentage', set => {
                key_values => [ { name => 'cpu_time', diff => 1 }, { name => 'vcpus' } ],
                closure_custom_calc => $self->can('custom_cpu_calc'),
                output_template => 'vCPU utilization: %.2f %%',
                output_use => 'cpu_prct_alloc', threshold_use => 'cpu_prct_alloc',
                perfdatas => [
                    { value => 'cpu_prct_alloc', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'vcpu-utilization', nlabel => 'vm.cpu.vcpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_time', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_vcpu_calc'),
                output_template => 'usage: %.2f %%',
                output_use => 'cpu_prct', threshold_use => 'cpu_prct',
                perfdatas => [
                    { value => 'cpu_prct', template => '%.2f',
                      unit => '%', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_vm_output {
    my ($self, %options) = @_;

    return "VM '" . $options{instance_value}->{display} . "' ";
}

sub vm_long_output {
    my ($self, %options) = @_;

    return "checking VM '" . $options{instance_value}->{display} . "'";
}

sub prefix_global_cpu_output {
    my ($self, %options) = @_;

    return 'cpu ';
}

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return "vCPU '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'vm-name:s'      => { name => 'vm_name',      default => '' },
        'include-name:s' => { name => 'include_name', default => '' },
        'exclude-name:s' => { name => 'exclude_name', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{output}->option_exit(short_msg => '--vm-name cannot be used together with --include-name or --exclude-name.')
        if $self->{option_results}->{vm_name} ne '' && ($self->{option_results}->{include_name} ne '' || $self->{option_results}->{exclude_name} ne '');
}

sub manage_selection {
    my ($self, %options) = @_;

    my $virsh_args = 'domstats --cpu-total --vcpu';
    $virsh_args .= $self->{option_results}->{vm_name} ne '' ? ' ' . $self->{option_results}->{vm_name} : ' --list-running';

    # virsh domstats --cpu-total --vcpu [--list-running | <vm>]
    # Domain: 'vm1'
    #   cpu.time=12345678900
    #   vcpu.current=2
    #   vcpu.0.time=6172839450
    #   vcpu.1.time=6172839450
    my $stdout = $options{custom}->execute_command(virsh_args => $virsh_args);

    $self->{vms} = {};
    my $current_vm;
    foreach (split(/\n/, $stdout)) {
        if (/^Domain:\s+'(.+?)'/) {
            $current_vm = $1;
            if (is_excluded($current_vm, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name})) {
                undef $current_vm;
                next
            }
            $self->{vms}->{$current_vm} = {
                display    => $current_vm,
                global_cpu => {},
                cpu        => {}
            };
            next
        }
        next unless $current_vm;
        $self->{vms}->{$current_vm}->{global_cpu}->{cpu_time} = $1 if /^\s*cpu\.time=(\d+)/;
        $self->{vms}->{$current_vm}->{global_cpu}->{vcpus}    = $1 if /^\s*vcpu\.current=(\d+)/;
        $self->{vms}->{$current_vm}->{cpu}->{"vcpu$1"} = { display => "vcpu$1", cpu_time => $2 }
            if /^\s*vcpu\.(\d+)\.time=(\d+)/;
    }

    $self->{output}->option_exit(short_msg => 'No running VM found.')
        unless %{$self->{vms}};

    $self->{cache_name} = 'libvirt_' . $options{custom}->get_identifier() . '_' . $self->{mode} . '_' .
        sha256_hex(
            $self->{option_results}->{vm_name} . '_' .
            $self->{option_results}->{include_name} . '_' .
            $self->{option_results}->{exclude_name}
        );
}

1;

__END__

=head1 MODE

Check virtual machines CPU usage (C<virsh domstats --cpu-total --vcpu>).

=over 8

=item B<--vm-name>

Check only this specific VM.
Cannot be used together with --include-name or --exclude-name.

=item B<--include-name>

Filter VMs by name (regexp).

=item B<--exclude-name>

Exclude VMs whose name matches this regexp.

=item B<--warning-cpu-utilization>

Warning threshold for CPU usage (% vs 1 physical CPU).

=item B<--critical-cpu-utilization>

Critical threshold for CPU usage (% vs 1 physical CPU).

=item B<--warning-cpu-utilization-vcpu>

Warning threshold for CPU usage relative to allocated vCPUs (%).

=item B<--critical-cpu-utilization-vcpu>

Critical threshold for CPU usage relative to allocated vCPUs (%).

=item B<--warning-vcpu-utilization>

Warning threshold for per-vCPU usage (% vs 1 physical CPU).

=item B<--critical-vcpu-utilization>

Critical threshold for per-vCPU usage (% vs 1 physical CPU).

=back

=cut
