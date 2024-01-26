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

package cloud::outscale::mode::vms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_vm_output {
    my ($self, %options) = @_;

    return sprintf(
        "virtual machine '%s' ",
        $options{instance_value}->{vmName}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'number of virtual machines ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'vms', type => 1, cb_prefix_output => 'prefix_vm_output', message_multiple => 'All virtual machines are ok' }
    ];

    $self->{maps_counters}->{global} = [];
    foreach ('detected', 'pending', 'running', 'stopping', 'stopped', 'shutting-down', 'terminated', 'quarantine') {
        push @{$self->{maps_counters}->{global}}, {
            label => 'vms-' . $_, display_ok => 0, nlabel => 'virtual_machines.' . $_ . '.count', set => {
                key_values => [ { name => $_ } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        };
    }

    $self->{maps_counters}->{vms} = [
        {
            label => 'vm-status',
            type => 2,
            set => {
                key_values => [ { name => 'state' }, { name => 'vmName' } ],
                output_template => 'state: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-id:s'   => { name => 'filter_id' },
        'filter-name:s' => { name => 'filter_name' },
        'vm-tag-name:s' => { name => 'vm_tag_name', default => 'name' }
    });

    return $self;
}

sub get_vm_name {
    my ($self, %options) = @_;

    foreach my $tag (@{$options{tags}}) {
        return $tag->{Value} if ($tag->{Key} =~ /^$self->{option_results}->{vm_tag_name}$/i);
    }

    return $options{id};
}

sub manage_selection {
    my ($self, %options) = @_;

    my $vms = $options{custom}->read_vms();

    $self->{global} = { detected => 0, pending => 0, running => 0, stopping => 0, stopped => 0, 'shutting-down' => 0, terminated => 0, quarantine => 0 };
    $self->{vms} = {};

    foreach (@$vms) {
        my $name = $self->get_vm_name(tags => $_->{Tags}, id => $_->{VmId});

        next if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $_->{VmId} !~ /$self->{option_results}->{filter_id}/);
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/);

        $self->{vms}->{ $_->{VmId} } = {
            vmName => $name,
            state => lc($_->{State})
        };

        $self->{global}->{ lc($_->{State}) }++
            if (defined($self->{global}->{ lc($_->{State}) }));
        $self->{global}->{detected}++;
    }
}

1;

__END__

=head1 MODE

Check virtual machines.

=over 8

=item B<--filter-id>

Filter virtual machines by id.

=item B<--filter-name>

Filter virtual machines by name.

=item B<--vm-tag-name>

Virtual machine tag to be used for the name (default: 'name').

=item B<--unknown-vm-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{vmName}

=item B<--warning-vm-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{vmName}

=item B<--critical-vm-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{state}, %{vmName}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'vms-detected', 'vms-pending', 'vms-running', 'vms-stopping',
'vms-stopped', 'vms-shutting-down', 'vms-terminated', 'vms-quarantine'.

=back

=cut
