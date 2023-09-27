#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package hardware::ups::ees::snmp::mode::temperature;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub status_custom_output {
    my ($self, %options) = @_;

    return sprintf(
        "alarm status %s [type: %s]",
        $self->{result_values}->{alarm_status},
        $self->{result_values}->{type}
    );
}

sub prefix_temperature_output {
    my ($self, %options) = @_;

    return "Probe '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'temperatures', type => 1, cb_prefix_output => 'prefix_temperature_output', message_multiple => 'All temperatures are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{temperatures} = [
        {
            label            => 'alarm-status',
            unknown_default  => '%{alarm_status} =~ /fail/i',
            warning_default  => '%{alarm_status} =~ /low/i',
            critical_default => '%{alarm_status} =~ /high/i',
            type             => 2,
            set              => {
                key_values                     => [
                    { name => 'alarm_status' }, { name => 'type' }, { name => 'name' }
                ],
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
                closure_custom_perfdata        => sub {return 0;},
                closure_custom_output          => $self->can('status_custom_output')
            }
        },
        {
            label => 'temperature', nlabel => 'probe.temperature.celsius',
            set   => {
                key_values      => [ { name => 'temperature' }, { name => 'name' } ],
                output_template => 'temperature: %.2fC',
                perfdatas       => [ { template => '%.2f', unit => 'C', label_extra_instance => 1, instance_use => 'name' } ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    return $self;
}

my $map_alarm_status = {
    0 => 'high',
    1 => 'low',
    2 => 'fail',
    3 => 'none'
};

my $map_type = {
    0 => 'none',
    1 => 'ambient',
    2 => 'battery'
};

my $mapping = {
    temperature  => { oid => '.1.3.6.1.4.1.6302.2.1.2.7.3.1.2' },
    alarm_status => { oid => '.1.3.6.1.4.1.6302.2.1.2.7.3.1.5', map => $map_alarm_status },
    name         => { oid => '.1.3.6.1.4.1.6302.2.1.2.7.3.1.3' },
    type         => { oid => '.1.3.6.1.4.1.6302.2.1.2.7.3.1.4', map => $map_type }
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids         => [
            { oid => $mapping->{temperature}->{oid} },
            { oid => $mapping->{alarm_status}->{oid} },
            { oid => $mapping->{name}->{oid} },
            { oid => $mapping->{type}->{oid} }
        ],
        return_type  => 1,
        nothing_quit => 1
    );

    $self->{temperatures} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{temperature}->{oid}\.(.*)$/);
        my $instance = $1;
        my $data = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $self->{temperatures}->{$instance} = {
            temperature  => $data->{temperature} / 1000,
            alarm_status => $data->{alarm_status},
            name         => $data->{name},
            type         => $data->{type}
        };
    }
}

1;

__END__

=head1 MODE

Check temperature.

=over 8

=item B<--unknown-alarm-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{alarm_status} =~ /fail/i').
You can use the following variables: %{alarm_status}, %{type}, %{name}

=item B<--warning-alarm-status>

Define the conditions to match for the status to be WARNING (default: '%{alarm_status} =~ /low/i').
You can use the following variables: %{alarm_status}, %{type}, %{name}

=item B<--critical-alarm-status>

Define the conditions to match for the status to be CRITICAL (default: '%{alarm_status} =~ /high/i').
You can use the following variables: %{alarm_status}, %{type}, %{name}

=item B<--warning-temperature> B<--critical-temperature>

Thresholds: temperature (C)

=back

=cut
