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

package apps::backup::netbackup::local::mode::listpolicies;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "hostname:s"        => { name => 'hostname' },
                                  "remote"            => { name => 'remote' },
                                  "ssh-option:s@"     => { name => 'ssh_option' },
                                  "ssh-path:s"        => { name => 'ssh_path' },
                                  "ssh-command:s"     => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"         => { name => 'timeout', default => 30 },
                                  "sudo"              => { name => 'sudo' },
                                  "command:s"         => { name => 'command', default => 'bppllist' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "command-options:s" => { name => 'command_options', default => '' },
                                  "command2:s"        => { name => 'command2', default => 'bpplinfo %{policy_name} -L' },
                                  "filter-name:s"     => { name => 'filter_name' },
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

    foreach (sort keys %{$self->{policies}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' && 
            $_ !~ /$self->{option_results}->{filter_name}/i) {
            $self->{output}->output_add(long_msg => "skipping policy '" . $_ . "': no type or no matching filter type");
            next;
        }
        
        $self->{output}->output_add(long_msg => "'" . $_ . "' [active = " . $self->{policies}->{$_}->{active}  . "]");
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List policy:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'active']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (sort keys %{$self->{policies}}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' && 
                 $_ !~ /$self->{option_results}->{filter_name}/i);

        $self->{output}->add_disco_entry(name => $_,
                                         active => $self->{policies}->{$_}->{active}
                                         );
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = centreon::plugins::misc::execute(output => $self->{output},
                                                    options => $self->{option_results},
                                                    sudo => $self->{option_results}->{sudo},
                                                    command => $self->{option_results}->{command},
                                                    command_path => $self->{option_results}->{command_path},
                                                    command_options => $self->{option_results}->{command_options});
    $self->{policies} = {};
    my @lines = split /\n/, $stdout;
    foreach my $policy_name (@lines) {
        my $command2 = $self->{option_results}->{command2};
        $command2 =~ s/%\{policy_name\}/$policy_name/g;
        my ($stdout2) = centreon::plugins::misc::execute(output => $self->{output},
                                                         options => $self->{option_results},
                                                         sudo => $self->{option_results}->{sudo},
                                                         command => $command2);
        
        #Policy Type:            NBU-Catalog (35)
        #Active:                 yes        
        my $active = '';
        $active = $1 if ($stdout2 =~ /^Active\s*:\s+(\S+)/msi);
        $self->{policies}->{$policy_name} = { active => $active };
    }
}

1;

__END__

=head1 MODE

List policies.

=over 8

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'bppllist').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: none).

=item B<--command2>

Command to get active policy information (Default: 'bpplinfo %{policy_name} -L').
Can be changed if you have output in a file.

=item B<--filter-name>

Filter policy name (can be a regexp).

=back

=cut
