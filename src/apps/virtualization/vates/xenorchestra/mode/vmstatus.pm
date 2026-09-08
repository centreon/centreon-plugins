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
package apps::virtualization::vates::xenorchestra::mode::vmstatus;
use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::misc qw/is_excluded/;
use centreon::plugins::constants qw(:counters :values);

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, force_new_perfdata => 1, %options);

    $options{options}->add_options(
        arguments => {
            'include-vm-name:s' => { name => 'include_vm_name' },
            'exclude-vm-name:s' => { name => 'exclude_vm_name' },
            'include-vm-uuid:s' => { name => 'include_vm_uuid' },
            'exclude-vm-uuid:s' => { name => 'exclude_vm_uuid' },
        }
    );

    return $self;
}

sub set_counters {
    my ($self, %options) = @_;


    $self->{maps_counters_type} = [
        {
            name             => 'vms',
            type             => COUNTER_TYPE_GLOBAL,
            skipped_code => { NO_VALUE => 1 }
        }
    ];
    $self->{maps_counters}->{vms} = [
        { label => 'running', nlabel => 'vms.running.count', set => {
            key_values      => [ { name => 'Running' },{ name => 'total' } ],
            output_template => '%s VM(s) running',
            perfdatas       => [
                { label => 'running', template => '%s', min => 0, max => 'total' }
            ]}
        },
        { label => 'halted', nlabel => 'vms.halted.count', set => {
            key_values      => [ { name => 'Halted' },{ name => 'total' } ],
            output_template => '%s VM(s) halted',
            perfdatas       => [
                { label => 'halted', template => '%s', min => 0, max => 'total' }
            ]}
        },
        { label => 'paused', nlabel => 'vms.paused.count', set => {
            key_values      => [ { name => 'Paused' },{ name => 'total' } ],
            output_template => '%s VM(s) paused',
            perfdatas       => [
                { label => 'paused', template => '%s', min => 0, max => 'total' }
            ]}
        },
        { label => 'suspended', nlabel => 'vms.suspended.count', set => {
            key_values      => [ { name => 'Suspended' },{ name => 'total' } ],
            output_template => '%s VM(s) suspended',
            perfdatas       => [
                { label => 'suspended', template => '%s', min => 0, max => 'total' }
            ]}
        },
        { label => 'total', nlabel => 'vms.total.count', set => {
            key_values      => [ { name => 'total' } ],
            output_template => '%s VM(s) total',
            perfdatas       => [
                { label => 'total', template => '%s', min => 0, max => 'total' }
            ]}
        },
    ];

}

sub manage_selection {
    my ($self, %options) = @_;
    # adding "$pool" in "fields" parameter allow to find the server id, useful for a potential v2 to display count peer host
    my $response = $options{custom}->request_api_get(endpoint => "vms", get_param => ["fields=name_label,power_state,uuid"]);
    my $exit_unknown = 0;
    $self->{vms} = {
        Running => 0,
        Halted => 0,
        Paused => 0,
        Suspended => 0,
        total => 0,
    };

    for my $vm (@$response){
        if (is_excluded($vm->{name_label}, $self->{option_results}->{include_vm_name}, $self->{option_results}->{exclude_vm_name}, output => $self->{output})) {
            next
        }
        if (is_excluded($vm->{name_label}, $self->{option_results}->{include_vm_uuid}, $self->{option_results}->{exclude_vm_uuid}, output => $self->{output})) {
            next
        }
        $self->{vms}->{total}++;

        if (!defined($self->{vms}->{$vm->{power_state}})){
            $self->{output}->add_option_msg(short_msg => "unknown power_state : $vm->{power_state} for vm $vm->{name_label}/$vm->{uuid}");
            $exit_unknown = 1;
            next;
        }
        $self->{vms}->{$vm->{power_state}}++;

    }
    if ($self->{vms}->{total} == 0){
        $self->{output}->option_exit(short_msg => "no vm found, check include and exclude filters.");
    }
    if ($exit_unknown == 1 ){
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check virtual machines status on a Xen Orchestra pool (running, halted, paused, suspended).

=over 8

=item B<--include-vm-name>

Filter virtual machines by name (can be a regexp). Only matching VMs are checked.

=item B<--exclude-vm-name>

Exclude virtual machines by name (can be a regexp).

=item B<--include-vm-uuid>

Filter virtual machines by uuid (can be a regexp). Only matching VMs are checked.

=item B<--exclude-vm-uuid>

Exclude virtual machines by uuid (can be a regexp).

=item B<--warning-running>

Threshold warning for the number of running VMs.

=item B<--critical-running>

Threshold critical for the number of running VMs.

=item B<--warning-halted>

Threshold warning for the number of halted VMs.

=item B<--critical-halted>

Threshold critical for the number of halted VMs.

=item B<--warning-paused>

Threshold warning for the number of paused VMs.

=item B<--critical-paused>

Threshold critical for the number of paused VMs.

=item B<--warning-suspended>

Threshold warning for the number of suspended VMs.

=item B<--critical-suspended>

Threshold critical for the number of suspended VMs.

=item B<--warning-total>

Threshold warning for the total number of VMs.

=item B<--critical-total>

Threshold critical for the total number of VMs.

=back

=cut