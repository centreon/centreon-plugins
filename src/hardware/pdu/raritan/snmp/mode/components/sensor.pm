#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package hardware::pdu::raritan::snmp::mode::components::sensor;

use strict;
use warnings;
use hardware::pdu::raritan::snmp::mode::components::resources qw($mapping %raritan_type %map_type);

sub load {
    my ($self, %options) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{$options{type} . '_label'}->{Label}->{oid} },
        { oid => $mapping->{$options{type}}->{Unit}->{oid} },
        { oid => $mapping->{$options{type}}->{Decimal}->{oid} },
        { oid => $mapping->{$options{type}}->{EnabledThresholds}->{oid} },
        { oid => $mapping->{$options{type}}->{LowerCriticalThreshold}->{oid} },
        { oid => $mapping->{$options{type}}->{LowerWarningThreshold}->{oid} },
        { oid => $mapping->{$options{type}}->{UpperCriticalThreshold}->{oid} },
        { oid => $mapping->{$options{type}}->{UpperWarningThreshold}->{oid} },
        { oid => $mapping->{$options{type}}->{State}->{oid} },
        { oid => $mapping->{$options{type}}->{Value}->{oid} };

}

sub check {
    my ($self, %options) = @_;

    foreach my $component (sort keys %raritan_type) {
        my $long_msg = 0;
        next if ($component !~ /$options{component}/);
        $self->{components}->{$component} = { name => $component, total => 0, skip => 0 };
        next if ($self->check_filter(section => $component));

        my $instance_type = $raritan_type{$component};
        my $value_type = $map_type{$instance_type};
        foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}})) {

            my ($pduId, $fullSensorId, $result);
            if ($options{type} eq 'external') {
                next if ($oid !~ /^$mapping->{ $options{type} }->{State}->{oid}\./);
                $oid =~ /^$mapping->{ $options{type} }->{State}->{oid}\.(\d+)\.(\d+)$/;
                $pduId = $1;
                $fullSensorId = $1 . '.' . $2;
                next if ($self->{externalSensorType}->{$fullSensorId} != $instance_type);

                $result = $self->{snmp}->map_instance(mapping => $mapping->{$options{type}}, results => $self->{results}, instance => $fullSensorId);
            } else {
                next if ($oid !~ /^$mapping->{ $options{type} }->{State}->{oid}\.(\d+)\.(\d+)\.$instance_type$/);

                $pduId = $1;
                $fullSensorId = $1 . '.' . $2;
                my $fullInstanceId = $1 . '.' . $2 . '.' . $instance_type;
                $result = $self->{snmp}->map_instance(mapping => $mapping->{$options{type}}, results => $self->{results}, instance => $fullInstanceId);
            }

            my $pduName = $self->{pduNames}->{$pduId};
            my $result2 = $self->{snmp}->map_instance(mapping => $mapping->{$options{type} . '_label'}, results => $self->{results}, instance => $fullSensorId);
            my $instance = defined($result2->{Label}) && $result2->{Label} ne '' ? $result2->{Label} : $fullSensorId;

            next if ($self->check_filter(section => $component, instance => $instance));

            if ($long_msg == 0) {
                $self->{output}->output_add(long_msg => "Checking " . $component);
                $long_msg = 1;
            }

            $self->{components}->{$component}->{total}++;

            my $value = (defined($result->{Value}) && $result->{Value} ne '') ? $result->{Value} : '-';
            if ($value =~ /[0-9]/) {
                $value *= 10 ** -int($result->{Decimal});
            }
            $self->{output}->output_add(
                long_msg => sprintf(
                    "'%s' %s state is '%s' [instance: %s, value: %s, unit: %s, label: %s, pdu: %s]", 
                    $instance,
                    $component,
                    $result->{State},
                    $instance,
                    $value,
                    $result->{Unit}->{unit},
                    $result2->{Label},
                    $pduName
                )
            );
            my $exit = $self->get_severity(
                section => $component, label => $value_type, 
                instance => $instance, value => $result->{State}
            );
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf(
                        "'%s' %s state is '%s'", 
                        $instance, $component, $result->{State}
                    )
                );
            }

            next if ($value !~ /[0-9]/);
            next if ($value =~ /^0$/ && $result->{Unit}->{unit} eq '');
    
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => $component, instance => $instance, value => $value);
            if ($checked == 0) {
                $result->{EnabledThresholds} = oct('0b'. unpack('b*', $result->{EnabledThresholds}));
                my $warn_th;
                $warn_th = ($result->{LowerWarningThreshold} * 10 ** -int($result->{Decimal})) . ':' if (($result->{EnabledThresholds} & (1 << 1)));
                if (($result->{EnabledThresholds} & (1 << 2))) {
                    if (defined($warn_th)) {
                        $warn_th .= ($result->{UpperWarningThreshold} * 10 ** -int($result->{Decimal}));
                    } else {
                        $warn_th = '~:' . ($result->{UpperWarningThreshold} * 10 ** -int($result->{Decimal}));
                    }
                }
                my $crit_th;
                $crit_th = ($result->{LowerCriticalThreshold} * 10 ** -int($result->{Decimal})) . ':' if (($result->{EnabledThresholds} & (1 << 0)));
                if (($result->{EnabledThresholds} & (1 << 3))) {
                    if (defined($crit_th)) {
                        $crit_th .= ($result->{UpperCriticalThreshold} * 10 ** -int($result->{Decimal}));
                    } else {
                        $crit_th = '~:' . ($result->{UpperCriticalThreshold} * 10 ** -int($result->{Decimal}));
                    }
                }
                $self->{perfdata}->threshold_validate(label => 'warning-' . $component . '-instance-' . $instance, value => $warn_th);
                $self->{perfdata}->threshold_validate(label => 'critical-' . $component . '-instance-' . $instance, value => $crit_th);
                $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $component . '-instance-' . $instance);
                $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $component . '-instance-' . $instance);
            }

            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit2,
                    short_msg => sprintf(
                        "'%s' %s value is %s %s", 
                        $instance, $component, $value, $result->{Unit}->{unit}
                    )
                );
            }

            my $nunit = (defined($result->{Unit}->{nunit}) ? $result->{Unit}->{nunit} : lc($result->{Unit}->{unit}));

            $self->{output}->perfdata_add(
                nlabel => 'hardware.sensor.' . $options{type} . '.' . lc($component) . '.' . $nunit,
                unit => $result->{Unit}->{unit},
                instances => [$pduName, $instance],
                value => $value,
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;
