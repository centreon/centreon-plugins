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

package apps::vmware::connector::mode::limitvm;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_limit_output {
    my ($self, %options) = @_;
    
    my $msg;
    if ($self->{result_values}->{limit} != -1) {
        $msg = sprintf("%s limit set", $self->{result_values}->{label});
    } else {
        $msg = sprintf("no %s limit set", $self->{result_values}->{label});
    }

    return $msg;
}

sub custom_limit_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{limit} = $options{new_datas}->{$self->{instance} . '_'. $options{extra_options}->{label_ref} . '_limit'};
    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{connection_state} = $options{new_datas}->{$self->{instance} . '_connection_state'};
    $self->{result_values}->{power_state} = $options{new_datas}->{$self->{instance} . '_power_state'};
    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu_alarms', type => 2, cb_long_output => 'cpu_long_output', message_multiple => '0 cpu limit problem(s) detected', format_output => '%s cpu limit problem(s) detected', display_counter_problem => { label => 'cpu_alerts', nlabel => 'vm.limit.cpu.alerts.count', min => 0 },
          group => [ { name => 'cpu_alarm', cb_prefix_output => 'prefix_vm_output', skipped_code => { -11 => 1 } } ] 
        },
        { name => 'memory_alarms', type => 2,cb_long_output => 'memory_long_output',  message_multiple => '0 memory limit problem(s) detected', format_output => '%s memory limit problem(s) detected', display_counter_problem => { label => 'memory_alerts', nlabel => 'vm.limit.memory.alerts.count', min => 0 },
          group => [ { name => 'memory_alarm', cb_prefix_output => 'prefix_vm_output', skipped_code => { -11 => 1 } } ] 
        },
        { name => 'disk_alarms', type => 2, cb_long_output => 'disk_long_output', message_multiple => '0 disk limit problem(s) detected', format_output => '%s disk limit problem(s) detected', display_counter_problem => { label => 'disk_alerts', nlabel => 'vm.limit.disk.alerts.count', min => 0 },
          group => [ { name => 'disk_alarm', cb_prefix_output => 'prefix_vm_output', skipped_code => { -11 => 1 } } ] 
        }
    ];
    
    $self->{maps_counters}->{cpu_alarm} = [
        {
            label => 'cpu-status', type => 2, critical_default => '%{connection_state} !~ /^connected$/i || %{limit} != -1',
            set => {
                key_values => [ { name => 'name' }, { name => 'connection_state' }, { name => 'power_state' }, { name => 'cpu_limit' } ],
                closure_custom_calc => $self->can('custom_limit_calc'), closure_custom_calc_extra_options => { label_ref => 'cpu' },
                closure_custom_output => $self->can('custom_limit_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{memory_alarm} = [
        {
            label => 'memory-status', type => 2, critical_default => '%{connection_state} !~ /^connected$/i || %{limit} != -1',
            set => {
                key_values => [ { name => 'name' }, { name => 'connection_state' }, { name => 'power_state' }, { name => 'memory_limit' } ],
                closure_custom_calc => $self->can('custom_limit_calc'), closure_custom_calc_extra_options => { label_ref => 'memory' },
                closure_custom_output => $self->can('custom_limit_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{disk_alarm} = [
        {
            label => 'disk-status', type => 2, critical_default => '%{connection_state} !~ /^connected$/i || %{limit} != -1',
            set => {
                key_values => [ { name => 'name' }, { name => 'connection_state' }, { name => 'power_state' }, { name => 'disk_limit' } ],
                closure_custom_calc => $self->can('custom_limit_calc'), closure_custom_calc_extra_options => { label_ref => 'disk' },
                closure_custom_output => $self->can('custom_limit_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub cpu_long_output {
    my ($self, %options) = @_;

    return "checking cpu limit";
}

sub memory_long_output {
    my ($self, %options) = @_;

    return "checking memory limit";
}

sub disk_long_output {
    my ($self, %options) = @_;

    return "checking disk limit";
}

sub prefix_vm_output {
    my ($self, %options) = @_;

    my $msg = "Virtual machine '" . $options{instance_value}->{name} . "'";
    if (defined($options{instance_value}->{config_annotation})) {
        $msg .= ' [annotation: ' . $options{instance_value}->{config_annotation} . ']';
    }
    $msg .= ' : ';
    
    return $msg;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'vm-hostname:s'        => { name => 'vm_hostname' },
        'filter'               => { name => 'filter' },
        'filter-description:s' => { name => 'filter_description' },
        'filter-os:s'          => { name => 'filter_os' },
        'filter-uuid:s'        => { name => 'filter_uuid' },
        'display-description'  => { name => 'display_description' },
        'check-disk-limit'     => { name => 'check_disk_limit' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'limitvm'
    );

    my $i = 0;
    $self->{cpu_alarms}->{global} = { cpu_alarm => {} };
    $self->{memory_alarms}->{global} = { memory_alarm => {} };
    $self->{disk_alarms}->{global} = { disk_alarm => {} } if (defined($self->{option_results}->{check_disk_limit}));
    foreach my $vm_id (keys %{$response->{data}}) {
        my $vm_name = $response->{data}->{$vm_id}->{name};

        $self->{cpu_alarms}->{global}->{cpu_alarm}->{$i} = {
            name => $vm_name,
            config_annotation => defined($self->{option_results}->{display_description}) ? $options{custom}->strip_cr(value => $response->{data}->{$vm_id}->{'config.annotation'}) : undef,
            connection_state => $response->{data}->{$vm_id}->{connection_state},
            power_state => $response->{data}->{$vm_id}->{power_state},
            cpu_limit => $response->{data}->{$vm_id}->{'config.cpuAllocation.limit'},
        };
        $self->{memory_alarms}->{global}->{memory_alarm}->{$i} = {
            name => $vm_name,
            config_annotation => defined($self->{option_results}->{display_description}) ? $options{custom}->strip_cr(value => $response->{data}->{$vm_id}->{'config.annotation'}) : undef,
            connection_state => $response->{data}->{$vm_id}->{connection_state},
            power_state => $response->{data}->{$vm_id}->{power_state},
            memory_limit => $response->{data}->{$vm_id}->{'config.memoryAllocation.limit'}
        };

        if (defined($self->{option_results}->{check_disk_limit})) {
            $self->{disk_alarms}->{global}->{disk_alarm}->{$i} = {
                name => $vm_name,
                config_annotation => defined($self->{option_results}->{display_description}) ? $options{custom}->strip_cr(value => $response->{data}->{$vm_id}->{'config.annotation'}) : undef,
                connection_state => $response->{data}->{$vm_id}->{connection_state},
                power_state => $response->{data}->{$vm_id}->{power_state},
                disk_limit => -1
            };

            foreach (@{$response->{data}->{$vm_id}->{'config.storageIOAllocation.limit'}}) {
                if ($_->{limit} != -1) {
                    $self->{disk_alarms}->{global}->{disk_alarm}->{$i}->{disk_limit} = 1;
                }
            }
        }

        $i++;
    }
}

1;

__END__

=head1 MODE

Check virtual machine limits.

=over 8

=item B<--vm-hostname>

VM hostname to check.
If not set, we check all VMs.

=item B<--filter>

VM hostname is a regexp.

=item B<--filter-description>

Filter also virtual machines description (can be a regexp).

=item B<--filter-os>

Filter also virtual machines OS name (can be a regexp).

=item B<--display-description>

Display virtual machine description.

=item B<--check-disk-limit>

Check disk limits (since vsphere 5.0).

=item B<--warning-disk-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{connection_state}, %{power_state}, %{limit}

=item B<--critical-disk-status>

Set critical threshold for status (Default: '%{connection_state} !~ /^connected$/i || %{limit} != -1').
Can used special variables like: %{connection_state}, %{power_state}, %{limit}

=item B<--warning-cpu-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{connection_state}, %{power_state}, %{limit}

=item B<--critical-cpu-status>

Set critical threshold for status (Default: '%{connection_state} !~ /^connected$/i || %{limit} != -1').
Can used special variables like: %{connection_state}, %{power_state}, %{limit}

=item B<--warning-memory-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{connection_state}, %{power_state}, %{limit}

=item B<--critical-memory-status>

Set critical threshold for status (Default: '%{connection_state} !~ /^connected$/i || %{limit} != -1').
Can used special variables like: %{connection_state}, %{power_state}, %{limit}

=back

=cut
