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

package apps::microsoft::sccm::local::mode::databasereplicationstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use JSON::XS;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use centreon::common::powershell::sccm::databasereplicationstatus;
use centreon::plugins::misc;
use DateTime;

my %map_link_status = (
    1 => 'Degraded',
    2 => 'Active',
    3 => 'Failed',
);
my %map_status = (
    100 => 'SITE_INSTALLING',
    105 => 'SITE_INSTALL_COMPLETE',
    110 => 'INACTIVE',
    115 => 'INITIALIZING',
    120 => 'MAINTENANCE_MODE',
    125 => 'ACTIVE',
    130 => 'DETACHING',
    135 => 'READY_TO_DETACH',
    199 => 'STATUS_UNKNOWN',
    200 => 'SITE_RECOVERED',
    205 => 'SITE_PREPARE_FOR_RECOVERY',
    210 => 'SITE_PREPARED_FOR_RECOVERY',
    215 => 'REPLCONFIG_REINITIALIZING',
    220 => 'REPLCONFIG_REINITIALIZED',
    225 => 'RECOVERY_IN_PROGRESS',
    230 => 'RECOVERING_DELTAS',
    250 => 'RECOVERY_RETRY',
    255 => 'RECOVERY_FAILED',
);
my %map_type = (
    0 => 'Unknown',
    1 => 'SECONDARY',
    2 => 'PRIMARY',
    4 => 'CAS',
);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("Overall Link status is '%s'", $self->{result_values}->{status});
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_LinkStatus'};
    return 0;
}

sub custom_site_status_output {
    my ($self, %options) = @_;

    return sprintf("status is '%s', Site-to-Site state is '%s' [Type: %s] [Last sync: %s]",
        $self->{result_values}->{status},
        $self->{result_values}->{site_to_site_state},
        $self->{result_values}->{type},
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{last_sync_time})
    );
}

sub custom_site_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_SiteStatus'};
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_SiteType'};
    $self->{result_values}->{site_to_site_state} = $options{new_datas}->{$self->{instance} . '_SiteToSiteGlobalState'};
    $self->{result_values}->{sync_time} = $options{new_datas}->{$self->{instance} . '_SiteToSiteGlobalSyncTime'};

    my $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
    $self->{result_values}->{sync_time} =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)$/;
    my $sync_time = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6, %$tz);

    $self->{result_values}->{last_sync_time} = time() - $sync_time->epoch;
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'sites', type => 1, cb_prefix_output => 'prefix_output_site', message_multiple => 'All sites status are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'link-status', threshold => 0, set => {
                key_values => [ { name => 'LinkStatus' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
    $self->{maps_counters}->{sites} = [
        { label => 'site-status', threshold => 0, set => {
                key_values => [ { name => 'SiteType' }, { name => 'SiteStatus' }, { name => 'SiteToSiteGlobalState' },
                    { name => 'SiteToSiteGlobalSyncTime' } ],
                closure_custom_calc => $self->can('custom_site_status_calc'),
                closure_custom_output => $self->can('custom_site_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_output_site {
    my ($self, %options) = @_;

    return "Site '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'timeout:s'              => { name => 'timeout', default => 30 },
        'command:s'              => { name => 'command', default => 'powershell.exe' },
        'command-path:s'         => { name => 'command_path' },
        'command-options:s'      => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
        'no-ps'                  => { name => 'no_ps' },
        'ps-exec-only'           => { name => 'ps_exec_only' },
        'ps-display'             => { name => 'ps_display' },
        'warning-link-status:s'  => { name => 'warning_link_status', default => '' },
        'critical-link-status:s' => { name => 'critical_link_status', default => '' },
        'warning-site-status:s'  => { name => 'warning_site_status', default => '' },
        'critical-site-status:s' => { name => 'critical_site_status', default => '' },
        'timezone:s'             => { name => 'timezone', default => 'UTC' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'warning_link_status', 'critical_link_status',
        'warning_site_status', 'critical_site_status'
    ]);
}

sub manage_selection {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::sccm::databasereplicationstatus::get_powershell();
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

    if (!defined($decoded->{LinkStatus})) {
        $self->{output}->add_option_msg(short_msg => 'No database replication');
        $self->{output}->option_exit();
    }
    $self->{global}->{LinkStatus} = $map_link_status{$decoded->{LinkStatus}};

    $self->{sites}->{$decoded->{Site1}} = {
        display => $decoded->{Site1},
        SiteType => $map_type{$decoded->{SiteType1}},
        SiteStatus => $map_status{$decoded->{Site1Status}},
        SiteToSiteGlobalState => $decoded->{Site1ToSite2GlobalState},
        SiteToSiteGlobalSyncTime => $decoded->{Site1ToSite2GlobalSyncTime},
    };
    $self->{sites}->{$decoded->{Site2}} = {
        display => $decoded->{Site2},
        SiteType => $map_type{$decoded->{SiteType2}},
        SiteStatus => $map_status{$decoded->{Site2Status}},
        SiteToSiteGlobalState => $decoded->{Site2ToSite1GlobalState},
        SiteToSiteGlobalSyncTime => $decoded->{Site2ToSite1GlobalSyncTime},
    };
}

1;

__END__

=head1 MODE

Check database replication status.

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

=item B<--warning-link-status>

Set warning threshold for current synchronisation status (Default: '')
Can used special variables like: %{status}.

=item B<--critical-link-status>

Set critical threshold for current synchronisation status (Default: '').
Can used special variables like: %{status}.

=item B<--warning-site-status>

Set warning threshold for current synchronisation status (Default: '')
Can used special variables like: %{status}, %{type}, %{site_to_site_state}, %{last_sync_time}.

=item B<--critical-site-status>

Set critical threshold for current synchronisation status (Default: '').
Can used special variables like: %{status}, %{type}, %{site_to_site_state}, %{last_sync_time}.

=back

=cut
