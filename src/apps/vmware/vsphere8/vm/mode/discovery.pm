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

package apps::vmware::vsphere8::vm::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'prettify'              => { name => 'prettify' },
        'no-identity'           => { name => 'no_identity' },
        'filter-power-states:s' => { name => 'filter_power_states' },
        'filter-folders:s'      => { name => 'filter_folders' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    my $disco_stats;
    $disco_stats->{start_time} = time();

    my @params;
    if (!centreon::plugins::misc::is_empty($self->{option_results}->{filter_power_states})) {
        push @params, 'power_states=' . $self->{option_results}->{filter_power_states};
    }

    if (!centreon::plugins::misc::is_empty($self->{option_results}->{filter_folders})) {
        my $folder_ids = $options{custom}->get_folder_ids_by_names('names' => $self->{option_results}->{filter_folders});
        push @params, 'folders=' . $folder_ids;
    }

    my $url_params = '';
    $url_params = '?' . join('&', @params) if (@params > 0);
    # Retrieve the data
    my $response = $options{custom}->request_api('endpoint' => '/vcenter/vm' . $url_params, 'method' => 'GET');

    # Format the data for vm discovery
    my @results = map {
        'vm_name' => $_->{name},
        'vmw_vm_id' => $_->{vm},
        'power_state' => $_->{power_state},
    }, @{$response};

    foreach my $vm (@results) {
        # if the VM is POWERED_ON and if the tools are available, the vcenter can provide system information
        # we skip this if the --no-identity option has been used
        my $identity = $options{custom}->get_vm_guest_identity(vm_id => $vm->{vmw_vm_id}) if ($vm->{power_state} eq 'POWERED_ON' && !$self->{option_results}->{no_identity});
        # The GuestOSFamily enumerated type defines the valid guest operating system family types reported by a virtual machine.
        # WINDOWS : Windows operating system
        # LINUX : Linux operating system
        # NETWARE : Novell Netware
        # SOLARIS : Solaris operating system
        # DARWIN : Mac OS operating system
        # OTHER : Other operating systems
        $vm->{family}        = $identity->{family} // '';
        # The GuestOS enumerated type defines the valid guest operating system types used for configuring a virtual machine.
        # for full list, see https://developer.broadcom.com/xapis/vsphere-automation-api/8.0.3/vcenter/api/vcenter/vm/vm/guest/identity/get/
        $vm->{guest_os}      = $identity->{name} // '';
        $vm->{ip_address}    = $identity->{ip_address} // '';
        $vm->{guest_os_full} = $identity->{full_name}->{default_message} // '';
    }
    # Record the metadata
    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{results}  = \@results;
    $disco_stats->{discovered_items} = scalar(@results);

    my $encoded_data;
    eval {
        if (defined($self->{option_results}->{prettify})) {
            $encoded_data = JSON::XS->new->utf8->canonical(1)->pretty->encode($disco_stats);
        } else {
            $encoded_data = JSON::XS->new->utf8->canonical(1)->encode($disco_stats);
        }
    };
    if ($@) {
        $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}';
    }

    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
}

1;

__END__

=head1 MODE

Discover VMware8 virtual machines.

=over 8

=item B<--filter-folders>

Display only virtual machines hold in one of the provided folders (separated by commas).
The strings must be equal (case sensitive).

Example: C<--filter-folders=REDIS_SERVERS>

=item B<--filter-power-states>

Display only virtual machines having power state equal to one of the provided states (separated by commas).
Supported values:

    - POWERED_OFF: The virtual machine is powered off.
    - POWERED_ON: The virtual machine is powered on.
    - SUSPENDED: The virtual machine is suspended.

=item B<--no-identity>

Collecting identity information for all VMs can take a very long time.
If you want to speed up the discovery you can narrow the scope by using C<--filter-power-states> and/or
C<--filter-folders> or, if you only need the VMs names and power states, you may use this option to avoid collecting the
following information: Guest OS, Guest OS family, IP address.

=item B<--prettify>

Prettify JSON output.

=back

=cut
