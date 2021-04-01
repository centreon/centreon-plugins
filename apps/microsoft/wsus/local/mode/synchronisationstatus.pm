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

package apps::microsoft::wsus::local::mode::synchronisationstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use JSON::XS;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use centreon::plugins::misc;
use centreon::common::powershell::wsus::synchronisationstatus;
use DateTime;

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("status is '%s'", $self->{result_values}->{status});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_SynchronizationStatus'};
    return 0;
}

sub custom_last_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("status is '%s'", $self->{result_values}->{status});
    return $msg;
}

sub custom_last_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_LastSynchronizationResult'};
    return 0;
}

sub custom_progress_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => 'synchronisation_progress',
        value => $self->{result_values}->{progress},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}),
        min => 0, max => 100
    );
}

sub custom_progress_threshold {
    my ($self, %options) = @_;
    
    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{progress},
                                                  threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' },
                                                                 { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_progress_output {
    my ($self, %options) = @_;

    return sprintf("Progress: %.2f%% (%d/%d items)",
        $self->{result_values}->{progress},
        $self->{result_values}->{processed},
        $self->{result_values}->{total}
    );
}

sub custom_progress_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{processed} = $options{new_datas}->{$self->{instance} . '_ProcessedItems'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_TotalItems'};
    $self->{result_values}->{progress} = 0;
    return 0 if ($self->{result_values}->{total} == 0);

    $self->{result_values}->{progress} = $self->{result_values}->{processed} * 100 / $self->{result_values}->{total};

    return 0;
}

sub custom_duration_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => 'last_synchronisation_duration',
        value => $self->{result_values}->{duration},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}),
        min => 0, unit => 's'
    );
}

