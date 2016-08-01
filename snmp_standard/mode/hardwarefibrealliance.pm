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

package snmp_standard::mode::hardwarefibrealliance;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %oids = (
    connUnitSensorName           => '.1.3.6.1.3.94.1.8.1.3',
    connUnitSensorStatus         => '.1.3.6.1.3.94.1.8.1.4',
    connUnitSensorMessage        => '.1.3.6.1.3.94.1.8.1.6',
    connUnitSensorType           => '.1.3.6.1.3.94.1.8.1.7',
    connUnitSensorCharacteristic => '.1.3.6.1.3.94.1.8.1.8',
    
    connUnitPortName    => '.1.3.6.1.3.94.1.10.1.17',
    connUnitPortStatus  => '.1.3.6.1.3.94.1.10.1.7',
);

my %map_sensor_status = (
    1 => 'unknown',
    2 => 'other',
    3 => 'ok',
    4 => 'warning',
    5 => 'failed',
);

my %map_port_status = (
    1 => 'unknown', 2 => 'unused',
    3 => 'ready', 4 => 'warning', 
    5 => 'failure', 6 => 'notparticipating', 
    7 => 'initializing', 8 => 'bypass', 
    9 => 'ols', 10 => 'other', 
);

my %map_sensor_type = (
    1 => 'unknown', 2 => 'other',
    3 => 'battery', 4 => 'fan',
    5 => 'power-supply', 6 => 'transmitter',
    7 => 'enclosure', 8 => 'board', 9 => 'receiver',
);

my %map_sensor_chara = (
    1 => 'unknown', 2 => 'other',
    3 => 'temperature', 4 => 'pressure',
    5 => 'emf', 6 => 'currentValue', 7 => 'airflow',
    8 => 'frequency', 9 => 'power', 10 => 'door',
);

my $thresholds = {
    sensors => [
        ['unknown', 'UNKNOWN'],
        ['other', 'UNKNOWN'],
        ['warning', 'WARNING'],
        ['critical', 'CRITICAL'],
        ['ok', 'OK'],
    ],
    port => [
        ['warning', 'WARNING'],
        ['failure', 'CRITICAL'],
        ['unused', 'OK'],
        ['initializing', 'OK'],
        ['ready', 'OK'],
        ['.*', 'UNKNOWN'],
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "exclude:s"        => { name => 'exclude' },
                                  "component:s"      => { name => 'component', default => 'all' },
                                  "no-component:s"          => { name => 'no_component' },
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                });

    $self->{components} = {};
    $self->{no_components} = undef;
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (defined($self->{option_results}->{no_component})) {
        if ($self->{option_results}->{no_component} ne '') {
            $self->{no_components} = $self->{option_results}->{no_component};
        } else {
            $self->{no_components} = 'critical';
        }
    }
    
    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
}

sub component {
    my ($self, %options) = @_;
    
    if ($self->{option_results}->{component} eq 'all') {    
        $self->check_sensors();
        $self->check_port();
    } elsif ($self->{option_results}->{component} eq 'sensors') {
        $self->check_sensors();
    } elsif ($self->{option_results}->{component} eq 'port') {
        $self->check_port();
    } else {
        $self->{output}->add_option_msg(short_msg => "Wrong option. Cannot find component '" . $self->{option_results}->{component} . "'.");
        $self->{output}->option_exit();
    }
    
    my $total_components = 0;
    my $display_by_component = '';
    my $display_by_component_append = '';
    foreach my $comp (sort(keys %{$self->{components}})) {
        # Skipping short msg when no components
        next if ($self->{components}->{$comp}->{total} == 0 && $self->{components}->{$comp}->{skip} == 0);
        $total_components += $self->{components}->{$comp}->{total} + $self->{components}->{$comp}->{skip};
        $display_by_component .= $display_by_component_append . $self->{components}->{$comp}->{total} . '/' . $self->{components}->{$comp}->{skip} . ' ' . $self->{components}->{$comp}->{name};
        $display_by_component_append = ', ';
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All %s components [%s] are ok.", 
                                                     $total_components,
                                                     $display_by_component)
                                );

    if (defined($self->{option_results}->{no_component}) && $total_components == 0) {
        $self->{output}->output_add(severity => $self->{no_components},
                                    short_msg => 'No components are checked.');
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [ 
                                { oid => $oids{connUnitSensorName} },
                                { oid => $oids{connUnitSensorStatus} },
                                { oid => $oids{connUnitSensorMessage} },
                                { oid => $oids{connUnitSensorType} },
                                { oid => $oids{connUnitSensorCharacteristic} },
                                { oid => $oids{connUnitPortName} },
                                { oid => $oids{connUnitPortStatus} },
                                               ]);
    $self->component();

    $self->{output}->display();
    $self->{output}->exit();
}

