#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package database::mongodb::mode::replicationstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

my %mapping_states = (
    0 => 'STARTUP', 1 => 'PRIMARY', 2 => 'SECONDARY',
    3 => 'RECOVERING', 5 => 'STARTUP2', 6 => 'UNKNOWN',
    7 => 'ARBITER', 8 => 'DOWN', 9 => 'ROLLBACK', 10 => 'REMOVED',
);
my %mapping_health = (
    0 => 'down',
    1 => 'up',
);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Current member state is '%s'", $self->{result_values}->{state});
    $msg .= sprintf(", syncing to '%s'", $self->{result_values}->{sync_host}) if ($self->{result_values}->{state} ne 'PRIMARY');

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{state} = $mapping_states{$options{new_datas}->{$self->{instance} . '_myState'}};
    $self->{result_values}->{sync_host} = $options{new_datas}->{$self->{instance} . '_syncSourceHost'};

    return 0;
}

sub custom_member_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("state is '%s' and health is '%s' [slave delay: %s] [priority: %s]",
        $self->{result_values}->{state},
        $self->{result_values}->{health},
        $self->{result_values}->{slave_delay},
        $self->{result_values}->{priority});

    return $msg;
}

sub custom_member_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_stateStr'};
    $self->{result_values}->{slave_delay} = $options{new_datas}->{$self->{instance} . '_slaveDelay'};
    $self->{result_values}->{health} = $mapping_health{$options{new_datas}->{$self->{instance} . '_health'}};
    $self->{result_values}->{priority} = $options{new_datas}->{$self->{instance} . '_priority'};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'members', type => 1, cb_prefix_output => 'prefix_output',
          message_multiple => 'All members statistics are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', set => {
                key_values => [ { name => 'myState' }, { name => 'syncSourceHost' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
    $self->{maps_counters}->{members} = [
        { label => 'member-status', set => {
                key_values => [ { name => 'stateStr' }, { name => 'health' }, { name => 'slaveDelay' },
                    { name => 'priority' }, { name => 'name' } ],
                closure_custom_calc => $self->can('custom_member_status_calc'),
                closure_custom_output => $self->can('custom_member_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'replication-lag', nlabel => 'replication.lag.seconds', set => {
                key_values => [  { name => 'lag' }, { name => 'name' } ],
                output_template => 'Replication Lag: %s s',
                perfdatas => [
                    { value => 'lag_absolute', template => '%d', unit => 's',
                      min => 0, label_extra_instance => 1, instance_use => 'name_absolute' },
                ],
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Member '" . $options{instance_value}->{name} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "warning-status:s"      => { name => 'warning_status', default => '' },
        "critical-status:s"     => { name => 'critical_status', default => '' },
        "warning-member-status:s"      => { name => 'warning_member_status', default => '%{state} !~ /PRIMARY|SECONDARY/' },
        "critical-member-status:s"     => { name => 'critical_member_status', default => '%{health} !~ /up/' },
    });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status',
        'warning_member_status', 'critical_member_status']);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{custom} = $options{custom};

    my $ismaster = $self->{custom}->run_command(
        database => 'admin',
        command => $self->{custom}->ordered_hash('ismaster' => 1),
    );

    if (!defined($ismaster->{me})) {
        $self->{output}->add_option_msg(short_msg => "No replication detected");
        $self->{output}->option_exit();
    }

    $self->{global} = {};
    $self->{members} = {};

    my $repl_conf = $self->{custom}->run_command(
        database => 'admin',
        command => $self->{custom}->ordered_hash('replSetGetConfig' => 1),
    );

    my %config;
    foreach my $member (sort @{$repl_conf->{config}->{members}}) {
        $config{$member->{host}} = { priority => $member->{priority}, slaveDelay => $member->{slaveDelay} }
    }

    my $repl_status = $self->{custom}->run_command(
        database => 'admin',
        command => $self->{custom}->ordered_hash('replSetGetStatus' => 1),
    );

    $self->{global}->{myState} = $repl_status->{myState};
    $self->{global}->{syncSourceHost} = (defined($repl_status->{syncSourceHost})) ? $repl_status->{syncSourceHost} : $repl_status->{syncingTo};
    $self->{global}->{syncSourceHost} = '-' if (!defined($self->{global}->{syncSourceHost}));

    foreach my $member (sort @{$repl_status->{members}}) {
        $self->{members}->{$member->{name}} = {
            name => $member->{name},
            stateStr => $member->{stateStr},
            health => $member->{health},
            optimeDate => $member->{optime}->{ts}->{seconds},
            slaveDelay => $config{$member->{name}}->{slaveDelay},
            priority => $config{$member->{name}}->{priority},
        }
    }

    foreach my $member (keys %{$self->{members}}) {
        next if ($self->{members}->{$member}->{stateStr} !~ /SECONDARY/);
        $self->{members}->{$member}->{lag} = $self->{members}->{$ismaster->{primary}}->{optimeDate} - $self->{members}->{$member}->{optimeDate} - $self->{members}->{$member}->{slaveDelay};
    }

    if (scalar(keys %{$self->{members}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No members found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check replication status

=over 8

=item B<--warning-status>

Set warning threshold for checked instance status (Default: '').
Can used special variables like: %{state}, %{sync_host}.

=item B<--critical-status>

Set critical threshold for checked instance status (Default: '').
Can used special variables like: %{state}, %{sync_host}.

=item B<--warning-member-status>

Set warning threshold for members status (Default: '%{state} !~ /PRIMARY|SECONDARY/').
Can used special variables like: %{name}, %{state}, %{health},
%{slave_delay}, %{priority}.

=item B<--critical-member-status>

Set critical threshold for members status (Default: '%{health} !~ /up/').
Can used special variables like: %{name}, %{state}, %{health},
%{slave_delay}, %{priority}.

=item B<--warning-instance-replication-lag-seconds>

Threshold warning for replication lag between primary and secondary members.
Must not be over 0 (between minus slaveDelay and 0).

=item B<--critical-instance-replication-lag-seconds>

Threshold critical for replication lag between primary and secondary members.
Must not be over 0 (between minus slaveDelay and 0).

=back

=cut
