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

package hardware::ups::standard::rfc1628::snmp::mode::alarms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_test_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'test status: %s [detail: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{detail}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'alarms-current', nlabel => 'alarms.current.count', set => {
                key_values => [ { name => 'current_alarms' } ],
                output_template => 'current alarms: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        {
            label => 'test-status',
            type => 2,
            warning_default => '%{status} =~ /doneWarning|aborted/',
            critical_default => '%{status} =~ /doneError/',
            set => {
                key_values => [ { name => 'status' }, { name => 'detail' } ],
                closure_custom_output => $self->can('custom_test_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ]
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'display-alarms' => { name => 'display_alarms' }
    });

    return $self;
}

my $map_test = {
    1 => 'donePass', 2 => 'doneWarning', 3 => 'doneError',
    4 => 'aborted', 5 => 'inProgress', 6 => 'noTestsInitiated'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_upsAlarmsPresent = '.1.3.6.1.2.1.33.1.6.1.0';
    my $oid_upsTestResultsSummary = '.1.3.6.1.2.1.33.1.7.3.0';
    my $oid_upsTestResultsDetail = '.1.3.6.1.2.1.33.1.7.4.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [ $oid_upsAlarmsPresent, $oid_upsTestResultsSummary, $oid_upsTestResultsDetail ],
        nothing_quit => 1
    );

    $self->{global} = {
        current_alarms => $snmp_result->{$oid_upsAlarmsPresent}
    };
    if (defined($snmp_result->{$oid_upsTestResultsSummary}) && defined($map_test->{ $snmp_result->{$oid_upsTestResultsSummary} })) {
        $self->{global}->{status} = $map_test->{ $snmp_result->{$oid_upsTestResultsSummary} };
        $self->{global}->{detail} = defined($snmp_result->{$oid_upsTestResultsDetail}) && $snmp_result->{$oid_upsTestResultsDetail} ne '' ?
            $snmp_result->{$oid_upsTestResultsDetail} : '-';
    }

    if ($snmp_result->{$oid_upsAlarmsPresent} > 0) {
        my $oid_upsAlarmEntry = '.1.3.6.1.2.1.33.1.6.2.1';
        my $oid_upsAlarmDescr = '.1.3.6.1.2.1.33.1.6.2.1.2';
        my $oid_upsAlarmTime = '.1.3.6.1.2.1.33.1.6.2.1.3';

        $snmp_result = $options{snmp}->get_table(oid => $oid_upsAlarmEntry);
        foreach my $oid (keys %$snmp_result) {
            next if ($oid !~ /^$oid_upsAlarmEntry\.(.*)$/);
            if (defined($self->{option_results}->{display_messages})) {
                $self->{output}->output_add(
                    long_msg => sprintf(
                        'alarm [date: %s]: %s',
                        $snmp_result->{$oid_upsAlarmTime . '.' . $1},
                        $snmp_result->{$oid_upsAlarmDescr . '.' . $1}
                    )
                );
            }
        }
    }
}

1;

__END__

=head1 MODE

Check current alarms.

=over 8

=item B<--display-alarms>

Display alarms in verbose output.

=item B<--unknown-test-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{detail}

=item B<--warning-test-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /doneWarning|aborted/').
You can use the following variables: %{status}, %{detail}

=item B<--critical-test-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /doneError/').
You can use the following variables: %{status}, %{detail}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'alarms-current'.

=back

=cut
