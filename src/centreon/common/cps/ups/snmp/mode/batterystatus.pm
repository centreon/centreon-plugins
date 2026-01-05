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

package centreon::common::cps::ups::snmp::mode::batterystatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);
use centreon::plugins::misc;
use Time::HiRes qw(time);

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_status_output {
    my ($self, %options) = @_;

    my $output = sprintf('battery status is %s [battery needs replace: %s] - recommended battery life time is %s months',
        $self->{result_values}->{status},
        $self->{result_values}->{replace},
        $self->{result_values}->{battery_life_time},
    );

    if (defined($self->{result_values}->{last_replace_date}) && length($self->{result_values}->{last_replace_date}) > 0) {
        $output .= sprintf(' - last replacement date: %s', $self->{result_values}->{last_replace_date});
    }

    return $output;
}

sub custom_load_output {
    my ($self, %options) = @_;

    return sprintf("charge remaining: %s%% (%s remaining)",
        $self->{result_values}->{charge_remain},
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{minute_remain})
    );
}

sub custom_battery_time_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'time on battery is: %s',
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{battery_time})
    );

    return $msg;
}

sub custom_battery_time_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label    => 'timeon',
        unit     => $self->{instance_mode}->{option_results}->{unit},
        nlabel   => 'battery.timeon.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        value    => sprintf(
            "%.2f",
            $self->{result_values}->{battery_time} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }
        ),
        warning  => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min      => 0
    );
}

sub custom_battery_time_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value     => sprintf(
            "%.2f",
            $self->{result_values}->{battery_time} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }
        ),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-' . $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', threshold => 0, set => {
            key_values                     => [
                { name => 'status' },
                { name => 'replace' },
                { name => 'battery_life_time' },
                { name => 'last_replace_date' }
            ],
            closure_custom_calc            => \&catalog_status_calc,
            closure_custom_output          => $self->can('custom_status_output'),
            closure_custom_perfdata        => sub {return 0;},
            closure_custom_threshold_check => \&catalog_status_threshold,
        }
        },
        { label => 'charge-remaining', nlabel => 'battery.charge.remaining.percent', set => {
            key_values            => [
                { name => 'charge_remain' },
                { name => 'minute_remain' }
            ],
            closure_custom_output => $self->can('custom_load_output'),
            perfdatas             => [
                { value => 'charge_remain', template => '%s', min => 0, max => 100, unit => '%' },
            ],
        }
        },
        { label => 'voltage', nlabel => 'battery.voltage.volt', display_ok => 0, set => {
            key_values      => [ { name => 'voltage', no_value => 0 } ],
            output_template => 'voltage: %s V',
            perfdatas       => [
                { value => 'voltage', template => '%s', unit => 'V' },
            ],
        }
        },
        { label => 'temperature', nlabel => 'battery.temperature.celsius', display_ok => 0, set => {
            key_values      => [ { name => 'temperature', no_value => 0 } ],
            output_template => 'temperature: %s C',
            perfdatas       => [
                { value => 'temperature', template => '%s', unit => 'C' },
            ],
        }
        },
        { label => 'timeon', display_ok => 0, set => {
            key_values                     => [ { name => 'battery_time' } ],
            closure_custom_output          => $self->can('custom_battery_time_output'),
            closure_custom_perfdata        => $self->can('custom_battery_time_perfdata'),
            closure_custom_threshold_check => $self->can('custom_battery_time_threshold')
        }
        },
        { label => 'battery-life-time', nlabel => 'battery.lifetime.month', display_ok => 0, set => {
            key_values      => [ { name => 'battery_life_time', no_value => 0 } ],
            output_template => 'recommended battery life time: %s month',
            perfdatas       => [
                { value => 'battery_life_time', template => '%d', unit => 'M' },
            ],
        }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'unknown-status:s'  => { name => 'unknown_status', default => '%{status} =~ /unknown|notPresent/i' },
        'warning-status:s'  => { name => 'warning_status', default => '%{status} =~ /low/i' },
        'critical-status:s' => { name => 'critical_status', default => '%{replace} =~ /yes/i' },
        'unit:s'            => { name => 'unit', default => 'm' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [ 'unknown_status', 'warning_status', 'critical_status' ]);

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 's';
    }
}

