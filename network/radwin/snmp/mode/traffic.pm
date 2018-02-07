################################################################################
# Copyright 2017 Centreon (http://www.centreon.com/)
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
# Authors : Yann Pilpré <yann.pilpre@ypsi.fr>
#
####################################################################################

# Chemin vers le mode
package network::radwin::snmp::mode::traffic;

# Bibliothèque nécessaire pour le mode
use base qw(centreon::plugins::mode);


# Bibliothèques nécessaires
use strict;
use warnings;

# Bibliothèque nécessaire pour certaines fonctions
use POSIX;

# Bibliothèque nécessaire pour utiliser un fichier de cache
use centreon::plugins::statefile;
use centreon::plugins::misc;
use Digest::MD5 qw(md5_hex);


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    $self->{version} = '1.0';
     $options{options}->add_options(arguments =>
                              {
                                # nom de l'option    => nom de la variable
				
                                  "warning-in:s"        => { name => 'warning_in', },
                                  "critical-in:s"       => { name => 'critical_in', },
                                  "warning-out:s"       => { name => 'warning_out', },
                                  "critical-out:s"      => { name => 'critical_out', },
				"units:s"           => { name => 'units', default => 'B' },
                              });
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);


    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

  if (($self->{perfdata}->threshold_validate(label => 'warning-in', value => $self->{option_results}->{warning_in})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning 'in' threshold '" . $self->{option_results}->{warning_in} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-in', value => $self->{option_results}->{critical_in})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical 'in' threshold '" . $self->{option_results}->{critical_in} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-out', value => $self->{option_results}->{warning_out})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning 'out' threshold '" . $self->{option_results}->{warning_out} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-out', value => $self->{option_results}->{critical_out})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical 'out' threshold '" . $self->{option_results}->{critical_out} . "'.");
        $self->{output}->option_exit();
    }
    
  # Validation des options de fichier de cache en utilisant la méthode check_options de la bibliothèque statefile
  $self->{statefile_value}->check_options(%options);

}

sub run {
  my ($self, %options) = @_;

  $self->{snmp} = $options{snmp};
  $self->{hostname} = $self->{snmp}->get_hostname();
  $self->{snmp_port} = $self->{snmp}->get_port();

    my $new_datas = {};
    $self->{statefile_value}->read(statefile => "cache_radwin_snmp_" . $self->{hostname}  . '_' . $self->{mode} . '_' . ( $self->{hostname} ? md5_hex( $self->{hostname}) : md5_hex('all')));
    $new_datas->{last_timestamp} = time();
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');


  my $oid_BridgeTpPortInBytes= ".1.3.6.1.4.1.4458.1000.1.4.4.3.1.102.0";
  my $oid_BridgeTpPortOutBytes= ".1.3.6.1.4.1.4458.1000.1.4.4.3.1.101.0";
  my $oid_EthernetRemainingRate = ".1.3.6.1.4.1.4458.1000.1.3.1.0";

    my $snmpinfo  = $self->{snmp}->get_leef(oids => [ $oid_BridgeTpPortInBytes, $oid_BridgeTpPortOutBytes,$oid_EthernetRemainingRate ], nothing_quit => 1);

     $new_datas->{'in'} = $snmpinfo->{$oid_BridgeTpPortInBytes} * 8;
     $new_datas->{'out'} = $snmpinfo->{$oid_BridgeTpPortOutBytes} * 8;

       my $old_in = $self->{statefile_value}->get(name => 'in');
       my $old_out = $self->{statefile_value}->get(name => 'out');
 if (defined($old_timestamp) || defined($old_in) || defined($old_out)) {
             
         if ($new_datas->{'in'} < $old_in) {
            # We set 0. Has reboot.
            $old_in = 0;
        }
        if ($new_datas->{'out'} < $old_out) {
            # We set 0. Has reboot.
            $old_out = 0;
        }

      my $time_delta = $new_datas->{last_timestamp} - $old_timestamp;
        if ($time_delta <= 0) {
            # At least one second. two fast calls ;)
            $time_delta = 1;
        }

        my $in_absolute_per_sec = ($new_datas->{'in'} - $old_in) / $time_delta;
        my $out_absolute_per_sec = ($new_datas->{'out'} - $old_out) / $time_delta;



        my ($exit, $interface_speed, $in_prct, $out_prct);
	$interface_speed = $snmpinfo->{$oid_EthernetRemainingRate};

	 $in_prct = $in_absolute_per_sec * 100 / $interface_speed   ;
         $out_prct = $out_absolute_per_sec * 100 / $interface_speed ;

         if ($self->{option_results}->{units} eq '%') {
                my $exit1 = $self->{perfdata}->threshold_check(value => $in_prct, threshold => [ { label => 'critical-in', 'exit_litteral' => 'critical' }, { label => 'warning-in', exit_litteral => 'warning' } ]);
                my $exit2 = $self->{perfdata}->threshold_check(value => $out_prct, threshold => [ { label => 'critical-out', 'exit_litteral' => 'critical' }, { label => 'warning-out', exit_litteral => 'warning' } ]);
                $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
            }

            $in_prct = sprintf("%.2f", $in_prct);
            $out_prct = sprintf("%.2f", $out_prct);
	



         if ($self->{option_results}->{units} ne '%') {
            my $exit1 = $self->{perfdata}->threshold_check(value => $in_absolute_per_sec, threshold => [ { label => 'critical-in', 'exit_litteral' => 'critical' }, { label => 'warning-in', exit_litteral => 'warning' } ]);
            my $exit2 = $self->{perfdata}->threshold_check(value => $out_absolute_per_sec, threshold => [ { label => 'critical-out', 'exit_litteral' => 'critical' }, { label => 'warning-out', exit_litteral => 'warning' } ]);
    
            $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
        }



      my ($in_value, $in_unit) = $self->{perfdata}->change_bytes(value => $in_absolute_per_sec, network => 1);
        my ($out_value, $out_unit) = $self->{perfdata}->change_bytes(value => $out_absolute_per_sec, network => 1);

     $self->{output}->output_add(short_msg => sprintf("Interface Radio Traffic In : %s/s (%s %%), Out : %s/s (%s %%) ",
                                       $in_value . $in_unit, $in_prct,
                                       $out_value . $out_unit, $out_prct));


    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Interface Radio Traffic In : %s/s (%s %%), Out : %s/s (%s %%) ",
                                            $in_value . $in_unit, $in_prct,
                                            $out_value . $out_unit, $out_prct));
        }

$self->{output}->perfdata_add(label => 'traffic_in', unit => 'b/s',
                                      value => sprintf("%.2f", $in_absolute_per_sec),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-in', total => $interface_speed),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-in', total => $interface_speed),
                                      min => 0, max => $interface_speed);
 $self->{output}->perfdata_add(label => 'traffic_out', unit => 'b/s',
                                      value => sprintf("%.2f", $out_absolute_per_sec),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-out', total => $interface_speed),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-out', total => $interface_speed),
                                      min => 0, max => $interface_speed);
}
$self->{statefile_value}->write(data => $new_datas);   
 
    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
    }

   $self->{output}->display();
    $self->{output}->exit();
  }
1;
=head1 MODE

This Mode Checks RADWIN Radio Inteface Traffic.
This Mode needs SNMP

=over 8

=item B<--warning-in>

Threshold warning for 'in' traffic.

=item B<--critical-in>

Threshold critical for 'in' traffic.

=item B<--warning-out>

Threshold warning for 'out' traffic.

=item B<--critical-out>

Threshold critical for 'out' traffic.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'b').

=item B<--hostname>

Hostname to query.

=back

=cut
