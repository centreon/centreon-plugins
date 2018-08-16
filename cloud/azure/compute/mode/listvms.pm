#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package cloud::azure::compute::mode::listvms;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                    "resource-group:s"    => { name => 'resource_group' },
                                    "filter-name:s"       => { name => 'filter_name' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{vms} = $options{custom}->azure_list_vms(
        resource_group => $self->{option_results}->{resource_group},
        show_details => 1
    );
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $vm (@{$self->{vms}}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $vm->{name} !~ /$self->{option_results}->{filter_name}/);
        $self->{output}->output_add(long_msg => sprintf("[name = %s][computername = %s][resourcegroup = %s]" .
            "[location = %s][vmid = %s][vmsize = %s][os = %s][state = %s]",
            $vm->{name}, (defined($vm->{osProfile}->{computerName})) ? $vm->{osProfile}->{computerName} : "-",
            $vm->{resourceGroup}, $vm->{location}, $vm->{vmId}, $vm->{hardwareProfile}->{vmSize},
            $vm->{storageProfile}->{osDisk}->{osType}, $vm->{powerState}));
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List vitual machines:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'computername', 'resourcegroup', 'location', 'vmid', 'vmsize', 'os', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $vm (@{$self->{vms}}) {
        $self->{output}->add_disco_entry(
            name => $vm->{name},
            computername => (defined($vm->{osProfile}->{computerName})) ? $vm->{osProfile}->{computerName} : "-",
            resourcegroup => $vm->{resourceGroup},
            location => $vm->{location},
            vmid => $vm->{vmId},
            vmsize => $vm->{hardwareProfile}->{vmSize},
            os => $vm->{storageProfile}->{osDisk}->{osType},
            state => $vm->{powerState},
        );
    }
}

1;

__END__

=head1 MODE

List vitual machines.

=over 8

=item B<--resource-group>

Set resource group (Optional).

=item B<--filter-name>

Filter resource name (Can be a regexp).

=back

=cut
