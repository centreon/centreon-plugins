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

package snmp_standard::mode::hardwarefibrealliance;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        unit => [
            ['unknown', 'UNKNOWN'],
            ['unused', 'OK'],
            ['warning', 'WARNING'],
            ['failed', 'CRITICAL'],
            ['ok', 'OK']
        ],
        sensors => [
            ['unknown', 'UNKNOWN'],
            ['other', 'UNKNOWN'],
            ['warning', 'WARNING'],
            ['failed', 'CRITICAL'],
            ['ok', 'OK']
        ],
        port => [
            ['warning', 'WARNING'],
            ['failure', 'CRITICAL'],
            ['unused', 'OK'],
            ['initializing', 'OK'],
            ['ready', 'OK'],
            ['.*', 'UNKNOWN']
        ]
    };

    $self->{components_path} = 'snmp_standard::mode::components';
    $self->{components_module} = ['sensors', 'port', 'unit'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(
        package => __PACKAGE__, %options, 
        no_absent => 1, no_performance => 1, no_load_components => 1, force_new_perfdata => 1
    );
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

1;

=head1 MODE

Check status of SAN Hardware (Following FibreAlliance MIB: MIB40)
http://www.emc.com/microsites/fibrealliance/index.htm

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'unit', 'sensors', 'port'.

=item B<--add-name-instance>

Add literal description for instance value (used in filter, and threshold options).

=item B<--filter>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --filter=sensors,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='sensors,CRITICAL,^(?!(ok)$)'

=back

=cut

package snmp_standard::mode::components::sensors;

use strict;
use warnings;

my %map_sensor_status = (
    1 => 'unknown', 2 => 'other',
    3 => 'ok', 4 => 'warning',
    5 => 'failed',
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

my $mapping = {
    connUnitSensorName            => { oid => '.1.3.6.1.3.94.1.8.1.3' },
    connUnitSensorStatus          => { oid => '.1.3.6.1.3.94.1.8.1.4', map => \%map_sensor_status },
    connUnitSensorMessage         => { oid => '.1.3.6.1.3.94.1.8.1.6' },
    connUnitSensorType            => { oid => '.1.3.6.1.3.94.1.8.1.7', map => \%map_sensor_type },
    connUnitSensorCharacteristic  => { oid => '.1.3.6.1.3.94.1.8.1.8', map => \%map_sensor_chara },
};
my $oid_connUnitSensorEntry = '.1.3.6.1.3.94.1.8.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_connUnitSensorEntry, start => $mapping->{connUnitSensorName}->{oid}, end => $mapping->{connUnitSensorCharacteristic}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking sensors");
    $self->{components}->{sensors} = { name => 'sensors', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'sensors'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_connUnitSensorEntry}})) {
        next if ($oid !~ /^$mapping->{connUnitSensorName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_connUnitSensorEntry}, instance => $instance);     
        
        next if ($self->check_filter(section => 'sensors', instance => $instance, name => $result->{connUnitSensorName}));
        
        $self->{components}->{sensors}->{total}++;
        $self->{output}->output_add(long_msg => sprintf(
            "sensor '%s' status is %s [msg: %s] [type: %s] [chara: %s]",
            $result->{connUnitSensorName}, $result->{connUnitSensorStatus},
            $result->{connUnitSensorMessage}, $result->{connUnitSensorType}, $result->{connUnitSensorCharacteristic})
        );
        my $exit = $self->get_severity(section => 'sensors', name => $result->{connUnitSensorName}, value => $result->{connUnitSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Sensor '%s' status is %s",
                    $result->{connUnitSensorName},
                    $result->{connUnitSensorStatus}
                )
            );
        }
    }
}

package snmp_standard::mode::components::port;

use strict;
use warnings;

my %map_port_status = (
    1 => 'unknown', 2 => 'unused',
    3 => 'ready', 4 => 'warning', 
    5 => 'failure', 6 => 'notparticipating', 
    7 => 'initializing', 8 => 'bypass', 
    9 => 'ols', 10 => 'other', 
);

my $mapping_port = {
    connUnitPortName    => { oid => '.1.3.6.1.3.94.1.10.1.17' },
    connUnitPortStatus  => { oid => '.1.3.6.1.3.94.1.10.1.7', map => \%map_port_status },
};

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $mapping_port->{connUnitPortName}->{oid} }, { oid => $mapping_port->{connUnitPortStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking ports");
    $self->{components}->{port} = { name => 'ports', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'port'));
    
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $mapping_port->{connUnitPortName}->{oid} }})) {
        $key =~ /^$mapping_port->{connUnitPortName}->{oid}\.(.*)/;
        my $instance = $1;
        my $name = $self->{results}->{ $mapping_port->{connUnitPortName}->{oid} }->{$key};
        my $result = $self->{snmp}->map_instance(mapping => $mapping_port, results => $self->{results}->{ $mapping_port->{connUnitPortStatus}->{oid} }, instance => $instance);

        next if ($self->check_filter(section => 'port', instance => $instance, name => $name));

        $self->{components}->{port}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "port '%s' status is %s",
                $name, $result->{connUnitPortStatus}
            )
        );
        my $exit = $self->get_severity(section => 'port', name => $name, value => $result->{connUnitPortStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Port '%s' status is %s",
                    $name,
                    $result->{connUnitPortStatus}
                )
            );
        }
    }
}

package snmp_standard::mode::components::unit;

use strict;
use warnings;

my $map_unit_status = {
    1 => 'unknown', 2 => 'unused', 3 => 'ok', 4 => 'warning', 5 => 'failed'
};
my $map_unit_type = {
    1 => 'unknown', 2 => 'other', 3 => 'hub', 4 => 'switch', 5 => 'gateway', 
    6 => 'converter', 7 => 'hba', 8 => 'proxy-agent', 9 => 'storage-device', 
    10 => 'host', 11 => 'storage-subsystem', 12 => 'module', 13 => 'swdriver', 
    14 => 'storage-access-device', 15 => 'wdm', 16 => 'ups', 17 => 'nas'
};

my $mapping_unit = {
    connUnitType   => { oid => '.1.3.6.1.3.94.1.6.1.3', map => $map_unit_type },
    connUnitStatus => { oid => '.1.3.6.1.3.94.1.6.1.6', map => $map_unit_status },
    connUnitName   => { oid => '.1.3.6.1.3.94.1.6.1.20' }
};

sub load {
    my ($self) = @_;

    push @{$self->{request}},
        { oid => $mapping_unit->{connUnitType}->{oid} },
        { oid => $mapping_unit->{connUnitStatus}->{oid} },
        { oid => $mapping_unit->{connUnitName}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking units");
    $self->{components}->{unit} = { name => 'units', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'unit'));

    my $results = {
        %{$self->{results}->{ $mapping_unit->{connUnitType}->{oid} }},
        %{$self->{results}->{ $mapping_unit->{connUnitStatus}->{oid} }},
        %{$self->{results}->{ $mapping_unit->{connUnitName}->{oid} }},
    };
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$results)) {
        next if ($key !~ /^$mapping_unit->{connUnitName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_unit, results => $results, instance => $instance);
        my $name = $result->{connUnitType} . '.' . $result->{connUnitName};

        next if ($self->check_filter(section => 'unit', instance => $instance, name => $name));

        $self->{components}->{unit}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "unit '%s' status is %s",
                $name, $result->{connUnitStatus}
            )
        );
        my $exit = $self->get_severity(section => 'unit', instance => $instance, name => $name, value => $result->{connUnitStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Unit '%s' status is %s",
                    $name,
                    $result->{connUnitStatus}
                )
            );
        }
    }
}
