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

package apps::lotus::snmp::mode::mailstate;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
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
