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

package hardware::devices::eltek::enexus::snmp::mode::load;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output { 
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{status}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'load', type => 0, cb_prefix_output => 'prefix_load_output', skipped_code => { -10 => 1 } },
        { name => 'phase', type => 1, cb_prefix_output => 'prefix_phase_output', message_multiple => 'All phases are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{load} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'current', nlabel => 'load.current.ampere', set => {
                key_values => [ { name => 'current' } ],
                output_template => 'current: %s A',
                perfdatas => [
                    { value => 'current', template => '%s', unit => 'A', min => 0 }
                ]
            }
        },
        { label => 'power', nlabel => 'load.power.watt', display_ok => 0, set => {
                key_values => [ { name => 'power' } ],
                output_template => 'power: %s W',
                perfdatas => [
                    { value => 'power', template => '%s', unit => 'W', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{phase} = [
        { label => 'voltage', nlabel => 'phase.voltage.volt', set => {
                key_values => [ { name => 'voltage' } ],
                output_template => 'voltage: %.2f V',
                perfdatas => [
                    { value => 'voltage', template => '%.2f', unit => 'V', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_load_output {
    my ($self, %options) = @_;

    return 'Load ';
}

sub prefix_phase_output {
    my ($self, %options) = @_;

    return "Phase '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '%{status} =~ /minor|warning/i' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} =~ /error|major|critical/i' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'warning_status', 'critical_status', 'unknown_status',
    ]);
}

my $map_status = {
    0 => 'error', 1 => 'normal', 2 => 'minorAlarm', 3 => 'majorAlarm',
    4 => 'disabled', 5 => 'disconnected', 6 => 'notPresent',
    7 => 'minorAndMajor', 8 => 'majorLow', 9 => 'minorLow',
    10 => 'majorHigh', 11 => 'minorHigh', 12 => 'event',
    13 => 'valueVolt', 14 => 'valueAmp', 15 => 'valueTemp',
    16 => 'valueUnit', 17 => 'valuePerCent', 18 => 'critical',
    19 => 'warning'
};
my $map_decimal_setting = { 0 => 'ampere', 1 => 'deciAmpere' };

my $mapping = {
    powerSystemCurrentDecimalSetting => { oid => '.1.3.6.1.4.1.12148.10.2.15', map => $map_decimal_setting },
    loadStatus                       => { oid => '.1.3.6.1.4.1.12148.10.9.1', map => $map_status },
    loadCurrentValue                 => { oid => '.1.3.6.1.4.1.12148.10.9.2.5' }, # A or dA
    loadCurrentMajorHighLevel        => { oid => '.1.3.6.1.4.1.12148.10.9.2.6' },
    loadCurrentMinorHighLevel        => { oid => '.1.3.6.1.4.1.12148.10.9.2.7' },
    loadEnergyLogAccumulated         => { oid => '.1.3.6.1.4.1.12148.10.9.8.1' }, # Watt
    batteryVoltageValue              => { oid => '.1.3.6.1.4.1.12148.10.10.5.5' } # not sure we should use that value
};

sub threshold_eltek_configured {
    my ($self, %options) = @_;

    if ((!defined($self->{option_results}->{'critical-' . $options{label}}) || $self->{option_results}->{'critical-' . $options{label}} eq '') &&
        (!defined($self->{option_results}->{'warning-' . $options{label}}) || $self->{option_results}->{'warning-' . $options{label}} eq '')) {
        my ($crit, $warn) = ('', '');
        $crit = $options{low_crit} . ':'  if (defined($options{low_crit}) && $options{low_crit} ne '');
        $crit .= $options{high_crit} if (defined($options{high_crit}) && $options{high_crit} ne '');
        $warn = $options{low_warn} . ':'  if (defined($options{low_warn}) && $options{low_warn} ne '');
        $warn .= $options{high_warn} if (defined($options{high_warn}) && $options{high_warn} ne '');
        $self->{perfdata}->threshold_validate(label => 'critical-' . $options{label}, value => $crit);
        $self->{perfdata}->threshold_validate(label => 'warning-' . $options{label}, value => $warn);
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');

    my $scale_current = 1;
    $scale_current = 0.1 if ($result->{powerSystemCurrentDecimalSetting} eq 'deciAmpere');
    $self->{load} = {
        status => $result->{loadStatus},
        power => $result->{loadCurrentValue} * $scale_current * ($result->{batteryVoltageValue} * 0.01),
        current => $result->{loadCurrentValue} * $scale_current
    };

    $self->threshold_eltek_configured(
        label => 'load-current-ampere',
        high_crit => $result->{loadCurrentMajorHighLevel} * $scale_current,
        high_warn => $result->{loadCurrentMinorHighLevel} * $scale_current
    );

    my $oid_loadVoltageValue = '.1.3.6.1.4.1.12148.10.9.9.1.6';
    $snmp_result = $options{snmp}->get_table(oid => $oid_loadVoltageValue);
    $self->{phase} = {};
    foreach (keys %$snmp_result) {
        /\.(\d+)$/;
        $self->{phase}->{$1} = { display => $1, voltage => $snmp_result->{$_} * 0.01 };
    }
}

1;

__END__

=head1 MODE

Check load.

=over 8

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /minor|warning/i').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /error|major|critical/i').
Can used special variables like: %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'current', 'power'.

=back

=cut
