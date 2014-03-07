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

package network::hp::procurve::mode::environment;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

my %states = (
    1 => ['unknown', 'UNKNOWN'], 
    2 => ['bad', 'CRITICAL'], 
    3 => ['warning', 'WARNING'], 
    4 => ['good', 'OK'],
    5 => ['not present', 'WARNING'],
);

my %object_map = (
    '.1.3.6.1.4.1.11.2.3.7.8.3.1' => 'power supply', #icfPowerSupplySensor
    '.1.3.6.1.4.1.11.2.3.7.8.3.2' => 'fan',          #icfFanSensor
    '.1.3.6.1.4.1.11.2.3.7.8.3.3' => 'temperature',  #icfTemperatureSensor
    '.1.3.6.1.4.1.11.2.3.7.8.3.4' => 'future slot',  #icfFutureSlotSensor
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                    "skip-not-present"           => { name => 'skip_not_present' },
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

    my $oid_hpicfSensorEntry = '.1.3.6.1.4.1.11.2.14.11.1.2.6.1';
    my $oid_hpicfSensorObjectId = '.1.3.6.1.4.1.11.2.14.11.1.2.6.1.2';
    my $oid_hpicfSensorStatus = '.1.3.6.1.4.1.11.2.14.11.1.2.6.1.4';
    my $oid_hpicfSensorDescr = '.1.3.6.1.4.1.11.2.14.11.1.2.6.1.7';
 
    my $result = $self->{snmp}->get_table(oid => $oid_hpicfSensorEntry, nothing_quit => 1);
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All sensors are ok."));  
    
    foreach my $oid (keys %$result) {
        next if ($oid !~ /^$oid_hpicfSensorStatus\./);
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;
    
        my $descr = centreon::plugins::misc::trim($result->{$oid_hpicfSensorDescr . '.' . $instance});
        my $status = $result->{$oid_hpicfSensorStatus . '.' . $instance};
        my $object = $result->{$oid_hpicfSensorObjectId . '.' . $instance};
        
        $self->{output}->output_add(long_msg => sprintf("%s sensor '%s' state is %s.", 
                                                        $object_map{$object}, $instance,
                                                        ${$states{$status}}[0]));
        if (defined($self->{option_results}->{skip_not_present}) &&
            $status == 5) {
            $self->{output}->output_add(long_msg => sprintf("Skipping %s sensor '%s'.",
                                                            $object_map{$object}, $instance));
            next;
        }
        if (${$states{$status}}[1] ne 'OK') {
            $self->{output}->output_add(severity  => ${$states{$status}}[1],
                                        short_msg => sprintf("%s sensor '%s' state is %s.", 
                                                        $object_map{$object}, $instance,
                                                        ${$states{$status}}[0]));
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check sensors (hpicfChassis.mib).

=over 8

=item B<--skip-not-present>

No warning for state 'not present'.

=back

=cut
    