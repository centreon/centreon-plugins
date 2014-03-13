################################################################################
# Copyright 2005-2013 MERETHIS
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

package snmp_standard::mode::hardwaredevice;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

my %device_status = (
    1 => ["Device '%s' status is unknown", 'UNKNOWN'], 
    2 => ["Device '%s' status is running", 'OK'], 
    3 => ["Device '%s' status is warning", 'WARNING'], 
    4 => ["Device '%s' status is testing", 'OK'], 
    5 => ["Device '%s' status is down", 'CRITICAL'], 
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "All devices are ok.");
    
    my $oid_hrDeviceEntry = '.1.3.6.1.2.1.25.3.2.1';
    my $oid_hrDeviceDescr = '.1.3.6.1.2.1.25.3.2.1.3';
    my $oid_hrDeviceStatus = '.1.3.6.1.2.1.25.3.2.1.5';
    my $result = $self->{snmp}->get_table(oid => $oid_hrDeviceEntry, nothing_quit => 1);
    
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_hrDeviceStatus\.(.*)/);
        my $index = $1;
        my $status = $result->{$oid_hrDeviceStatus . '.' . $index};
        my $descr = centreon::plugins::misc::trim($result->{$oid_hrDeviceDescr . '.' . $index});
        
        $self->{output}->output_add(long_msg => sprintf(${$device_status{$status}}[0], $descr));
        if (!$self->{output}->is_status(value => ${$device_status{$status}}[1], compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => ${$device_status{$status}}[1],
                                        short_msg => sprintf(${$device_status{$status}}[0], $descr));
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check hardware devices (HOST-RESOURCES-MIB).

=over 8

=back

=cut
