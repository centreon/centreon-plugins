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

package apps::microsoft::sccm::local::mode::sitestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use JSON::XS;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use centreon::plugins::misc;
use centreon::common::powershell::sccm::sitestatus;

my %map_mode = (
    0 => 'Unknown',
    1 => 'Replication maintenance',
    2 => 'Recovery in progress',
    3 => 'Upgrade in progress',
    4 => 'Evaluation has expired',
    5 => 'Site expansion in progress',
    6 => 'Interop mode where there are primary sites, having the same version as the CAS, were not upgraded',
    7 => 'Interop mode where there are secondary sites, having the same version as the top-level site server, were not upgraded',
);
my %map_status = (
    0 => 'Unknown',
    1 => 'ACTIVE',
    2 => 'PENDING',
    3 => 'FAILED',
    4 => 'DELETED',
    5 => 'UPGRADE',
    6 => 'Failed to delete or deinstall the secondary site',
    7 => 'Failed to upgrade the secondary site',
    8 => 'Secondary site recovery is in progress',
    9 => 'Failed to recover secondary site',
);
my %map_type = (
    0 => 'Unknown',
    1 => 'SECONDARY',
    2 => 'PRIMARY',
    4 => 'CAS',
);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("status is '%s' [Type: %s] [Mode: '%s']",
        $self->{result_values}->{status},
        $self->{result_values}->{type},
        $self->{result_values}->{mode}
    );
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_SiteName'};
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_Type'};
    $self->{result_values}->{mode} = $options{new_datas}->{$self->{instance} . '_Mode'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_Status'};
    $self->{result_values}->{secondary_site_status} = $options{new_datas}->{$self->{instance} . '_SecondarySiteCMUpdateStatus'};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'sites', type => 1, cb_prefix_output => 'prefix_output_site', message_multiple => 'All sites status are ok' },
    ];

    $self->{maps_counters}->{sites} = [
        { label => 'status', threshold => 0, set => {
                key_values => [
                    { name => 'display' }, { name => 'SiteName' }, { name => 'Type' }, { name => 'Mode' },
                    { name => 'Status' }, { name => 'SecondarySiteCMUpdateStatus' }
                ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
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
        'timeout:s'         => { name => 'timeout', default => 30 },
        'command:s'         => { name => 'command', default => 'powershell.exe' },
        'command-path:s'    => { name => 'command_path' },
        'command-options:s' => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
        'no-ps'             => { name => 'no_ps' },
        'ps-exec-only'      => { name => 'ps_exec_only' },
        'ps-display'        => { name => 'ps_display' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::sccm::sitestatus::get_powershell();
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

    foreach my $site (@{$decoded}) {
        $self->{sites}->{$site->{SiteCode}} = {
            display => $site->{SiteCode},
            SiteName => $site->{SiteName},
            Type => $map_type{$site->{Type}},
            Mode => $map_mode{$site->{Mode}},
            Status => $map_status{$site->{Status}},
            SecondarySiteCMUpdateStatus => $site->{SecondarySiteCMUpdateStatus}
        };
    }

    if (scalar(keys %{$self->{sites}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No sites found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check sites status.

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

=item B<--warning-status>

Set warning threshold for current synchronisation status (Default: '').
Can used special variables like: %{status}, %{mode}, %{type}, %{name}.

=item B<--critical-status>

Set critical threshold for current synchronisation status (Default: '').
Can used special variables like: %{status}, %{mode}, %{type}, %{name}.

=back

=cut
