#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package os::windows::local::mode::liststorages;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::common::powershell::windows::liststorages;
use centreon::plugins::misc;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'no-ps'             => { name => 'no_ps', },
        'timeout:s'         => { name => 'timeout', default => 50 },
        'command:s'         => { name => 'command', default => 'powershell.exe' },
        'command-path:s'    => { name => 'command_path' },
        'command-options:s' => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
        'ps-exec-only'      => { name => 'ps_exec_only', },
        'ps-display'        => { name => 'ps_display' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $map_type = {
    0 => 'unknown',
    1 => 'noRootDirectory',
    2 => 'removableDisk',
    3 => 'localDisk',
    4 => 'networkDrive',
    5 => 'compactDisc',
    6 => 'ramDisk'
};

sub manage_selection {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::windows::liststorages::get_powershell();
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

    return $decoded;
}

sub run {
    my ($self, %options) = @_;

    my $result = $self->manage_selection();
    foreach (@$result) {
        $self->{output}->output_add(
            long_msg => sprintf(
                "'%s' [size: %s][free: %s][desc: %s][type: %s]",
                $_->{name},
                defined($_->{size}) ? $_->{size} : '',
                defined($_->{freespace}) ? $_->{freespace} : '',
                defined($_->{desc}) ? $_->{desc} : '',
                $map_type->{ $_->{type} }
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List disks:'
    );

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name', 'size', 'free', 'type', 'desc']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $result = $self->manage_selection();
    foreach (@$result) {
        $self->{output}->add_disco_entry(
            name => $_->{name},
            size => defined($_->{size}) ? $_->{size} : '',
            free => defined($_->{freespace}) ? $_->{freespace} : '',
            type => $map_type->{ $_->{type} },
            desc => defined($_->{desc}) ? $_->{desc} : ''
        );
    }
}

1;

__END__

=head1 MODE

List Windows disks.

=over 8

=item B<--timeout>

Set timeout time for command execution (Default: 50 sec)

=item B<--no-ps>

Don't encode powershell. To be used with --command and 'type' command.

=item B<--command>

Command to get information (Default: 'powershell.exe').
Can be changed if you have output in a file. To be used with --no-ps option!!!

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-InputFormat none -NoLogo -EncodedCommand').

=item B<--ps-display>

Display powershell script.

=item B<--ps-exec-only>

Print powershell output.

=item B<--filter-type>

Filter database (only wilcard 'FileSystem' can be used. In Powershell).

=back

=cut
