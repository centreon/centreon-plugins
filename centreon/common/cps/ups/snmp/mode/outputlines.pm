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

package centreon::common::cps::ups::snmp::mode::outputlines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("status is '%s'", $self->{result_values}->{status});
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'olines', type => 0, cb_prefix_output => 'prefix_olines_output', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{olines} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'load', nlabel => 'lines.output.load.percentage', set => {
                key_values => [ { name => 'load' } ],
                output_template => 'Load : %.2f %%',
                perfdatas => [
                    { value => 'load', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'current', nlabel => 'lines.output.current.ampere', set => {
                key_values => [ { name => 'current' } ],
                output_template => 'Current : %.2f A',
                perfdatas => [
                    { value => 'current', template => '%.2f', min => 0, unit => 'A' },
                ],
            }
        },
        { label => 'voltage', nlabel => 'lines.output.voltage.volt', set => {
                key_values => [ { name => 'voltage' } ],
                output_template => 'Voltage : %.2f V',
                perfdatas => [
                    { value => 'voltage', template => '%.2f', unit => 'V' },
                ],
            }
        },
        { label => 'power', nlabel => 'lines.output.power.watt', set => {
                key_values => [ { name => 'power' } ],
                output_template => 'Power : %.2f W',
                perfdatas => [
                    { value => 'power', template => '%.2f', min => 0, unit => 'W' },
                ],
            }
        },
        { label => 'frequence', nlabel => 'lines.output.frequence.hertz', set => {
                key_values => [ { name => 'frequence' } ],
                output_template => 'Frequence : %.2f Hz',
                perfdatas => [
                    { value => 'frequence', template => '%.2f', min => 0, unit => 'Hz' },
                ],
            }
        },
    ];
}

sub prefix_olines_output {
    my ($self, %options) = @_;

    return 'Output ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'unknown-status:s'      => { name => 'unknown_status', default => '%{status} =~ /unknown/i' },
        'warning-status:s'      => { name => 'warning_status', default => '%{status} =~ /rebooting|onBattery|onBypass/i' },
        'critical-status:s'     => { name => 'critical_status', default => '' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

my $map_status = { 
    1 => 'unknown', 2 => 'onLine',
    3 => 'onBattery', 4 => 'onBoost',
    5 => 'onSleep', 6 => 'off',
    7 => 'rebooting', 8 => 'onECO',
    9 => 'onBypass', 10 => 'onBuck',
    11 => 'onOverload', 
};

my $mapping = {
    upsBaseOutputStatus         => { oid => '.1.3.6.1.4.1.3808.1.1.1.4.1.1', map => $map_status },
    upsAdvanceOutputVoltage     => { oid => '.1.3.6.1.4.1.3808.1.1.1.4.2.1' }, # in dV
    upsAdvanceOutputFrequency   => { oid => '.1.3.6.1.4.1.3808.1.1.1.4.2.2' }, # in dHz
    upsAdvanceOutputLoad        => { oid => '.1.3.6.1.4.1.3808.1.1.1.4.2.3' }, # in %
    upsAdvanceOutputCurrent     => { oid => '.1.3.6.1.4.1.3808.1.1.1.4.2.4' }, # in dA
    upsAdvanceOutputPower       => { oid => '.1.3.6.1.4.1.3808.1.1.1.4.2.5' }, # in W
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_upsOutput = '.1.3.6.1.4.1.3808.1.1.1.4';
    my $snmp_result = $options{snmp}->get_table(oid => $oid_upsOutput, nothing_quit => 1);
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');

    $self->{olines} = {
        frequence => (defined($result->{upsAdvanceOutputFrequency}) && $result->{upsAdvanceOutputFrequency} =~ /\d/) ? $result->{upsAdvanceOutputFrequency} * 0.1 : undef,
        voltage => (defined($result->{upsAdvanceOutputVoltage}) && $result->{upsAdvanceOutputVoltage} =~ /\d/) ? $result->{upsAdvanceOutputVoltage} * 0.1 : undef,
        current => (defined($result->{upsAdvanceOutputCurrent}) && $result->{upsAdvanceOutputCurrent} =~ /\d/) ? $result->{upsAdvanceOutputCurrent} * 0.1 : undef,
        load => (defined($result->{upsAdvanceOutputLoad}) && $result->{upsAdvanceOutputLoad} =~ /\d/) ? $result->{upsAdvanceOutputLoad} : undef,
        power => (defined($result->{upsAdvanceOutputPower}) && $result->{upsAdvanceOutputPower} =~ /\d/) ? $result->{upsAdvanceOutputPower} : undef,
        status => $result->{upsBaseOutputStatus},
    };
}

1;

__END__

=head1 MODE

Check output lines metrics.

=over 8

=item B<--unknown-status>

Set warning threshold for status (Default: '%{status} =~ /unknown/i').
Can used special variables like: %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /rebooting|onBattery|onBypass/i').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'load', 'voltage', 'current', 'power', 'frequence'.

=back

=cut
