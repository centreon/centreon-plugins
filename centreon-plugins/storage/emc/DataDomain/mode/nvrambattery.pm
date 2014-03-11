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

package storage::emc::DataDomain::mode::nvrambattery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %conditions = (
    1 => ['ok', 'OK'],
    2 => ['disabled', 'OK'], 
    3 => ['discharged', 'WARNING'],
    4 => ['unknown', 'UNKNOWN'],
    5 => ['soft disabled', 'OK'], 
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (5sec) threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (5sec) threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_nvramBatteryEntry = '.1.3.6.1.4.1.19746.1.2.3.1.1';
    my $oid_nvramBatteryStatus = '.1.3.6.1.4.1.19746.1.2.3.1.1.2';
    my $oid_nvramBatteryCharge = '.1.3.6.1.4.1.19746.1.2.3.1.1.3';
    my $result = $self->{snmp}->get_table(oid => $oid_nvramBatteryEntry, nothing_quit => 1);
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All nvram batteries are ok.');
    
    foreach my $oid (keys %$result) {
        next if ($oid !~ /^$oid_nvramBatteryStatus/);
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;
        
        my $status = $result->{$oid_nvramBatteryStatus . '.' . $instance};
        my $charge = $result->{$oid_nvramBatteryCharge . '.' . $instance};

        $self->{output}->output_add(long_msg => sprintf("nvram battery '%s' status is %s.", 
                                                        $instance, ${$conditions{$status}}[0]));
        if (!$self->{output}->is_status(litteral => 1, value => ${$conditions{$status}}[1], compare => 'ok')) {
            $self->{output}->output_add(severity => ${$conditions{$status}}[1],
                                        short_msg => sprintf("nvram battery '%s' status is %s", $instance, ${$conditions{$status}}[0]));
        }
        
        # Check only if ok
        if ($status == 1) {
            my $exit = $self->{perfdata}->threshold_check(value => $charge, 
                                                          threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
            $self->{output}->output_add(long_msg => sprintf("nvram battery '%s' charge is %s %%", $instance,
                                                            $charge));
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("nvram battery '%s' charge is %s %%", $instance,
                                                                 $charge));
            }
        
            $self->{output}->perfdata_add(label => 'nvram_battery_' . $instance, unit => '%',
                                          value => $charge,
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                          min => 0, max => 100);
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check nvram Batteries status and charge percentage (DATA-DOMAIN-MIB).

=over 8

=item B<--warning>

Threshold warning in percent (for charge).

=item B<--critical>

Threshold critical in percent (for charge).

=back

=cut
    