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

package apps::vmware::connector::mode::thinprovisioningvm;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "vm-hostname:s"           => { name => 'vm_hostname' },
        "filter"                  => { name => 'filter' },
        "scope-datacenter:s"      => { name => 'scope_datacenter' },
        "scope-cluster:s"         => { name => 'scope_cluster' },
        "scope-host:s"            => { name => 'scope_host' },
        "filter-description:s"    => { name => 'filter_description' },
        "filter-os:s"             => { name => 'filter_os' },
        "filter-uuid:s"           => { name => 'filter_uuid' },
        "disconnect-status:s"     => { name => 'disconnect_status', default => 'unknown' },
        "nopoweredon-skip"        => { name => 'nopoweredon_skip' },
        "display-description"     => { name => 'display_description' },
        "thinprovisioning-status:s"   => { name => 'thinprovisioning_status' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if ($self->{output}->is_litteral_status(status => $self->{option_results}->{disconnect_status}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong disconnect-status option '" . $self->{option_results}->{disconnect_status} . "'.");
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{thinprovisioning_status}) && $self->{option_results}->{thinprovisioning_status} ne '') {
        ($self->{thin_entry}, $self->{thin_status}) = split /,/, $self->{option_results}->{thinprovisioning_status};
        if ($self->{thin_entry} !~ /^(notactive|active)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong thinprovisioning-status option. Can only be 'active' or 'noactive'. Not: '" . $self->{thin_entry} . "'.");
            $self->{output}->option_exit();
        }
        if ($self->{output}->is_litteral_status(status => $self->{thin_status}) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong thinprovisioning-status option. Not a good status: '" . $self->{thin_status} . "'.");
            $self->{output}->option_exit();
        }
    }
}

sub display_verbose {
    my ($self, %options) = @_;
    
    foreach my $vm (sort keys %{$options{vms}}) {
        my $prefix = $vm;
        if (defined($options{vms}->{$vm}->{description}) && $options{vms}->{$vm}->{description} ne '') {
            $prefix .= ' [' . $options{vms}->{$vm}->{description} . ']';
        }
        $self->{output}->output_add(long_msg => $prefix);
        foreach my $disk (sort keys %{$options{vms}->{$vm}->{disks}}) {
            $self->{output}->output_add(long_msg => '    ' . $disk);
        }
    }
}

sub run {
    my ($self, %options) = @_;
    
    my $response = $options{custom}->execute(params => $self->{option_results},
        command => 'thinprovisioningvm');

    my $multiple = 0;
    if (scalar(keys %{$response->{data}}) > 1) {
        $multiple = 1;
    }
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                               short_msg => 'All thinprovisoning virtualdisks are ok.');
    } else {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'Thinprovisoning virtualdisks are ok.');
    }
    
    my $disks_vm = {};
    my %maps_match = ('active' => { regexp => '^1$', output => 'VirtualDisks thinprovisioning actived' },
                      'notactive' => { regexp => '^(?!(1)$)', output => 'VirtualDisks thinprovisioning not actived' });
    my $num = 0;    
    foreach my $vm_id (sort keys %{$response->{data}}) {
        my $vm_name = $response->{data}->{$vm_id}->{name};
        
        if ($options{custom}->entity_is_connected(state => $response->{data}->{$vm_id}->{connection_state}) == 0) {
            my $output = "VM '" . $vm_name . "' not connected. Current Connection State: '$response->{data}->{$vm_id}->{connection_state}'.";
            if ($multiple == 0 ||  
                !$self->{output}->is_status(value => $self->{option_results}->{disconnect_status}, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $self->{option_results}->{disconnect_status},
                                            short_msg => $output);
            }
            next;
        }
    
        next if (defined($self->{option_results}->{nopoweredon_skip}) && 
                 $options{custom}->vm_is_running(power => $response->{data}->{$vm_id}->{power_state}) == 0);
        
        foreach (@{$response->{data}->{$vm_id}->{disks}}) {
            if (defined($self->{thin_entry}) && $_->{thin_provisioned} =~ /$maps_match{$self->{thin_entry}}->{regexp}/) {
                $num++;
                if (!defined($disks_vm->{$vm_name})) {
                    $disks_vm->{$vm_name} = { disks => {}, description => (defined($self->{option_results}->{display_description}) ? $options{custom}->strip_cr(value => $response->{data}->{$vm_id}->{'config.annotation'}) : undef) };
                }
                $disks_vm->{$vm_name}->{disks}->{$_->{name}} = 1;
            }
        }
    }
    
    if ($num > 0) {
        $self->{output}->output_add(severity => $self->{thin_status},
                                    short_msg => sprintf('%d %s', $num, $maps_match{$self->{thin_entry}}->{output}));
        $self->display_verbose(vms => $disks_vm);
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check virtual machine thin provisioning option.

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

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--scope-cluster>

Search in following cluster(s) (can be a regexp).

=item B<--scope-host>

Search in following host(s) (can be a regexp).

=item B<--disconnect-status>

Status if VM disconnected (default: 'unknown').

=item B<--nopoweredon-skip>

Skip check if VM is not poweredOn.

=item B<--display-description>

Display virtual machine description.

=item B<--thinprovisioning-status>

Thinprovisioning status (default: none)
Example: 'active,CRITICAL' or 'notactive,WARNING'

=back

=cut
