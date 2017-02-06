#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package apps::pacemaker::local::mode::constraints;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "hostname:s"        => { name => 'hostname' },
                                  "remote"            => { name => 'remote' },
                                  "ssh-option:s@"     => { name => 'ssh_option' },
                                  "ssh-path:s"        => { name => 'ssh_path' },
                                  "ssh-command:s"     => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"         => { name => 'timeout', default => 30 },
                                  "sudo"              => { name => 'sudo' },
                                  "command:s"         => { name => 'command', default => 'crm_resource' },
                                  "command-path:s"    => { name => 'command_path', default => '/usr/sbin' },
                                  "command-options:s" => { name => 'command_options', default => ' --constraints -r' },
                                  "resource:s"        => { name => 'resource' },
                                  "warning"           => { name => 'warning' },
                                });
    $self->{threshold} = 'CRITICAL';
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{resource}) || $self->{option_results}->{resource} eq '') {
       $self->{output}->add_option_msg(short_msg => "Please set the resource name with --resource option");
       $self->{output}->option_exit();
    }

    $self->{threshold} = 'WARNING' if (defined $self->{option_results}->{warning});
}

sub parse_output {
    my ($self, %options) = @_;

    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("Resource '%s' constraint location is OK", $self->{option_results}->{resource}));

    if ($options{output} =~ /Connection to cluster failed\:(.*)/i ) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => "Connection to cluster FAILED: $1");
            return ;
    }

    my @lines = split /\n/, $options{output};
    foreach my $line (@lines) {
        next if $line !~ /^\s+:\sNode/;
        if ($line =~ /^\s+:\sNode/) {
            $self->{output}->output_add(long_msg => sprintf('Processed %s', $line), debug => 1);
            $line =~ /^\s+:\sNode\s([a-zA-Z0-9-_]+)\s+\(score=([a-zA-Z0-9-_]+),\sid=([a-zA-Z0-9-_]+)/;
            my ($node, $score, $rule) = ($1, $2, $3);
            if ($score eq '-INFINITY' && $rule =~ /^cli-ban/) {
                $self->{output}->output_add(severity => $self->{threshold},
                                            short_msg => sprintf("Resource '%s' is locked on node '%s' ('%s')", $self->{option_results}->{resource}, $node, $rule));
            }
        } else {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => "ERROR: $line");
        }
    }
}

sub run {
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options}." ".$self->{option_results}->{resource});

    $self->parse_output(output => $stdout);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check that a resource has no location constraint (migrate without unmigrate)
Can be executed from any cluster node.

=over 8

=item B<--resource>

Set the resource name you want to check

=item B<--warning>

Return a warning instead of a critical

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine" --ssh-option='-p=52").

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'crm_resource').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: '/usr/sbin').

=item B<--command-options>

Command options (Default: ' --constraints -r').

=back

=cut
