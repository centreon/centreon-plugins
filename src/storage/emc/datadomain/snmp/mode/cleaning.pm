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

package storage::emc::datadomain::snmp::mode::cleaning;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use POSIX;
use DateTime;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_last_exec_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        unit => $self->{instance_mode}->{option_results}->{unit},
        value => $self->{result_values}->{lastExecSeconds} >= 0 ? floor($self->{result_values}->{lastExecSeconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }) : $self->{result_values}->{lastExecSeconds},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_last_exec_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{lastExecSeconds} >= 0 ? floor($self->{result_values}->{lastExecSeconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }) : $self->{result_values}->{lastExecSeconds},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
         { label => 'last-cleaning-execution', nlabel => 'filesystems.cleaning.execution.last', set => {
                key_values  => [ { name => 'lastExecSeconds' }, { name => 'lastExecHuman' } ],
                output_template => 'cleaning last execution: %s',
                output_use => 'lastExecHuman',
                closure_custom_perfdata => $self->can('custom_last_exec_perfdata'),
                closure_custom_threshold_check => $self->can('custom_last_exec_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'unit:s'     => { name => 'unit', default => 'd' },
        'timezone:s' => { name => 'timezone'}
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 'd';
    }
    if (defined($self->{option_results}->{timezone}) && $self->{option_results}->{timezone} ne '' && $self->{option_results}->{timezone} !~ /^[A-Za-z_\/0-9-]+$/) {
        $self->{output}->add_option_msg(short_msg => "Wrong timezone format '" . $self->{option_results}->{timezone} . "'. (Example format: 'America/Los_Angeles')");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    # "Cleaning finished at 2024/08/27 13:58:59."
    my $oid_fileSystemCleanStatus = '.1.3.6.1.4.1.19746.1.3.5.1.1.2';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_fileSystemCleanStatus
    );

    my $ctime = time();

    $self->{global} = { lastExecHuman => 'never', lastExecSeconds => -1 };
    foreach my $oid (keys %$snmp_result) {
        if ($snmp_result->{$oid} =~ /\s+(\d+)\/(\d+)\/(\d+)\s+(\d+):(\d+):(\d+)/) {
            my $dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6);
            # if the equipment check is on another timezone than the system where the plugin is executed.
            if (!centreon::plugins::misc::is_empty($self->{option_results}->{timezone})) {
                eval {
                    $dt = $dt->set_time_zone($self->{option_results}->{timezone});
                };
                if ($@) {
                    $self->{output}->add_option_msg(short_msg => "Invalid timezone provided: '" . $self->{option_results}->{timezone} . "'. Check in /usr/share/zoneinfo for valid time zones.");
                     $self->{output}->option_exit();
                 }
            }
            my $lastExecSeconds = $ctime - $dt->epoch();
            if ($self->{global}->{lastExecSeconds} == -1 || $self->{global}->{lastExecSeconds} > $lastExecSeconds) {
                $self->{global}->{lastExecSeconds} = $lastExecSeconds;
            }
        } elsif ($snmp_result->{$oid} =~ /Cleaning: phase (\d+) of (\d+) \(([^)]+)\)/) {
            $self->{global}->{lastExecHuman} = "running (phase $1 of $2 : $3)";
            $self->{global}->{lastExecSeconds} = 0;
        }
    }

    # If there is a lastExecSeconds set (if above in the looop) and this is not a cleaning running (elsif above)
    if ($self->{global}->{lastExecSeconds} > 0 || ($self->{global}->{lastExecSeconds} == 0 && $self->{global}->{lastExecHuman} eq "never")) {
        $self->{global}->{lastExecHuman} =  centreon::plugins::misc::change_seconds(
            value => $self->{global}->{lastExecSeconds}
        );
    }
}

1;

__END__

=head1 MODE

Check last time filesystems had been cleaned.

=over 8

=item B<--unit>

Select the time unit for thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks (default: 'd').

=item B<--timezone>

Set equipment timezone if different from UTC. Valid time zones can be found in C</usr/share/zoneinfo>.
Format example : Europe/Paris and America/Los_Angeles

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'last-cleaning-execution'.

=back

=cut
