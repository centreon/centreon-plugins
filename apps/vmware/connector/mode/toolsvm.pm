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

package apps::vmware::connector::mode::toolsvm;

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
        "display-description"     => { name => 'display_description' },
        "disconnect-status:s"     => { name => 'disconnect_status', default => 'unknown' },
        "tools-notinstalled-status:s"   => { name => 'tools_notinstalled_status', default => 'critical' },
        "tools-notrunning-status:s"     => { name => 'tools_notrunning_status', default => 'critical' },
        "tools-notup2date-status:s"     => { name => 'tools_notupd2date_status', default => 'warning' },
        "nopoweredon-skip"              => { name => 'nopoweredon_skip' },
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
    if ($self->{output}->is_litteral_status(status => $self->{option_results}->{tools_notinstalled_status}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong tools-notinstalled-status option '" . $self->{option_results}->{tools_notinstalled_status} . "'.");
        $self->{output}->option_exit();
    }
    if ($self->{output}->is_litteral_status(status => $self->{option_results}->{tools_notrunning_status}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong tools-notrunning-status option '" . $self->{option_results}->{tools_notrunning_status} . "'.");
        $self->{output}->option_exit();
    }
    if ($self->{output}->is_litteral_status(status => $self->{option_results}->{tools_notupd2date_status}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong tools-notupd2date-status option '" . $self->{option_results}->{tools_notupd2date_status} . "'.");
        $self->{output}->option_exit();
    }
}

sub display_verbose {
    my ($self, %options) = @_;
    
    $self->{output}->output_add(long_msg => $options{label});
    foreach my $vm (sort keys %{$options{vms}}) {
        my $prefix = $vm;
        if ($options{vms}->{$vm} ne '') {
            $prefix .= ' [' . $options{custom}->strip_cr(value => $options{vms}->{$vm}) . ']';
        }
        $self->{output}->output_add(long_msg => '    ' . $prefix);
    }
}

sub run {
    my ($self, %options) = @_;
    
    my $response = $options{custom}->execute(params => $self->{option_results},
        command => 'toolsvm');

    my $multiple = 0;
    if (scalar(keys %{$response->{data}}) > 1) {
        $multiple = 1;
    }
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                               short_msg => 'All VMTools are OK');
    } else {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'VMTools are OK');
    }
    
    my %not_installed = ();
    my %not_running = ();
    my %not_up2date = ();
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
        
        next if (!defined($response->{data}->{$vm_id}->{tools_status}));
        
        my $tools_status = lc($response->{data}->{$vm_id}->{tools_status});
        if ($tools_status eq 'toolsnotinstalled') {
            $not_installed{$vm_name} = defined($response->{data}->{$vm_id}->{'config.annotation'}) ? $response->{data}->{$vm_id}->{'config.annotation'} : '';
        } elsif ($tools_status eq 'toolsnotrunning') {
            $not_running{$vm_name} = defined($response->{data}->{$vm_id}->{'config.annotation'}) ? $response->{data}->{$vm_id}->{'config.annotation'} : '';
        } elsif ($tools_status eq 'toolsold') {
            $not_up2date{$vm_name} = defined($response->{data}->{$vm_id}->{'config.annotation'}) ? $response->{data}->{$vm_id}->{'config.annotation'} : '';
        }
    }
    
    if (scalar(keys %not_up2date) > 0 && 
        !$self->{output}->is_status(value => $self->{option_results}->{tools_notupd2date_status}, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $self->{option_results}->{tools_notupd2date_status},
                                               short_msg => sprintf('%d VM with VMTools not up-to-date', scalar(keys %not_up2date)));
        $self->display_verbose(label => 'vmtools not up-to-date:', vms => \%not_up2date, custom => $options{custom});
    }
    if (scalar(keys %not_running) > 0 &&
        !$self->{output}->is_status(value => $self->{option_results}->{tools_notrunning_status}, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $self->{option_results}->{tools_notrunning_status},
                                               short_msg => sprintf('%d VM with VMTools not running', scalar(keys %not_running)));
        $self->display_verbose(label => 'vmtools not running:', vms => \%not_running, custom => $options{custom});
    }
    if (scalar(keys %not_installed) > 0 &&
        !$self->{output}->is_status(value => $self->{option_results}->{tools_notinstalled_status}, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $self->{option_results}->{tools_notinstalled_status},
                                               short_msg => sprintf('%d VM with VMTools not installed', scalar(keys %not_installed)));
        $self->display_verbose(label => 'vmtools not installed:', vms => \%not_installed, custom => $options{custom});
    }
    
    if ($multiple == 1) {
        my $total = scalar(keys %not_up2date) + scalar(keys %not_running) + scalar(keys %not_installed);
        $self->{output}->perfdata_add(
            label => 'not_updated',
            nlabel => 'vm.tools.notupdated.current.count',
            value => scalar(keys %not_up2date),
            min => 0, max => $total
        );
        $self->{output}->perfdata_add(
            label => 'not_running',
            nlabel => 'vm.tools.notrunning.current.count',
            value => scalar(keys %not_running),
            min => 0, max => $total
        );
        $self->{output}->perfdata_add(
            label => 'not_installed',
            nlabel => 'vm.tools.notinstalled.current.count',
            value => scalar(keys %not_installed),
            min => 0, max => $total
        );
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check virtual machine tools.

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

=item B<--tools-notinstalled-status>

Status if vmtools is not installed (default: critical).

=item B<--tools-notrunning-status>

Status if vmtools is not running (default: critical).

=item B<--tools-notup2date-status>

Status if vmtools is not upd2date (default: warning).

=back

=cut
