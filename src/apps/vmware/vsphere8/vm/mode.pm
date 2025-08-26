#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::vmware::vsphere8::vm::mode;
use strict;
use warnings;

use base qw(centreon::plugins::templates::counter);

sub new {
    my ($class, %options) = @_;
    my $self              = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);

    $options{options}->add_options(
        arguments => {
            'vm-id:s'          => { name => 'vm_id' },
            'vm-name:s'        => { name => 'vm_name' }
        }
    );
    $options{options}->add_help(package => __PACKAGE__, sections => 'VMWARE 8 VM OPTIONS', once => 1);

    return $self;
}

sub get_vm_id_from_name {
    my ($self, %options) = @_;

    if ( centreon::plugins::misc::is_empty($self->{vm_name}) ) {
        $self->{output}->add_option_msg(short_msg => "get_vm_id_from_name method called without vm_name option. Please check configuration.");
        $self->{output}->option_exit();
    }

    my $response = $options{custom}->request_api(
        'endpoint' => '/vcenter/vm',
        'method' => 'GET'
    );

    for my $rsrc (@$response) {
        next if ($rsrc->{name} ne $self->{vm_name});
        $self->{vm_id} = $rsrc->{vm};
        $self->{output}->add_option_msg(long_msg => "get_vm_id_from_name method called to get " . $self->{vm_name}
            . "'s id: " . $self->{vm_id} . ". Prefer using --vm-id to spare a query to the API.");
        return $rsrc->{vm};
    }

    return undef;

}

sub get_vm_stats {
    my ($self, %options) = @_;

    if ( centreon::plugins::misc::is_empty($options{vm_id}) && !$self->get_vm_id_from_name(%options) ) {
        $self->{output}->add_option_msg(short_msg => "get_vm_stats method cannot get vm ID from vm name");
        $self->{output}->option_exit();
    }

    return $options{custom}->get_stats(
        %options,
        rsrc_id   => $self->{vm_id}
    );
}

sub request_api {
    my ($self, %options) = @_;

    return $options{custom}->request_api(%options);
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

    if (centreon::plugins::misc::is_empty($self->{option_results}->{vm_id})
        && centreon::plugins::misc::is_empty($self->{option_results}->{vm_name})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify either --vm-id or --vm-name option.');
        $self->{output}->option_exit();
    }

    $self->{vm_id}   = $self->{option_results}->{vm_id};
    $self->{vm_name} = $self->{option_results}->{vm_name};

}

1;

__END__

=head1 VMWARE 8 VM OPTIONS

=over 4

=item B<--vm-id>

Define which physical server to monitor based on its resource ID (example: C<vm-16>).

=item B<--vm-name>

Define which physical server to monitor based on its name (example: C<WEBSERVER01>).
When possible, it is recommended to use C<--vm-id> instead.

=back

=cut

=head1 NAME

apps::vmware::vsphere8::vm::mode - Template for modes monitoring VMware virtual machine

=head1 SYNOPSIS

    use base apps::vmware::vsphere8::vm::mode;

    sub set_counters {...}
    sub manage_selection {
        my ($self, %options) = @_;



    $api->set_options(option_results => $option_results);
    $api->check_options();
    my $response = $api->request_api(endpoint => '/vcenter/vm');
    my $vm_cpu_capacity = $self->get_vm_stats(
                                cid     => 'cpu.capacity.provisioned.VM',
                                rsrc_id => 'vm-18');

=head1 DESCRIPTION

This module provides methods to interact with the VMware vSphere 8 REST API. It handles authentication, caching, and API requests.

=head1 METHODS

=head2 get_vm_stats

    $self->get_vm_stats(%options);

Retrieves the VM statistics for the given options using package apps::vmware::vsphere8::custom::api::get_stats()

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<cid> - The C<cid> (counter id) of the desired metric.

=item * C<vm_id> - The VM's C<rsrc_id> (resource ID) for which to retrieve the statistics. This option is optional if C<vm_name> is provided.

=item * C<vm_name> - The VM's name for which to retrieve the statistics. This option is not used if C<vm_id> is provided, which is the nominal usage of this function.

=back

=back

Returns the statistics for the specified VM.

=cut

