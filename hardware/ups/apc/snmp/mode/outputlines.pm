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

package hardware::ups::apc::snmp::mode::outputlines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;
    
    return sprintf("output status is '%s'", $self->{result_values}->{status});
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
         { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'load', set => {
                key_values => [ { name => 'load' } ],
                output_template => 'load: %s %%',
                perfdatas => [
                    { label => 'load', value => 'load', template => '%s', 
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'current', set => {
                key_values => [ { name => 'current' } ],
                output_template => 'current: %s A',
                perfdatas => [
                    { label => 'current', value => 'current', template => '%s', 
                      min => 0, unit => 'A' },
                ],
            }
        },
        { label => 'voltage', set => {
                key_values => [ { name => 'voltage' } ],
                output_template => 'voltage: %s V',
                perfdatas => [
                    { label => 'voltage', value => 'voltage', template => '%s', 
                      unit => 'V' },
                ],
            }
        },
        { label => 'frequence', set => {
                key_values => [ { name => 'frequency' } ],
                output_template => 'frequence: %s Hz',
                perfdatas => [
                    { label => 'frequence', value => 'frequency', template => '%s', 
                      unit => 'Hz' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'unknown-status:s'  => { name => 'unknown_status', default => '%{status} =~ /unknown/i' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} !~ /onLine|rebooting/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
}

my $map_status = {
    1 => 'unknown', 2 => 'onLine', 3 => 'onBattery', 4 => 'onSmartBoost',
    5 => 'timedSleeping', 6 => 'softwareBypass', 7 => 'off',
    8 => 'rebooting', 9 => 'switchedBypass', 10 => 'hardwareFailureBypass',
    11 => 'sleepingUntilPowerReturn', 12 => 'onSmartTrim',
};

my $mapping = {
    upsBasicOutputStatus     => { oid => '.1.3.6.1.4.1.318.1.1.1.4.1.1', map => $map_status },
    upsAdvOutputVoltage      => { oid => '.1.3.6.1.4.1.318.1.1.1.4.2.1' },
    upsAdvOutputFrequency    => { oid => '.1.3.6.1.4.1.318.1.1.1.4.2.2' },
    upsAdvOutputLoad         => { oid => '.1.3.6.1.4.1.318.1.1.1.4.2.3' },
    upsAdvOutputCurrent      => { oid => '.1.3.6.1.4.1.318.1.1.1.4.2.4' },
    upsHighPrecOutputVoltage   => { oid => '.1.3.6.1.4.1.318.1.1.1.4.3.1' }, # tenths of VAC
    upsHighPrecOutputFrequency => { oid => '.1.3.6.1.4.1.318.1.1.1.4.3.2' }, # tenths of Hz
    upsHighPrecOutputLoad      => { oid => '.1.3.6.1.4.1.318.1.1.1.4.3.3' }, # tenths of percent
    upsHighPrecOutputCurrent   => { oid => '.1.3.6.1.4.1.318.1.1.1.4.3.4' }, # tenths of amperes
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');
    $self->{global} = {
        status => $result->{upsBasicOutputStatus},
        voltage => defined($result->{upsHighPrecOutputVoltage}) && $result->{upsHighPrecOutputVoltage} =~ /\d/ ?
            $result->{upsHighPrecOutputVoltage} * 0.1 : $result->{upsAdvOutputVoltage},
        frequency => defined($result->{upsHighPrecOutputFrequency}) && $result->{upsHighPrecOutputFrequency} =~ /\d/ ?
            $result->{upsHighPrecOutputFrequency} * 0.1 : $result->{upsAdvOutputFrequency},
        load => defined($result->{upsHighPrecOutputLoad}) && $result->{upsHighPrecOutputLoad} =~ /\d/ ?
            $result->{upsHighPrecOutputLoad} * 0.1 : $result->{upsAdvOutputLoad},
        current => defined($result->{upsHighPrecOutputCurrent}) && $result->{upsHighPrecOutputCurrent} =~ /\d/ ?
            $result->{upsHighPrecOutputCurrent} * 0.1 : $result->{upsAdvOutputCurrent},
    };
}

1;

__END__

=head1 MODE

Check output lines.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status|load$'

=item B<--unknown-status>

Set unknown threshold for status (Default: '%{status} =~ /unknown/i').
Can used special variables like: %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /onLine|rebooting/i').
Can used special variables like: %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'load', 'voltage', 'current', 'frequence'.

=back

=cut