sub check_exclude {
    my ($self, %options) = @_;

    if (defined($options{instance})) {
        if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)${options{section}}[^,]*#\Q$options{instance}\E#/) {
            $self->{components}->{$options{section}}->{skip}++;
            $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section $options{instance} instance."));
            return 1;
        }
    } elsif (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)$options{section}(\s|,|$)/) {
        $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section."));
        return 1;
    }
    return 0;
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {           
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

sub check_sensors {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking sensors");
    $self->{components}->{sensors} = {name => 'sensors', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'sensors'));
    
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oids{connUnitSensorName}}})) {
        $key =~ /^$oids{connUnitSensorName}\.(.*)/;
        my $instance = $1;
        my $name = $self->{results}->{ $oids{connUnitSensorName} }->{$key};
        my $status = defined($self->{results}->{$oids{connUnitSensorStatus}}->{$oids{connUnitSensorStatus} . '.' . $instance}) ? 
                $self->{results}->{$oids{connUnitSensorStatus}}->{$oids{connUnitSensorStatus} . '.' . $instance} : 1; 
        my $msg = defined($self->{results}->{$oids{connUnitSensorMessage}}->{$oids{connUnitSensorMessage} . '.' . $instance}) ? 
                $self->{results}->{$oids{connUnitSensorMessage}}->{$oids{connUnitSensorMessage} . '.' . $instance} : 1;
        my $type = defined($self->{results}->{$oids{connUnitSensorType}}->{$oids{connUnitSensorType} . '.' . $instance}) ? 
                $self->{results}->{$oids{connUnitSensorType}}->{$oids{connUnitSensorType} . '.' . $instance} : 1;
        my $chara = defined($self->{results}->{$oids{connUnitSensorCharacteristic}}->{$oids{connUnitSensorCharacteristic} . '.' . $instance}) ? 
                $self->{results}->{$oids{connUnitSensorCharacteristic}}->{$oids{connUnitSensorCharacteristic} . '.' . $instance} : 1;        
        
        next if ($self->check_exclude(section => 'sensors', instance => $name));
        
        $self->{components}->{sensors}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Sensor '%s' status is %s [msg = %s] [type = %s] [chara = %s]",
                                                        $name, $map_sensor_status{$status}, $msg, $map_sensor_type{$type}, $map_sensor_chara{$chara}));
        my $exit = $self->get_severity(section => 'sensors', value => $map_sensor_status{$status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Sensor '" . $name . "' status is " . $map_sensor_status{$status});
        }
    }
}

sub check_port {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking ports");
    $self->{components}->{port} = {name => 'ports', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'port'));
    
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oids{connUnitPortName}}})) {
        $key =~ /^$oids{connUnitPortName}\.(.*)/;
        my $instance = $1;
        my $name = $self->{results}->{ $oids{connUnitPortName} }->{$key};
        my $status = defined($self->{results}->{$oids{connUnitPortStatus}}->{$oids{connUnitPortStatus} . '.' . $instance}) ? 
                $self->{results}->{$oids{connUnitPortStatus}}->{$oids{connUnitPortStatus} . '.' . $instance} : 1; 

        next if ($self->check_exclude(section => 'port', instance => $name));
        
        $self->{components}->{port}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Port '%s' status is %s",
                                                        $name, $map_port_status{$status}));
        my $exit = $self->get_severity(section => 'port', value => $map_port_status{$status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Port '" . $name . "' status is " . $map_port_status{$status});
        }
    }
}

1;

__END__

=head1 MODE

Check status of SAN Hardware (Following FibreAlliance MIB: MIB40)
http://www.emc.com/microsites/fibrealliance/index.htm

=over 8

=item B<--component>

Which component to check (Default: 'all').
Can be: 'sensors', 'port'.

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=port)
Can also exclude specific instance: --exclude='sensors#Temperature Loc:upper-IOM A#'

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='sensors,CRITICAL,^(?!(ok)$)'

=back

=cut
