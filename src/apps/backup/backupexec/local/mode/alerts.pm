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

package apps::backup::backupexec::local::mode::alerts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::powershell::backupexec::alerts;
use apps::backup::backupexec::local::mode::resources::types qw($alert_severity $alert_source $alert_category);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc;
use JSON::XS;

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "alert %s [severity: %s] [source: %s] [category: %s] [raised: %s] %s",
        $self->{result_values}->{name},
        $self->{result_values}->{severity},
        $self->{result_values}->{source},
        $self->{result_values}->{category},
        scalar(localtime($self->{result_values}->{timeraised})),
        $self->{result_values}->{message}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return 'Alerts severity ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { 
            name => 'alarms', type => 2, message_multiple => '0 alerts detected', format_output => '%s alerts detected', display_counter_problem => { nlabel => 'alerts.detected.count', min => 0 },
            group => [ { name => 'alarm', skipped_code => { -11 => 1 } } ] 
        }
    ];

    $self->{maps_counters}->{global} = [];
    foreach ('none', 'information', 'question', 'warning', 'error') {
        push @{$self->{maps_counters}->{global}}, {
            label => 'severity-' . $_, nlabel => 'alerts.severity.' . $_ . '.count', display_ok => 0, set => {
                key_values => [ { name => $_ } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        };
    }

    $self->{maps_counters}->{alarm} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{severity} =~ /warning/i',
            critical_default => '%{severity} =~ /error/i',
            set => {
                key_values => [
                    { name => 'timeraised' }, { name => 'category' },
                    { name => 'severity' }, { name => 'source' },
                    { name => 'message' }, { name => 'name' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'timeout:s'         => { name => 'timeout', default => 50 },
        'command:s'         => { name => 'command' },
        'command-path:s'    => { name => 'command_path' },
        'command-options:s' => { name => 'command_options' },
        'no-ps'             => { name => 'no_ps' },
        'ps-exec-only'      => { name => 'ps_exec_only' },
        'ps-display'        => { name => 'ps_display' },
        'bemcli-file'       => { name => 'bemcli_file' },
        'filter-category:s' => { name => 'filter_category' },
        'filter-source:s'   => { name => 'filter_source' },
        'filter-severity:s' => { name => 'filter_severity' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    centreon::plugins::misc::check_security_command(
        output => $self->{output},
        command => $self->{option_results}->{command},
        command_options => $self->{option_results}->{command_options},
        command_path => $self->{option_results}->{command_path}
    );

    $self->{option_results}->{command} = 'powershell.exe'
        if (!defined($self->{option_results}->{command}) || $self->{option_results}->{command} eq '');
    $self->{option_results}->{command_options} = '-InputFormat none -NoLogo -EncodedCommand'
        if (!defined($self->{option_results}->{command_options}) || $self->{option_results}->{command_options} eq '');
}

sub manage_selection {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::backupexec::alerts::get_powershell(
            bemcli_file => $self->{option_results}->{bemcli_file}
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
        $decoded = JSON::XS->new->decode($stdout);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    #[
    #  { "name": "alert 1", "severity": 1, "source": 0, "category": 1, "message": "test 1", "creationTime": 1512875246.2 },
    #  { "name": "alert 2", "severity": 3, "source": 2, "category": 8, "message": "test 2", "creationTime": "1512875246.2" }
    #]

    $self->{global} = { none => 0, information => 0, question => 0, warning => 0, error => 0 };
    $self->{alarms}->{global} = { alarm => {} };
    my $i = 0;
    foreach my $alert (@$decoded) {
        my $severity = defined($alert_severity->{ $alert->{severity} }) ? $alert_severity->{ $alert->{severity} } : 'unknown';
        my $category = defined($alert_category->{ $alert->{category} }) ? $alert_category->{ $alert->{category} } : 'unknown';
        my $source = defined($alert_source->{ $alert->{source} }) ? $alert_source->{ $alert->{source} } : 'unknown';
        $alert->{creationTime} =~ s/,/\./;

        if (defined($self->{option_results}->{filter_category}) && $self->{option_results}->{filter_category} ne '' &&
            $category !~ /$self->{option_results}->{filter_category}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $alert->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_severity}) && $self->{option_results}->{filter_severity} ne '' &&
            $severity !~ /$self->{option_results}->{filter_severity}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $alert->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_source}) && $self->{option_results}->{filter_source} ne '' &&
            $source !~ /$self->{option_results}->{filter_source}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $alert->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{global}->{$severity}++;
        $self->{alarms}->{global}->{alarm}->{$i} = {
            name => $alert->{name},
            source => $source,
            category => $category,
            severity => $severity,
            message => $alert->{message},
            timeraised => $alert->{creationTime}
        };
        $i++;
    }
}

1;

__END__

=head1 MODE

Check alerts.

=over 8

=item B<--timeout>

Set timeout time for command execution (default: 50 sec)

=item B<--no-ps>

Don't encode powershell. To be used with --command and 'type' command.

=item B<--command>

Command to get information (default: 'powershell.exe').
Can be changed if you have output in a file. To be used with --no-ps option!!!

=item B<--command-path>

Command path (default: none).

=item B<--command-options>

Command options (default: '-InputFormat none -NoLogo -EncodedCommand').

=item B<--ps-display>

Display powershell script.

=item B<--ps-exec-only>

Print powershell output.

=item B<--bemcli-file>

Set powershell module file (default: 'C:/Program Files/Veritas/Backup Exec/Modules/BEMCLI/bemcli').

=item B<--filter-category>

Only get alerts by category (can be a regexp).

=item B<--filter-source>

Filter alerts by source (can be a regexp).

=item B<--filter-severity>

Only get alerts by severity (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{severity} =~ /warning/i')
You can use the following variables: %{name}, %{severity}, %{source}, %{category}, %{timeraised}, %{message}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{severity} =~ /error/i').
You can use the following variables: %{name}, %{severity}, %{source}, %{category}, %{timeraised}, %{message}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'severity-none', 'severity-information', 'severity-question',
'severity-warning', 'severity-error'.

=back

=cut
