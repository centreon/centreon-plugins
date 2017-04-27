################################################################################
## Copyright 2005-2015 MERETHIS
## Centreon is developped by : Julien Mathis and Romain Le Merlus under
## GPL Licence 2.0.
##
## This program is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free Software
## Foundation ; either version 2 of the License.
##
## This program is distributed in the hope that it will be useful, but WITHOUT ANY
## WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
## PARTICULAR PURPOSE. See the GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License along with
## this program; if not, see <http://www.gnu.org/licenses>.
##
## Linking this program statically or dynamically with other modules is making a
## combined work based on this program. Thus, the terms and conditions of the GNU
## General Public License cover the whole combination.
##
## As a special exception, the copyright holders of this program give MERETHIS
## permission to link this program with independent modules to produce an executable,
## regardless of the license terms of these independent modules, and to copy and
## distribute the resulting executable under terms of MERETHIS choice, provided that
## MERETHIS also meet, for each linked independent module, the terms  and conditions
## of the license of that module. An independent module is a module which is not
## derived from this program. If you modify this program, you may extend this
## exception to your version of the program, but you are not obliged to do so. If you
## do not wish to do so, delete this exception statement from your version.
##
## For more information : contact@centreon.com
## Authors : Christophe De Loeul <cdeloeul@gmail.com>
##
#####################################################################################

package hardware::pdu::schleifenbauer::gtw::snmp::mode::temperature;

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
                                "warning:s"          => { name => 'warning', },
                                "critical:s"         => { name => 'critical', },
                                "device:s"         => { name => 'device', },
                              });

  return $self;
}

sub check_options {
  my ($self, %options) = @_;
  $self->SUPER::init(%options);

  if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
     $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
     $self->{output}->option_exit();
  }
  if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
     $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
     $self->{output}->option_exit();
  }

}

sub run {
  my ($self, %options) = @_;

  $self->{snmp} = $options{snmp};
  $self->{hostname} = $self->{snmp}->get_hostname();
  $self->{snmp_port} = $self->{snmp}->get_port();

  my $Id = $self->{option_results}->{device};

  my $oid_temperature = ".1.3.6.1.4.1.31034.1.1.8.1.11.$Id.1";
  my $oid_type = ".1.3.6.1.4.1.31034.1.1.8.1.10.$Id.1";
  my $oid_name = ".1.3.6.1.4.1.31034.1.1.8.1.12.$Id.1";
  my ($result, $value);

  $result = $self->{snmp}->get_leef(oids => [ $oid_temperature ], nothing_quit => 1);
  $value = $result->{$oid_temperature};

  #temperature is an int so we devide by 100 toi have it in C degrees
  my $temperature = $value / 100;

  $result = $self->{snmp}->get_leef(oids => [ $oid_type ], nothing_quit => 1);
  my $type = $result->{$oid_type};

  $result = $self->{snmp}->get_leef(oids => [ $oid_name ], nothing_quit => 1);
  my $name = $result->{$oid_name};

  my $exit_code = $self->{perfdata}->threshold_check(value => $temperature,
                                                     threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

  $self->{output}->perfdata_add(label => "Temperature",
                                value => sprintf("%.2f", $temperature),
                                warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                min => 0);

  # Ajout du message de sortie
  $self->{output}->output_add(severity => $exit_code,
                              short_msg => sprintf("$name : %.2f C",
                                  $temperature));

  # Affichage du message de sortie
  $self->{output}->display();
  $self->{output}->exit();
}


1;

__END__

=head1 MODE

Check temperature of a PDU connected to the gateway.

=over 8

=item B<--warning>

Threshold warning for temperature.

=item B<--critical>

Threshold critical for temperature.

=back

=cut
