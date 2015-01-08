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

package network::checkpoint::mode::hastate;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_status = (
    0 => 'Member is UP and working',
    1 => 'Problem preventing role switching',
    2 => 'HA is down',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
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
    
    my $oid_haInstalled = '.1.3.6.1.4.1.2620.1.5.2.0';
    my $oid_haState = '.1.3.6.1.4.1.2620.1.5.6.0';
    my $oid_haStatCode = '.1.3.6.1.4.1.2620.1.6.7.2.2.0';
    my $oid_haStarted = '.1.3.6.1.4.1.2620.1.5.5.0';
    
    my $result = $self->{snmp}->get_leef(oids => [$oid_haInstalled, $oid_haState, $oid_haStatCode, $oid_haStarted], nothing_quit => 1);
    
    if ($result->{$oid_haInstalled} < 1 or $result->{$oid_haStarted} eq "no") {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => sprintf("Looks like HA is not started, or not installed .."),
                                    long_msg => sprintf("HA Installed : '%u' HA Started : '%s'", $result->{$oid_haInstalled},  $result->{$oid_haStarted}),
                                    );
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    my $status = $result->{$oid_haStatCode};

    if ($status < 1 ) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => sprintf("'%s'. State : '%s'", $map_status{$status}, $result->{$oid_haState}),
                                    );
    } elsif ($status == 1) {
        $self->{output}->output_add(severity => 'WARNING',
                                    short_msg => sprintf("'%s'. State : '%s'", $map_status{$status}, $result->{$oid_haState}),
                                    );

    } else {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("'%s'. State : '%s'", $map_status{$status}, $result->{$oid_haState}),
                                    );
    }
  
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check HA State of a Checkpoint node (chkpnt.mib).

=back

=cut
    
