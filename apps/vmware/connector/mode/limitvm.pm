#
# Copyright 2016 Centreon (http://www.centreon.com/)
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
                                  "vm-hostname:s"           => { name => 'vm_hostname' },
                                  "filter"                  => { name => 'filter' },
                                  "filter-description:s"    => { name => 'filter_description' },
                                  "disconnect-status:s"     => { name => 'disconnect_status', default => 'unknown' },
                                  "cpu-limitset-status:s"       => { name => 'cpu_limitset_status', default => 'critical' },
                                  "memory-limitset-status:s"    => { name => 'memory_limitset_status', default => 'critical' },
                                  "disk-limitset-status:s"      => { name => 'disk_limitset_status', default => 'critical' },
                                  "nopoweredon-skip"        => { name => 'nopoweredon_skip' },
                                  "display-description"     => { name => 'display_description' },
                                  "check-disk-limit"        => { name => 'check_disk_limit' },
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
    if ($self->{output}->is_litteral_status(status => $self->{option_results}->{cpu_limitset_status}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong cpu-limitset-status option '" . $self->{option_results}->{cpu_limitset_status} . "'.");
        $self->{output}->option_exit();
    }
    if ($self->{output}->is_litteral_status(status => $self->{option_results}->{memory_limitset_status}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong memory-limitset-status option '" . $self->{option_results}->{memory_limitset_status} . "'.");
        $self->{output}->option_exit();
    }
    if ($self->{output}->is_litteral_status(status => $self->{option_results}->{disk_limitset_status}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong disk-limitset-status option '" . $self->{option_results}->{disk_limitset_status} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{connector} = $options{custom};

    $self->{connector}->add_params(params => $self->{option_results},
                                   command => 'limitvm');
    $self->{connector}->run();
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

=item B<--disconnect-status>

Status if VM disconnected (default: 'unknown').

=item B<--nopoweredon-skip>

Skip check if VM is not poweredOn.

=item B<--display-description>

Display virtual machine description.

=item B<--cpu-limitset-status>

Status if cpu limit is set (default: critical).

=item B<--memory-limitset-status>

Status if memory limit is set (default: critical).

=item B<--disk-limitset-status>

Status if disk limit is set (default: critical).

=item B<--check-disk-limit>

Check disk limits (since vsphere 5.0).

=back

=cut
