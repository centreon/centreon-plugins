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
# Authors : Florian Asche <info@florian-asche.de>
#
####################################################################################

package apps::lmsensors::mode::voltage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_SensorDesc = '.1.3.6.1.4.1.2021.13.16.4.1.2';  # voltage entry description
my $oid_SensorValue = '.1.3.6.1.4.1.2021.13.16.4.1.3'; # voltage entry value (mV)

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning' },
                                  "critical:s"              => { name => 'critical' },
                                  "name"                    => { name => 'use_name' },
                                  "sensor:s"                => { name => 'sensor' },
                                  "regexp"                  => { name => 'use_regexp' },
                                  "regexp-isensitive"       => { name => 'use_regexpi' },
                                });

    $self->{Sensor_id_selected} = [];
    
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
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();

    $self->manage_selection();

    $self->{snmp}->load(oids => [$oid_SensorDesc, $oid_SensorValue], instances => $self->{Sensor_id_selected});
    my $SensorValueResult = $self->{snmp}->get_leef(nothing_quit => 1);

    if (!defined($self->{option_results}->{sensor}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All Voltages are ok.');
    }

    foreach my $SensorId (sort @{$self->{Sensor_id_selected}}) {
        my $SensorDesc = $SensorValueResult->{$oid_SensorDesc . '.' . $SensorId};
        my $SensorValue = $SensorValueResult->{$oid_SensorValue . '.' . $SensorId} / 1000;

        my $exit = $self->{perfdata}->threshold_check(value => $SensorValue, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

        $self->{output}->output_add(long_msg => sprintf("Sensor '%s' Volt: %s", 
                                            $SensorDesc, $SensorValue));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1) || (defined($self->{option_results}->{sensor}) && !defined($self->{option_results}->{use_regexp}))) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Sensor '%s' Volt: %s", 
                                            $SensorDesc, $SensorValue));
        }    

        my $label = 'sensor_voltage';
        my $extra_label = '';
        $extra_label = '_' . $SensorDesc if (!defined($self->{option_results}->{sensor}) || defined($self->{option_results}->{use_regexp}));
        $self->{output}->perfdata_add(label => $label . $extra_label, unit => 'V',
                                      value => $SensorValue,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));
    }

    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;
    my $result = $self->{snmp}->get_table(oid => $oid_SensorDesc, nothing_quit => 1);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /\.([0-9]+)$/);
        my $SensorId = $1;
        my $SensorDesc = $result->{$key};

        next if (defined($self->{option_results}->{sensor}) && !defined($self->{option_results}->{use_name}) && !defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi})
            && $SensorId !~ /$self->{option_results}->{sensor}/i);
        next if (defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) 
            && $SensorDesc !~ /$self->{option_results}->{sensor}/i);
        next if (defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) 
            && $SensorDesc !~ /$self->{option_results}->{sensor}/);
        next if (defined($self->{option_results}->{use_name}) && !defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi})
            && $SensorDesc ne $self->{option_results}->{sensor});


        push @{$self->{Sensor_id_selected}}, $SensorId;
}

    if (scalar(@{$self->{Sensor_id_selected}}) <= 0) {
        if (defined($self->{option_results}->{sensor})) {
            $self->{output}->add_option_msg(short_msg => "No Sensors found for '" . $self->{option_results}->{sensor} . "'.");
        } else {
            $self->{output}->add_option_msg(short_msg => "No Sensors found.");
        };
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check LM-Sensors: Voltage Sensors

=over 8

=item B<--warning>

Threshold warning (Volt)

=item B<--critical>

Threshold critical (Volt)

=item B<--sensor>

Set the Sensor Desc (number expected) ex: 1, 2,... (empty means 'check all sensors').

=item B<--name>

Allows to use Sensor Desc name with option --sensor instead of Sensor Desc oid index.

=item B<--regexp>

Allows to use regexp to filter sensordesc (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=back

=cut
