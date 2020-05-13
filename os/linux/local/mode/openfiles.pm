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

package os::linux::local::mode::openfiles;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'files-open', nlabel => 'system.files.open.count', set => {
                key_values => [ { name => 'openfiles' } ],
                output_template => 'current open files: %s',
                perfdatas => [
                    { value => 'openfiles', template => '%s', min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'hostname:s'        => { name => 'hostname' },
        'remote'            => { name => 'remote' },
        'ssh-option:s@'     => { name => 'ssh_option' },
        'ssh-path:s'        => { name => 'ssh_path' },
        'ssh-command:s'     => { name => 'ssh_command', default => 'ssh' },
        'timeout:s'         => { name => 'timeout', default => 30 },
        'sudo'              => { name => 'sudo' },
        'command:s'         => { name => 'command', default => 'lsof' },
        'command-path:s'    => { name => 'command_path' },
        'command-options:s' => { name => 'command_options', default => '-a -d ^mem -d ^cwd -d ^rtd -d ^txt -d ^DEL 2>&1' },
        'filter-username:s' => { name => 'filter_username' },
        'filter-appname:s'  => { name => 'filter_appname' },
        'filter-pid:s'      => { name => 'filter_pid' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{hostname} = $self->{option_results}->{hostname};
    if (!defined($self->{hostname})) {
        $self->{hostname} = 'me';
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options}
    );

    $self->{global} = { openfiles => 0 };
    my @lines = split /\n/, $stdout;
    shift @lines;
    foreach (@lines) {
        /^(\S+)\s+(\S+)\s+(\S+)/;
        my ($name, $pid, $user) = ($1, $2, $3);
        next if (defined($self->{option_results}->{filter_username}) && $self->{option_results}->{filter_username} ne '' &&
            $user !~ /$self->{option_results}->{filter_username}/);
        next if (defined($self->{option_results}->{filter_appname}) && $self->{option_results}->{filter_appname} ne '' &&
            $name !~ /$self->{option_results}->{filter_appname}/);
        next if (defined($self->{option_results}->{filter_pid}) && $self->{option_results}->{filter_pid} ne '' &&
            $pid !~ /$self->{option_results}->{filter_pid}/);

        $self->{global}->{openfiles}++;
    }
}

1;

__END__

=head1 MODE

Check open files.

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

Command to get information (Default: 'lsof').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-a -d ^mem -d ^cwd -d ^rtd -d ^txt -d ^DEL 2>&1').

=item B<--filter-appname>

Filter application name (can be a regexp).

=item B<--filter-username>

Filter username name (can be a regexp).

=item B<--filter-pid>

Filter PID (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'files-open'.

=back

=cut
