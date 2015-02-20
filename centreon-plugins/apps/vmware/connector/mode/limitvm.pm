################################################################################
# Copyright 2005-2014 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

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
