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

package hardware::ats::eaton::snmp::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output { 
    my ($self, %options) = @_;

    my $msg = 'operation mode : ' . $self->{result_values}->{operation_mode};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{operation_mode} = $options{new_datas}->{$self->{instance} . '_operation_mode'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'operation_mode' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'temperature', nlabel => 'system.temperature.celsius', set => {
                key_values => [ { name => 'temperature' } ],
                output_template => 'temperature : %s C',
                perfdatas => [
                    { label => 'temperature', value => 'temperature', template => '%s',
                      unit => 'C' },
                ],
            }
        },
        { label => 'humidity', nlabel => 'system.humidity.percentage', set => {
                key_values => [ { name => 'humidity' } ],
                output_template => 'humidity : %s %%',
                perfdatas => [
                    { label => 'humidity', value => 'humidity', template => '%s',
                      unit => '%', min => 9, max => 100 },
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
        "unknown-status:s"  => { name => 'unknown_status', default => '' },
        "warning-status:s"  => { name => 'warning_status', default => '' },
        "critical-status:s" => { name => 'critical_status', default => '%{operation_mode} !~ /source1|source2/i' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
}

my $map_opmode = {
    1 => 'initialization',
    2 => 'diagnosis',
    3 => 'off',
    4 => 'source1',
    5 => 'source2',
    6 => 'safe',
    7 => 'fault',
};
my $oid_ats2OperationMode = '.1.3.6.1.4.1.534.10.2.2.4.0';
my $oid_ats2EnvRemoteTemp = '.1.3.6.1.4.1.534.10.2.5.1.0';
my $oid_ats2EnvRemoteHumidity = '.1.3.6.1.4.1.534.10.2.5.2.0';
my $oid_atsMeasureTemperatureC = '.1.3.6.1.4.1.534.10.1.3.3.0';
my $oid_atsMessureOperationMode = '.1.3.6.1.4.1.534.10.1.3.7.0';

sub check_ats2 {
    my ($self, %options) = @_;

    return if (!defined($options{result}->{$oid_ats2OperationMode}));

    $self->{global} = {
        operation_mode => $map_opmode->{$options{result}->{$oid_ats2OperationMode}},
        temperature => $options{result}->{$oid_ats2EnvRemoteTemp},
        humidity => $options{result}->{$oid_ats2EnvRemoteHumidity}
    };
}

sub check_ats {
    my ($self, %options) = @_;

    return if (defined($self->{global}));

    $self->{global} = {
        operation_mode => $map_opmode->{$options{result}->{$oid_atsMessureOperationMode}},
        temperature => $options{result}->{$oid_atsMeasureTemperatureC},
    };
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(oids => [
        $oid_ats2OperationMode, $oid_ats2EnvRemoteTemp, $oid_ats2EnvRemoteHumidity,
        $oid_atsMeasureTemperatureC, $oid_atsMessureOperationMode,
    ], nothing_quit => 1);
    $self->check_ats2(result => $snmp_result);
    $self->check_ats(result => $snmp_result);
}

1;

__END__

=head1 MODE

Check system (operation mode, temperature).

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--unknown-status>

Set warning threshold for status (Default: '').
Can used special variables like: operation_mode

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: operation_mode

=item B<--critical-status>

Set critical threshold for status (Default: '%{operation_mode} !~ /source1|source2/i').
Can used special variables like: %{operation_mode}

=item B<--warning-*>

Threshold warning.
Can be: 'temperature', 'humidity'.

=item B<--critical-*>

Threshold critical.
Can be: 'temperature', 'humidity'.

=back

=cut
