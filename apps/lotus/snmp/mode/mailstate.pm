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
# Authors : Simon Bomm <sbomm@merethis.com>
#
####################################################################################

package apps::lotus::snmp::mode::mailstate;

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
                                  "warning-waiting:s"               => { name => 'warning_waiting', },
                                  "critical-waiting:s"              => { name => 'critical_waiting', },
                                  "warning-dead:s"               => { name => 'warning_dead', },
                                  "critical-dead:s"              => { name => 'critical_dead', },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning-waiting', value => $self->{option_results}->{warning_waiting})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-waiting threshold '" . $self->{option_results}->{warning_waiting} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-waiting', value => $self->{option_results}->{critical_waiting})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-waiting threshold '" . $self->{option_results}->{critical_waiting} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-dead', value => $self->{option_results}->{warning_dead})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-dead threshold '" . $self->{option_results}->{warning_dead} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-dead', value => $self->{option_results}->{critical_dead})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-dead threshold '" . $self->{option_results}->{critical_dead} . "'.");
       $self->{output}->option_exit();
    }

}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    my $oid_lnDeadMail = '.1.3.6.1.4.1.334.72.1.1.4.1.0';
#   my $oid_DeliveredMail = '.1.3.6.1.4.1.334.72.1.1.4.2.0';
#   my $oid_TransferredMail = '.1.3.6.1.4.1.334.72.1.1.4.5.0';
    my $oid_lnWaitingMail = '.1.3.6.1.4.1.334.72.1.1.4.6.0';

    my $results = $self->{snmp}->get_leef(oids => [$oid_lnDeadMail, $oid_lnWaitingMail], nothing_quit => 1);
#   my $delivered = $self->{snmp}->get_leef(oid => $oid_DeliveredMail, nothing_quit => 1); 
#   my $transferred = $self->{snmp}->get_leef(oid => $oid_TransferredMail, nothing_quit => 1);

    my $exit1 = $self->{perfdata}->threshold_check(value => $results->{$oid_lnDeadMail}, 
                               threshold => [ { label => 'critical-dead', 'exit_litteral' => 'critical' }, { label => 'warning-dead', exit_litteral => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $results->{$oid_lnWaitingMail},
                               threshold => [ { label => 'critical-waiting', 'exit_litteral' => 'critical' }, { label => 'warning-waiting', exit_litteral => 'warning' } ]);
    my $exit_code = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);


    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("Number of dead mail: %d Number of waiting mail: %d", $results->{$oid_lnDeadMail}, $results->{$oid_lnWaitingMail}));
    $self->{output}->perfdata_add(label => 'dead', unit => 'mail',
                                  value => $results->{$oid_lnDeadMail},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-dead'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-dead'),
                                  );
    $self->{output}->perfdata_add(label => 'waiting', unit => 'mail',
                                  value => $results->{$oid_lnWaitingMail},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-waiting'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-waiting'),
                                  );
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check the number of dead and wainting mail on the lotus server (NOTES-MIB.mib)

=over 8

=item B<--warning-dead>

Threshold warning in percent.

=item B<--critical-dead>

Threshold critical in percent.

=item B<--warning-waiting>

Threshold warning in percent.

=item B<--critical-waiting>

Threshold critical in percent.

=back

=cut
