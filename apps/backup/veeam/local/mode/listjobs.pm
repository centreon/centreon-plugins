#
# Copyright 2018 Centreon (http://www.centreon.com/)
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
use centreon::common::powershell::veeam::listjobs;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "timeout:s"           => { name => 'timeout', default => 50 },
                                  "command:s"           => { name => 'command', default => 'powershell.exe' },
                                  "command-path:s"      => { name => 'command_path' },
                                  "command-options:s"   => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
                                  "no-ps"               => { name => 'no_ps' },
                                  "ps-exec-only"        => { name => 'ps_exec_only' },
                                  "filter-name:s"       => { name => 'filter_name' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (sort keys %{$self->{jobs}}) {        
        $self->{output}->output_add(long_msg => "'" . $_ . "' [type = " . $self->{jobs}->{$_}->{type}  . "]");
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List jobs:');
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
            type => $self->{jobs}->{$_}->{type},
        );
    }
}

sub manage_selection {
    my ($self, %options) = @_;

   my $ps = centreon::common::powershell::veeam::listjobs::get_powershell(
        no_ps => $self->{option_results}->{no_ps});

    $self->{option_results}->{command_options} .= " " . $ps;
    my ($stdout) = centreon::plugins::misc::execute(output => $self->{output},
                                                    options => $self->{option_results},
                                                    command => $self->{option_results}->{command},
                                                    command_path => $self->{option_results}->{command_path},
                                                    command_options => $self->{option_results}->{command_options});
    if (defined($self->{option_results}->{ps_exec_only})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => $stdout);
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }
    
    $self->{jobs} = {};
    my @lines = split /\n/, $stdout;
    foreach my $line (@lines) {
        next if ($line !~ /^\[name\s*=(.*?)\]\[type\s*=(.*?)\]/i);
        my ($name, $type) = (centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($2));
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' && 
            $name !~ /$self->{option_results}->{filter_name}/i) {
            $self->{output}->output_add(long_msg => "skipping job '" . $name . "': no type or no matching filter type", debug => 1);
            next;
        }
        
        $self->{jobs}->{$name} = { type => $type };
    }
}

1;

__END__

=head1 MODE

List jobs.

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

=item B<--ps-exec-only>

Print powershell output.

=item B<--filter-name>

Filter job name (can be a regexp).

=back

=cut