my $map_status = { 1 => 'unknown', 2 => 'normal', 3 => 'low', 4 => 'notPresent' };
my $map_replace_status = {
    1 => 'no', 2 => 'yes'
};

my $mapping = {
    upsBaseBatteryStatus              => { oid => '.1.3.6.1.4.1.3808.1.1.1.2.1.1', map => $map_status },
    upsAdvanceBatteryCapacity         => { oid => '.1.3.6.1.4.1.3808.1.1.1.2.2.1' },
    upsAdvanceBatteryVoltage          => { oid => '.1.3.6.1.4.1.3808.1.1.1.2.2.2' },# in dV
    upsAdvanceBatteryTemperature      => { oid => '.1.3.6.1.4.1.3808.1.1.1.2.2.3' },# in degrees Centigrade
    upsAdvanceBatteryRunTimeRemaining => { oid => '.1.3.6.1.4.1.3808.1.1.1.2.2.4' },
    upsBasicBatteryTimeOnBattery      => { oid => '.1.3.6.1.4.1.3808.1.1.1.2.1.2' },
    upsBasicBatteryLastReplaceDate    => { oid => '.1.3.6.1.4.1.3808.1.1.1.2.1.3' },
    upsAdvanceBatteryAgeRecommand     => { oid => '.1.3.6.1.4.1.3808.1.1.1.2.1.4' },
    upsAdvanceBatteryReplaceIndicator => { oid => '.1.3.6.1.4.1.3808.1.1.1.2.2.5', map => $map_replace_status }
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_upsBattery = '.1.3.6.1.4.1.3808.1.1.1.2';
    my $snmp_result = $options{snmp}->get_table(oid => $oid_upsBattery, nothing_quit => 1);
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');

    $self->{global} = {
        voltage           =>
            (defined($result->{upsAdvanceBatteryVoltage}) && $result->{upsAdvanceBatteryVoltage} =~ /\d/) ?
                $result->{upsAdvanceBatteryVoltage} * 0.1 :
                0,
        temperature       =>
            $result->{upsAdvanceBatteryTemperature},
        minute_remain     =>
            (defined($result->{upsAdvanceBatteryRunTimeRemaining}) && $result->{upsAdvanceBatteryRunTimeRemaining} =~ /\d/) ?
                $result->{upsAdvanceBatteryRunTimeRemaining} / 100 :
                'unknown',
        charge_remain     =>
            (defined($result->{upsAdvanceBatteryCapacity}) && $result->{upsAdvanceBatteryCapacity} =~ /\d/) ?
                $result->{upsAdvanceBatteryCapacity} :
                undef,
        status            =>
            $result->{upsBaseBatteryStatus},
        replace           =>
            (defined($result->{upsAdvanceBatteryReplaceIndicator})) ?
                $result->{upsAdvanceBatteryReplaceIndicator} :
                'n/a',
        battery_life_time =>
            (defined($result->{upsAdvanceBatteryAgeRecommand}) && $result->{upsAdvanceBatteryAgeRecommand} =~ /\d/) ?
                $result->{upsAdvanceBatteryAgeRecommand} :
                'unknown',
        last_replace_date => $result->{upsBasicBatteryLastReplaceDate},
        battery_time      =>
            (defined($result->{upsBasicBatteryTimeOnBattery}) && $result->{upsBasicBatteryTimeOnBattery} =~ /\d/) ?
                $result->{upsBasicBatteryTimeOnBattery} / 100 :
                'unknown',
    };
}

1;

__END__

=head1 MODE

Check battery status and charge remaining.

=over 8

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{status} =~ /unknown|notPresent/i').
You can use the following variables: %{status}, %{replace}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /low/i').
You can use the following variables: %{status}, %{replace}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{replace} =~ /yes/i').
You can use the following variables: %{status}, %{replace}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: C<charge-remaining> (%), C<voltage> (V), C<temperature> (C), C<timeon> (unit), C<battery-life-time> in months.

=item B<--unit>

Select the time unit for thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=back

=cut
