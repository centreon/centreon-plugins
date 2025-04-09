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

package centreon::common::cisco::standard::snmp::mode::configuration;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

sub custom_status_output {
    my ($self, %options) = @_;

    return $self->{result_values}->{output_message};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { 
            label => 'config-running-ahead', nlabel => 'configuration.running.ahead.since.seconds',
            set => {
                key_values => [ { name => 'running_ahead' }, { name => 'output_message' } ],
                closure_custom_output => $self->can('custom_status_output'),
                perfdatas => [
                    { template => '%s', min => 0, unit => 's' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_ccmHistoryRunningLastChanged = '.1.3.6.1.4.1.9.9.43.1.1.1.0';
    my $oid_ccmHistoryRunningLastSaved = '.1.3.6.1.4.1.9.9.43.1.1.2.0';
    my $oid_ccmHistoryStartupLastChanged = '.1.3.6.1.4.1.9.9.43.1.1.3.0';
    my $oid_sysUpTime = '.1.3.6.1.2.1.1.3.0';
    my $oid_snmpEngineTime = '.1.3.6.1.6.3.10.2.1.3.0';

    my $ctime = time();
    my $runningChangedMarginAfterReload = 300;

    my $results = $options{snmp}->get_leef(
        oids => [
            $oid_ccmHistoryRunningLastChanged,
            $oid_ccmHistoryRunningLastSaved,
            $oid_ccmHistoryStartupLastChanged,
            $oid_sysUpTime,
            $oid_snmpEngineTime
        ],
        nothing_quit => 1
    );

    my $uptime = defined($results->{$oid_snmpEngineTime}) ? $results->{$oid_snmpEngineTime} : ($results->{$oid_sysUpTime} / 100);

    my $start_time = $ctime - $uptime;
    my $ccmHistoryRunningLastChanged = $start_time + ($results->{$oid_ccmHistoryRunningLastChanged} / 100);
    my $ccmHistoryRunningLastSaved   = $start_time + ($results->{$oid_ccmHistoryRunningLastSaved} / 100);
    my $ccmHistoryStartupLastChanged = $start_time + ($results->{$oid_ccmHistoryStartupLastChanged} / 100);

    $self->{output}->output_add(long_msg => sprintf(
        "ccmHistoryRunningLastChanged: %s (%s)",
        $ccmHistoryRunningLastChanged,
        scalar(localtime($ccmHistoryRunningLastChanged)))
    );
    $self->{output}->output_add(long_msg => sprintf(
        "ccmHistoryRunningLastSaved: %s (%s)",
        $ccmHistoryRunningLastSaved,
        scalar(localtime($ccmHistoryRunningLastSaved)))
    );
    $self->{output}->output_add(long_msg => sprintf(
        "ccmHistoryStartupLastChanged: %s (%s)",
        $ccmHistoryStartupLastChanged,
        scalar(localtime($ccmHistoryStartupLastChanged)))
    );

    my $runningUnchangedDuration = $ctime - $ccmHistoryRunningLastChanged;
    my $startupUnchangedDuration = $ctime - $ccmHistoryStartupLastChanged;

    my $runningAhead = 0;
    my $output = 'saved config is up to date';
    if ($runningUnchangedDuration < $startupUnchangedDuration) {
        if (($runningUnchangedDuration + $runningChangedMarginAfterReload) > $uptime) {
            $output = sprintf("running config has not changed since reload (using a %d second margin)", $runningChangedMarginAfterReload);
        } else {
            $output = sprintf(
                "running config is ahead of startup config since %s. changes will be lost in case of a reboot",
                centreon::plugins::misc::change_seconds(value => $runningUnchangedDuration)
            );
            $runningAhead = $runningUnchangedDuration;
        }
    }

    $self->{global} = {
        output_message => $output,
        running_ahead => $runningAhead
    }
}

1;

__END__

=head1 MODE

Check Cisco changed and saved configurations (CISCO-CONFIG-MAN-MIB).

=over 8

=item B<--warning-config-running-ahead> 

Thresholds.

=item B<--critical-config-running-ahead>

Thresholds.

=back

=cut
    
