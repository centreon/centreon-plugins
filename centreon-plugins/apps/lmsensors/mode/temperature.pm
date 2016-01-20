#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package apps::lmsensors::mode::temperature;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_SensorDesc = '.1.3.6.1.4.1.2021.13.16.2.1.2';  # temperature entry description
my $oid_SensorValue = '.1.3.6.1.4.1.2021.13.16.2.1.3'; # temperature entry value (RPM)

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
                                    short_msg => 'All Temperatures are ok.');
    }

    foreach my $SensorId (sort @{$self->{Sensor_id_selected}}) {
        my $SensorDesc = $SensorValueResult->{$oid_SensorDesc . '.' . $SensorId};
        my $SensorValue = $SensorValueResult->{$oid_SensorValue . '.' . $SensorId} / 1000;

        my $exit = $self->{perfdata}->threshold_check(value => $SensorValue, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

        $self->{output}->output_add(long_msg => sprintf("Sensor '%s' Temperature: %s", 
                                            $SensorDesc, $SensorValue));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1) || (defined($self->{option_results}->{sensor}) && !defined($self->{option_results}->{use_regexp}))) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Sensor '%s' Temperature: %s", 
                                            $SensorDesc, $SensorValue));
        }    

        my $label = 'sensor_temperature';
        my $extra_label = '';
        $extra_label = '_' . $SensorId . "_" . $SensorDesc if (!defined($self->{option_results}->{sensor}) || defined($self->{option_results}->{use_regexp}));
        $self->{output}->perfdata_add(label => $label . $extra_label,
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

Check LM-Sensors: Temperature Sensors

=over 8

=item B<--warning>

Threshold warning

=item B<--critical>

Threshold critical

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
