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
# Authors : Simon Bomm <sbomm@centreon.com>
#
####################################################################################
package network::cisco::common::mode::hsrp;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_row_status = (
    1 => 'active',
    2 => 'notInService',
    3 => 'notReady',
    4 => 'createAndGo',
    5 => 'createAndWait',
    6 => 'destroy'
);
my %map_states = (
    1 => 'initial',
    2 => 'learn',
    3 => 'listen',
    4 => 'speak',
    5 => 'standby',
    6 => 'active',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "role:s"               => { name => 'role', default => 'primary' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    if (($self->{option_results}->{role} ne 'primary') && ($self->{option_results}->{role} ne 'secondary')) {
        $self->{output}->add_option_msg(short_msg => "You must use either primary either secondary for --role option");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    my $vridout = '';
    my $oid_cHsrpGrpStandbyState = ".1.3.6.1.4.1.9.9.106.1.2.1.1.15";    # HSRP Oper Status
    my $oid_cHsrpGrpEntryRowStatus = ".1.3.6.1.4.1.9.9.106.1.2.1.1.17";   # HSRP Admin Status

    my $result_state = $self->{snmp}->get_table(oid => $oid_cHsrpGrpStandbyState, nothing_quit => 1);
    my $result_status = $self->{snmp}->get_table(oid => $oid_cHsrpGrpEntryRowStatus, nothing_quit => 1);

    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("Router is in its expected state : '%s'", $self->{option_results}->{role}));
    
    foreach my $oid (keys %$result_state) {
	$oid =~ /(([0-9]+)\.([0-9]+))$/; 
        my $vrid = $1;
        
        my $operState = $result_status->{$oid_cHsrpGrpEntryRowStatus . "." . $vrid};
        my $adminState = $result_state->{$oid_cHsrpGrpStandbyState . "." . $vrid};

        $self->{output}->output_add(long_msg => sprintf("[Vrid : %s] [Admin Status is '%s'] [Oper Status is '%s']",
                                                               $vrid, $map_states{$adminState}, $map_row_status{$operState}));
        
        if ($operState != 1) {
            $self->{output}->output_add(severity => 'CRITICAL',
					short_msg => sprintf("VRID %s operational state is '%s'", $vrid, $map_row_status{$operState}));
        }

        if (($self->{option_results}->{role} eq 'primary' && $adminState != 6) || ($self->{option_results}->{role} eq 'secondary' && $adminState != 5)) {
            $vridout .= sprintf("(VRID %s is '%s')", $vrid, $map_states{$adminState});
        }
    
    }       
    
    if ($vridout ne '') {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("%s - Router isn't in the expected state (%s)", $vridout, $self->{option_results}->{role}));
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Cisco HSRP (CISCO-HSRP-MIB). Trigger a critical if not in the expected state or if a VRID is not in an active state.

=over 8

=back

=cut
    
