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

package centreon::common::cisco::standard::snmp::mode::stack;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_role = (
    1 => 'master',
    2 => 'member',
    3 => 'notMember',
    4 => 'standby'
);
my %states = (
    1 => ['waiting', 'WARNING'], 
    2 => ['progressing', 'WARNING'], 
    3 => ['added', 'WARNING'], 
    4 => ['ready', 'OK'],
    5 => ['sdmMismatch', 'CRITICAL'],
    6 => ['verMismatch', 'CRITICAL'],
    7 => ['featureMismatch', 'CRITICAL'],
    8 => ['newMasterInit', 'WARNING'],
    9 => ['provisioned', 'OK'],
    10 => ['invalid', 'WARNING'],
    11 => ['removed', 'WARNING'],
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

    my $oid_cswRingRedundant = '.1.3.6.1.4.1.9.9.500.1.1.3';
    my $oid_cswSwitchRole = '.1.3.6.1.4.1.9.9.500.1.2.1.1.3';
    my $oid_cswSwitchState = '.1.3.6.1.4.1.9.9.500.1.2.1.1.6';
    my $results = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_cswRingRedundant },
                                                            { oid => $oid_cswSwitchState },
                                                            { oid => $oid_cswSwitchRole }
                                                            ],
                                                   nothing_quit => 1);    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'Stack ring is redundant');
    if ($results->{$oid_cswRingRedundant}->{$oid_cswRingRedundant . '.0'} != 1) {
        $self->{output}->output_add(severity => 'WARNING',
                                    short_msg => 'Stack ring is not redundant');
    }
    
    foreach my $oid (keys %{$results->{$oid_cswSwitchState}}) {
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;

        my $state = $results->{$oid_cswSwitchState}->{$oid};
        my $role = defined($results->{$oid_cswSwitchRole}->{$oid_cswSwitchRole . '.' . $instance}) ? $results->{$oid_cswSwitchRole}->{$oid_cswSwitchRole . '.' . $instance} : 'unknown';
        # .1001, .2001 the instance.
        my $number = int(($instance - 1) / 1000);
        
        $self->{output}->output_add(long_msg => sprintf("Member '%s' state is %s [Role is '%s']", $number,
                                            ${$states{$state}}[0], $map_role{$role}));
        if (${$states{$state}}[1] ne 'OK') {
             $self->{output}->output_add(severity => ${$states{$state}}[1],
                                        short_msg => sprintf("Member '%s' state is %s", $number,
                                                             ${$states{$state}}[0]));
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Cisco Stack (CISCO-STACKWISE-MIB).

=over 8

=back

=cut
    