sub custom_duration_threshold {
    my ($self, %options) = @_;
    
    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{duration},
                                                  threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' },
                                                                 { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_duration_output {
    my ($self, %options) = @_;

    return sprintf('Duration: %s',  centreon::plugins::misc::change_seconds(value => $self->{result_values}->{duration}));
}

sub custom_duration_calc {
    my ($self, %options) = @_;

    my $start_time = $options{new_datas}->{$self->{instance} . '_LastSynchronizationStartTime'};
    my $end_time = $options{new_datas}->{$self->{instance} . '_LastSynchronizationEndTime'};
    
    # 2019-03-21T13:00:13
    my $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
    $start_time =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)$/;
    my $start_time_dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6, %$tz);
    $end_time =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)$/;
    my $end_time_dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6, %$tz);
    
    $self->{result_values}->{duration} = $end_time_dt->epoch - $start_time_dt->epoch;
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'current', type => 0, cb_prefix_output => 'prefix_output_current' },
        { name => 'last', type => 0, cb_prefix_output => 'prefix_output_last' },
    ];

    $self->{maps_counters}->{current} = [
        { label => 'synchronisation-status', threshold => 0, set => {
                key_values => [ { name => 'SynchronizationStatus' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'synchronisation-progress', set => {
                key_values => [ { name => 'TotalItems' }, { name => 'ProcessedItems' } ],
                closure_custom_calc => $self->can('custom_progress_calc'),
                closure_custom_output => $self->can('custom_progress_output'),
                closure_custom_perfdata => $self->can('custom_progress_perfdata'),
                closure_custom_threshold_check => $self->can('custom_progress_threshold'),
            }
        },
    ];
    $self->{maps_counters}->{last} = [
        { label => 'last-synchronisation-status', threshold => 0, set => {
                key_values => [ { name => 'LastSynchronizationResult' } ],
                closure_custom_calc => $self->can('custom_last_status_calc'),
                closure_custom_output => $self->can('custom_last_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'last-synchronisation-duration', set => {
                key_values => [ { name => 'LastSynchronizationStartTime' }, { name => 'LastSynchronizationEndTime' } ],
                closure_custom_calc => $self->can('custom_duration_calc'),
                closure_custom_output => $self->can('custom_duration_output'),
                closure_custom_perfdata => $self->can('custom_duration_perfdata'),
                closure_custom_threshold_check => $self->can('custom_duration_threshold'),
            }
        },
    ];
}

sub prefix_output_current {
    my ($self, %options) = @_;

    return "Current Synchronisation ";
}

sub prefix_output_last {
    my ($self, %options) = @_;

    return "Last Synchronisation ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'timeout:s'         => { name => 'timeout', default => 30 },
        'command:s'         => { name => 'command', default => 'powershell.exe' },
        'command-path:s'    => { name => 'command_path' },
        'command-options:s' => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
        'no-ps'             => { name => 'no_ps' },
        'ps-exec-only'      => { name => 'ps_exec_only' },
        'ps-display'        => { name => 'ps_display' },
        'wsus-server:s'     => { name => 'wsus_server', default => 'localhost' },
        'wsus-port:s'       => { name => 'wsus_port', default => 8530 },
        'use-ssl'           => { name => 'use_ssl' },
        'timezone:s'        => { name => 'timezone', default => 'UTC' },
        'warning-synchronisation-status:s'       => { name => 'warning_synchronisation_status', default => '' },
        'critical-synchronisation-status:s'      => { name => 'critical_synchronisation_status', default => '' },
        'warning-last-synchronisation-status:s'  => { name => 'warning_last_synchronisation_status', default => '' },
        'critical-last-synchronisation-status:s' => { name => 'critical_last_synchronisation_status', default => '%{status} !~ /Succeeded/' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'warning_synchronisation_status', 'critical_synchronisation_status',
        'warning_last_synchronisation_status', 'critical_last_synchronisation_status']
    );
}

sub manage_selection {
    my ($self, %options) = @_;

    my $use_ssl = "\$false";
    $use_ssl = "\$true" if (defined($self->{option_results}->{use_ssl}));

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::wsus::synchronisationstatus::get_powershell(
            wsus_server => $self->{option_results}->{wsus_server},
            wsus_port => $self->{option_results}->{wsus_port},
            use_ssl => $use_ssl
        );
        if (defined($self->{option_results}->{ps_display})) {
            $self->{output}->output_add(
                severity => 'OK',
                short_msg => $ps
            );
            $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
            $self->{output}->exit();
        }

        $self->{option_results}->{command_options} .= " " . centreon::plugins::misc::powershell_encoded($ps);
    }

    my ($stdout) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options}
    );
    if (defined($self->{option_results}->{ps_exec_only})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $stdout
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }
    
    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($stdout);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    $self->{current} = {
        SynchronizationStatus => $decoded->{SynchronizationStatus},
        TotalItems => $decoded->{TotalItems},
        ProcessedItems => $decoded->{ProcessedItems},
    };
    $self->{last} = {
        LastSynchronizationResult => $decoded->{LastSynchronizationResult},
        LastSynchronizationStartTime => $decoded->{LastSynchronizationStartTime},
        LastSynchronizationEndTime => $decoded->{LastSynchronizationEndTime},
    };
}

1;

__END__

=head1 MODE

Check synchronisation status.

=over 8

=item B<--timeout>

Set timeout time for command execution (Default: 30 sec)

=item B<--no-ps>

Don't encode powershell. To be used with --command and 'type' command.

=item B<--command>

Command to get information (Default: 'powershell.exe').
Can be changed if you have output in a file. To be used with --no-ps option.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-InputFormat none -NoLogo -EncodedCommand').

=item B<--ps-display>

Display powershell script.

=item B<--ps-exec-only>

Print powershell output.

=item B<--wsus-server>

Set WSUS hostname/IP (Dafault: localhost).

=item B<--wsus-port>

Set WSUS port (Default: 8530).

=item B<--use-ssl>

Set if WSUS use ssl.

=item B<--warning-synchronisation-status>

Set warning threshold for current synchronisation status (Default: '')
Can used special variables like: %{status}.

=item B<--critical-synchronisation-status>

Set critical threshold for current synchronisation status (Default: '').
Can used special variables like: %{status}.

=item B<--warning-last-synchronisation-status>

Set warning threshold for current synchronisation status (Default: '')
Can used special variables like: %{status}.

=item B<--critical-last-synchronisation-status>

Set critical threshold for current synchronisation status (Default: '%{status} !~ /Succeeded/').
Can used special variables like: %{status}.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'last-synchronisation-duration' (s), 'synchronisation-progress' (%).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=back

=cut
