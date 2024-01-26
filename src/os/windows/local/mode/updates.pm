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

package os::windows::local::mode::updates;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::windows::updates;
use JSON::XS;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'pending-updates', nlabel => 'windows.pending.updates.count', set => {
                key_values => [ { name => 'num' } ],
                output_template => 'pending Windows updates: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'timeout:s'          => { name => 'timeout', default => 50 },
        'command:s'          => { name => 'command', default => 'powershell.exe' },
        'command-path:s'     => { name => 'command_path' },
        'command-options:s'  => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
        'no-ps'              => { name => 'no_ps' },
        'ps-exec-only'       => { name => 'ps_exec_only' },
        'ps-display'         => { name => 'ps_display' },
        'filter-title:s'     => { name => 'filter_title' },
        'exclude-title:s'    => { name => 'exclude_title' },
        'filter-mandatory:s' => { name => 'filter_mandatory' },
        'display-updates'    => { name => 'display_updates' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::windows::updates::get_powershell();
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
        $decoded = JSON::XS->new->decode($self->{output}->decode($stdout));
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    #[
    #   {"isMandatory":false, "title":"Windows Malicious Software Removal Tool x64 - v5.105 (KB890830)"},
    #   {"isMandatory":false,"title":"2022-09 Cumulative Update Preview for .NET Framework 3.5, 4.7.2 and 4.8 for Windows Server 2019 for x64 (KB5017855)"},
    #   {"isMandatory":false,"title":"2022-09 Cumulative Update for Windows Server 2019 (1809) for x64-based Systems (KB5017315)"}
    #]

    $self->{global} = { num => 0 };
    foreach my $update (@$decoded) {
        next if (defined($self->{option_results}->{filter_title}) && $self->{option_results}->{filter_title} ne '' &&
            $update->{title} !~ /$self->{option_results}->{filter_title}/);
        next if (defined($self->{option_results}->{exclude_title}) && $self->{option_results}->{exclude_title} ne '' &&
            $update->{title} =~ /$self->{option_results}->{exclude_title}/);

        $update->{isMandatory} = $update->{isMandatory} =~ /^(?:true|1)$/i ? 'yes' : 'no';
        next if (defined($self->{option_results}->{filter_mandatory}) && $self->{option_results}->{filter_mandatory} ne '' &&
            $update->{isMandatory} !~ /$self->{option_results}->{filter_mandatory}/);

        $self->{global}->{num}++;

        if (defined($self->{option_results}->{display_updates})) {
            $update->{title} =~ s/\|/ /g;
            $self->{output}->output_add(
                long_msg => sprintf(
                    'update: %s [mandatory: %s]',
                    $update->{title},
                    $update->{isMandatory}
                )
            );
        }
    }
}

1;

__END__

=head1 MODE

Check pending Windows updates.

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

=item B<--filter-mandatory>

Filter only mandatory Windows updates.

=item B<--filter-title>

Filter Windows updates by title (can be a regexp).

=item B<--exclude-title>

Exclude Windows updates by title (can be a regexp).

=item B<--display-updates>

Display updates in verbose output.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'pending-updates'.

=back

=cut
