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

package apps::pacemaker::local::mode::crm;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

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
                                  "command:s"         => { name => 'command', default => 'crm_mon' },
                                  "command-path:s"    => { name => 'command_path', default => '/usr/sbin' },
                                  "command-options:s"           => { name => 'command_options', default => '-1 -r -f 2>&1' },
                                  "warning"                     => { name => 'warning', },
                                  "standbyignore"               => { name => 'standbyignore', },
                                  "resources:s"                 => { name => 'resources', },
                                  "ignore-stopped-clone:s"      => { name => 'ignore_stopped_clone', },
                                  "ignore-failed-actions:s@"    => { name => 'ignore_failed_actions', },
                                });
    $self->{threshold} = 'CRITICAL';
    $self->{resources_check} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{warning})) {
        $self->{threshold} = 'WARNING';
    }
    if (defined($self->{option_results}->{resources})) {
        foreach (split(/,/, $self->{option_results}->{resources})) {
            my ($rsc_name, $node) = split(/:/, $_);
            if (defined($rsc_name) && $rsc_name ne '' && 
                defined($node) && $node ne '') {
                $self->{resources_check}->{$rsc_name} = $node;
            }
        }
    }
}

sub parse_output {
    my ($self, %options) = @_;
    
    my @standby;
    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "Cluster is OK");
    my @lines = split /\n/, $options{crm_out};
    foreach my $line (@lines) {
        if ($line =~ /Connection to cluster failed\:(.*)/i ) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Connection to cluster FAILED: $1");
            return ;
        } elsif ($line =~ /Current DC:/) {
            if ($line !~ m/partition with quorum$/ ) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "No Quorum");
            }
        } elsif ($line =~ /^offline:\s*\[\s*(\S.*?)\s*\]/i) {
            # Count offline nodes
            my @offline = split( /\s+/, $1 );
            my $numoffline = scalar @offline;
            $self->{output}->output_add(severity => $self->{threshold}, 
                                        short_msg => "$numoffline Nodes Offline");
        } elsif ($line =~ /^node\s+(\S.*):\s*standby/i) {
            push @standby, $1;
        } elsif ($line =~ /\s*([0-9a-zA-Z_\-]+)\s+\(\S+\)\:\s+Started\s+([0-9a-zA-Z_\-]+)/) {
            # Check Resources pos
            if (defined($self->{resources_check}->{$1}) && $self->{resources_check}->{$1} ne $2) {
                $self->{output}->output_add(severity => $self->{threshold}, 
                                            short_msg => "Resource '$1' is started on node '$2'");
            }
            $self->{output}->output_add(long_msg => "Resource '$1' is started on node '$2'");
        } elsif ($line =~ /\s*([0-9a-zA-Z_\-]+)\s+\(\S+\)\:\s+Stopped/ || $line =~ /\s*([0-9a-zA-Z_\-]+)\s+\(\S+\)\:\s+\(\S+\)\s+Stopped/) {
            $self->{output}->output_add(severity => $self->{threshold}, 
                                        short_msg => "Resource '$1' is stopped",
                                        long_msg => "Resource '$1' is stopped");
        } elsif ($line =~ m/\s*stopped\:\s*\[\s*(.*)\s*\]/i) {
            # Check Master/Slave stopped
            my @stopped = ();
            foreach my $node (split /\s+/, $1) {
                if (!defined($self->{option_results}->{ignore_stopped_clone}) || $self->{option_results}->{ignore_stopped_clone} eq '' ||
                    $node !~ /$self->{option_results}->{ignore_stopped_clone}/) {
                    push @stopped, $node;
                }
            }
            if (scalar(@stopped) > 0) {
                $self->{output}->output_add(severity => $self->{threshold},
                                            short_msg => join(' ', @stopped) . " Stopped");
            }
        } elsif ($line =~ /^Failed actions\:/) {
            # Check Failed Actions          
            my $error = 0;
            foreach my $line_failed_action (shift @lines) {
                my $skip = 0;
                foreach (@{$self->{option_results}->{ignore_failed_actions}}) {
                    if ($line_failed_action =~ /$_/) {
                        $skip = 1;
                        last;
                    }
                }
                if ($skip == 0) {
                    $error = 1;
                    last;
                }
            }
            if ($error == 1) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "FAILED actions detected or not cleaned up");
            }
        } elsif ($line =~ /\s*(\S+?)\s+ \(.*\)\:\s+\w+\s+\w+\s+\(unmanaged\)\s+FAILED/) {
            # Check Unmanaged
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "$1 unmanaged FAILED");
        } elsif ($line =~ /\s*(\S+?):.*(fail-count=\d+)/i) {
            # Check for resource Fail count
            $self->{output}->output_add(severity => 'WARNING', 
                                        short_msg => "$1 failure detected, $2");
        }
    }
    
    if (scalar(@standby) > 0 && !defined($self->{option_results}->{standbyignore})) {
        $self->{output}->output_add(severity => $self->{threshold}, 
                                    short_msg => join( ', ', @standby ) . " in Standby");
    }
}

sub run {
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});
    $self->parse_output(crm_out => $stdout);
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Cluster Resource Manager (need 'crm_mon' command).
Should be executed on a cluster node.

=over 8

=item B<--warning>

If failed Nodes, stopped Resources detected or Standby Nodes sends Warning instead of Critical (default)
as long as there are no other errors and there is Quorum.

=item B<--standbyignore>

Ignore any node(s) in standby, by default return threshold choosen.

=item B<--resources>

If resources not started on the node specified, send a warning message:
(format: <rsc_name>:<node>,<rsc_name>:<node>,...)

=item B<--ignore-stopped-clone>

Stopped clone resource on nodes (that match) are skipped.

=item B<--ignore-failed-actions>

Failed actions errors (that match) are skipped.

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

Command to get information (Default: 'crm_mon').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: '/usr/sbin').

=item B<--command-options>

Command options (Default: '-1 -r -f 2>&1').

=back

=cut
