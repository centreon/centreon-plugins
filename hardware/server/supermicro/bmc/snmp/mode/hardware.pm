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

package hardware::server::supermicro::bmc::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(?:sensor)$';

    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {};

    $self->{components_path} = 'hardware::server::supermicro::bmc::snmp::mode::components';
    $self->{components_module} = ['sensor'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_load_components => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{option_results}->{add_name_instance} = 1;

    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(
        oids => $self->{request},
        return_type => 1
    );
}

1;

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'sensor'.

=item B<--filter>

Can also exclude specific instance: --filter=sensor,fan

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--warning>

Set warning threshold (syntax: type,regexp,threshold)
Example: --warning='sensor,.*,30'

=item B<--critical>

Set critical threshold (syntax: type,regexp,threshold)
Example: --critical='sensor,.*,40'

=back

=cut

package hardware::server::supermicro::bmc::snmp::mode::components::sensor;

use strict;
use warnings;
use centreon::plugins::misc;

my $mapping = {
    sensorReading  => { oid => '.1.3.6.1.4.1.21317.1.3.1.2' },
    lncThreshold   => { oid => '.1.3.6.1.4.1.21317.1.3.1.5' },
    lcThreshold    => { oid => '.1.3.6.1.4.1.21317.1.3.1.6' },
    uncThreshold   => { oid => '.1.3.6.1.4.1.21317.1.3.1.8' },
    ucThreshold    => { oid => '.1.3.6.1.4.1.21317.1.3.1.9' },
    sensorIDString => { oid => '.1.3.6.1.4.1.21317.1.3.1.13' }
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, values(%$mapping);
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking sensors");
    $self->{components}->{sensor} = { name => 'sensors', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'sensor'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}})) {
        next if ($oid !~ /^$mapping->{sensorIDString}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => $instance);

        $result->{sensorIDString} = centreon::plugins::misc::trim($result->{sensorIDString});
        next if ($result->{sensorIDString} eq '');
        next if ($result->{sensorReading} =~ /^0\.0+$/ && $result->{lncThreshold} =~ /^0\.0+$/);

        next if ($self->check_filter(section => 'sensor', instance => $instance, name => $result->{sensorIDString}));

        foreach (('sensorReading', 'lncThreshold', 'lcThreshold', 'uncThreshold', 'ucThreshold')) {
            $result->{$_} = $1 if ($result->{$_} =~ /^(\d+)\.0+$/);
        }

        $self->{components}->{sensor}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "sensor '%s' reading is '%s' [instance = %s]",
                $result->{sensorIDString},
                $result->{sensorReading},
                $instance . '#' . $result->{sensorIDString}
            )
        );

        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(
            section => 'sensor',
            instance => $instance,
            name => $result->{sensorIDString},
            value => $result->{sensorReading}
        );
        if ($checked == 0 && $result->{lncThreshold} != 0 && $result->{lcThreshold} != 0 &&
            $result->{uncThreshold} != 0 && $result->{ucThreshold} != 0) {
            my $warn_th = $result->{lncThreshold} . ':' . $result->{uncThreshold};
            my $crit_th = $result->{lcThreshold} . ':' . $result->{ucThreshold};
            $self->{perfdata}->threshold_validate(label => 'warning-sensor-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-sensor-instance-' . $instance, value => $crit_th);

            $exit = $self->{perfdata}->threshold_check(
                value => $result->{sensorReading},
                threshold => [
                    { label => 'critical-sensor-instance-' . $instance, exit_litteral => 'critical' },
                    { label => 'warning-sensor-instance-' . $instance, exit_litteral => 'warning' }
                ]
            );
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-sensor-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-sensor-instance-' . $instance);
        }

        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Sensor '%s' reading is %s",
                    $result->{sensorIDString},
                    $result->{sensorReading}
                )
            );
        }

        $self->{output}->perfdata_add(
            nlabel => 'hardware.sensor.reading.count',
            instances => $result->{sensorIDString},
            value => $result->{sensorReading},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
