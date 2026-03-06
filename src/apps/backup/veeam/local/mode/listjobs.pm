#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::backup::veeam::local::mode::listjobs;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::common::powershell::veeam::functions qw/veeam_to_psexec/;
use apps::backup::veeam::local::mode::resources::types qw($job_type);
use centreon::common::powershell::veeam::listjobs;
use centreon::plugins::misc;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'timeout:s'         => { name => 'timeout', default => 50 },
        'command:s'         => { name => 'command', default => '' },
        'command-path:s'    => { name => 'command_path' },
        'command-options:s' => { name => 'command_options' },
        'no-ps'             => { name => 'no_ps' },
        'ps-exec-only'      => { name => 'ps_exec_only' },
        'ps-display'        => { name => 'ps_display' },
        'filter-name:s'     => { name => 'filter_name' },
        'veeam-version:s'   => { name => 'veeam_version', default => '12' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    centreon::plugins::misc::check_security_command(
        output => $self->{output},
        command => $self->{option_results}->{command},
        command_options => $self->{option_results}->{command_options},
        command_path => $self->{option_results}->{command_path}
    );


    $self->{option_results}->{command} = veeam_to_psexec($self->{option_results}->{veeam_version})
        if $self->{option_results}->{command} eq '';
    $self->{option_results}->{command_options} = '-InputFormat none -NoLogo -EncodedCommand'
        if (!defined($self->{option_results}->{command_options}) || $self->{option_results}->{command_options} eq '');
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (sort keys %{$self->{jobs}}) {        
        $self->{output}->output_add(long_msg => "'" . $_ . "' [type = " . $self->{jobs}->{$_}->{type}  . "]");
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List jobs:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name', 'type']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (sort keys %{$self->{jobs}}) {
        $self->{output}->add_disco_entry(
            name => $_,
            type => $self->{jobs}->{$_}->{type}
        );
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::veeam::listjobs::get_powershell();
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

    $self->{jobs} = {};
    foreach my $job (@$decoded) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' && 
            $job->{name} !~ /$self->{option_results}->{filter_name}/i) {
            $self->{output}->output_add(long_msg => "skipping job '" . $job->{name} . "': no matching filter name", debug => 1);
            next;
        }

        $self->{jobs}->{ $job->{name} } = {
            type => defined($job_type->{ $job->{type} }) ? $job_type->{ $job->{type} } : 'unknown'
        };
    }
}

1;

__END__

=head1 MODE

List jobs.

=over 8

=item B<--veeam-version>

The Veeam version to monitor (default: 12).
Veeam version 13 and later require PowerShell 7 whereas earlier versions use PowerShell 5.

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

=item B<--filter-name>

Filter job name (can be a regexp).

=back

=cut
