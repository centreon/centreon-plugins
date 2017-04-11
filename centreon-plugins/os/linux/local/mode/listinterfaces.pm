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

package os::linux::local::mode::listinterfaces;

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
                                  "command:s"         => { name => 'command', default => 'ifconfig' },
                                  "command-path:s"    => { name => 'command_path', default => '/sbin' },
                                  "command-options:s" => { name => 'command_options', default => '-a 2>&1' },
                                  "filter-name:s"     => { name => 'filter_name', },
                                  "filter-state:s"    => { name => 'filter_state', },
                                  "no-loopback"       => { name => 'no_loopback', },
                                  "skip-novalues"     => { name => 'skip_novalues', },
                                });
    $self->{result} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});
    while ($stdout =~ /^(\S+)(.*?)(\n\n|\n$)/msg) {
        my ($interface_name, $values) = ($1, $2);
        $interface_name =~ s/:$//;
        my $states = '';
        $states .= 'R' if ($values =~ /RUNNING/ms);
        $states .= 'U' if ($values =~ /UP/ms);
        
        if (defined($self->{option_results}->{no_loopback}) && $values =~ /LOOPBACK/ms) {
            $self->{output}->output_add(long_msg => "Skipping interface '" . $interface_name . "': option --no-loopback");
            next;
        }
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $interface_name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping interface '" . $interface_name . "': no matching filter name");
            next;
        }
        if (defined($self->{option_results}->{filter_state}) && $self->{option_results}->{filter_state} ne '' &&
            $states !~ /$self->{option_results}->{filter_state}/) {
            $self->{output}->output_add(long_msg => "Skipping interface '" . $interface_name . "': no matching filter state");
            next;
        }
        
        $values =~ /RX bytes:(\S+).*?TX bytes:(\S+)/msi;
        if (defined($self->{option_results}->{skip_novalues}) && !defined($1)) {
            $self->{output}->output_add(long_msg => "Skipping interface '" . $interface_name . "': no values");
            next;
        }
        $self->{result}->{$interface_name} = {state => $states};
    }    
}

sub run {
    my ($self, %options) = @_;
	
    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {
        $self->{output}->output_add(long_msg => "'" . $name . "' [state = '" . $self->{result}->{$name}->{state} . "']");
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List interfaces:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {     
        $self->{output}->add_disco_entry(name => $name,
                                         state => $self->{result}->{$name}->{state}
                                         );
    }
}

1;

__END__

=head1 MODE

List storages.

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

Command to get information (Default: 'ifconfig').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: '/sbin').

=item B<--command-options>

Command options (Default: '-a 2>&1').

=item B<--filter-name>

Filter interface name (regexp can be used).

=item B<--filter-state>

Filter state (regexp can be used).
Can be: 'R' (running), 'U' (up).

=item B<--no-loopback>

Don't display loopback interfaces.

=item B<--skip-novalues>

Filter interface without in/out byte values.

=back

=cut