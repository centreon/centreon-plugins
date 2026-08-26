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
package apps::virtualization::vates::vm::mode::vmstatus;
use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::misc qw/is_excluded is_empty/;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, force_new_perfdata => 1, %options);

    $options{options}->add_options(
        arguments => {
            'vm-uuid:s' => { name => 'vm_uuid', default => '' },
            'vm-name:s' => { name => 'vm_name', default => '' },
        }
    );

    return $self;
}
sub custom_power_status_output {
    my ($self, %options) = @_;

    return  "'" . $self->{result_values}->{display} . "' vm is " . $self->{result_values}->{power_state} . '. OS : ' .  $self->{result_values}->{os_version};


}
sub check_options {
    my ($self, %options) = @_;
    if (is_empty($options{option_results}->{vm_uuid}) and is_empty($options{option_results}->{vm_name})) {
                $self->{output}->option_exit(short_msg => "you must fill either --vm-uuid or --vm-name.");

    }
    $self->SUPER::check_options(%options);
}
sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'vms',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_vm_output',
            message_multiple => 'All VMs are ok'
        }
    ];
    $self->{maps_counters}->{vms} = [
             {
            label => 'status',
            type => COUNTER_TYPE_GROUP,
            critical_default => '%{power_state} =~ /^Halted|Paused/i',
            set => {
                key_values => [ { name => 'display' }, { name => 'power_state' }, { name => 'uuid' }, { name => 'os_version' } ],
                closure_custom_output          => $self->can('custom_power_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

}

sub manage_selection {
    my ($self, %options) = @_;

    # default filter use uuid, or name if not present.
    my $filter = "uuid:". $self->{option_results}->{vm_uuid};
    if (is_empty($self->{option_results}->{vm_uuid})){
        $filter = "name_label:". $self->{option_results}->{vm_name};
    }
    my $response = $options{custom}->request_api_get(
        endpoint  => "vms",
        get_param => [ "fields=name_label,power_state,uuid,os_version", "filter=" . $filter ],
    );
    if (!defined($response) or ref($response) ne "ARRAY" or scalar @$response != 1){
        $self->{output}->option_exit(short_msg => "no vm found, api did not return an array with one element. Please check --vm-uuid and --vm-name parameter or --debug.");
    }
    my $vm = $response->[0];

    if (! $vm->{os_version} or ! $vm->{os_version}->{name}){
        $vm->{os_version}->{name} = "Unknown";
    }
    $self->{vms}->{$vm->{name_label}} = {
        display     => $vm->{name_label},
        power_state => $vm->{power_state},
        uuid        => $vm->{uuid},
        os_version  => $vm->{os_version}->{name},
    };


}

1;

__END__

=head1 MODE

Check one virtual machines status on a Xen Orchestra pool (running, halted, paused, suspended).

=over 8

=item B<--vm-uuid>

include virtual machines by exact uuid.

=item B<--vm-name>

include virtual machines by name (only one machine is expected).

=item B<--warning-status>

Define the warning threshold for the power status of the VM.
The value should be a Perl expression using the %{power_state} macro.

=item B<--critical-status>

Define the critical threshold for the power status of the VM.
The value should be a Perl expression using the %{power_state} macro.
Default: '%{power_state} =~ /^Halted|Paused/i'

=back

=cut