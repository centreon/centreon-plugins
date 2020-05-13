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

package os::linux::local::mode::pendingupdates;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'updates', type => 1 }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Number of pending updates : %d',
                perfdatas => [
                    { label => 'total', value => 'total', template => '%d',
                      min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{updates} = [
        { label => 'update', set => {
                key_values => [ { name => 'package' }, { name => 'version' }, { name => 'repository' } ],
                closure_custom_calc => $self->can('custom_updates_calc'),
                closure_custom_output => $self->can('custom_updates_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => sub { return 'ok'; }
            }
        },
    ];
}

sub custom_updates_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf(
        "Package '%s' [version: %s] [repository: %s]",
        $self->{result_values}->{package},
        $self->{result_values}->{version},
        $self->{result_values}->{repository}
    );
    return $msg;
}

sub custom_updates_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{package} = $options{new_datas}->{$self->{instance} . '_package'};
    $self->{result_values}->{version} = $options{new_datas}->{$self->{instance} . '_version'};
    $self->{result_values}->{repository} = $options{new_datas}->{$self->{instance} . '_repository'};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s'          => { name => 'hostname' },
        'remote'              => { name => 'remote' },
        'ssh-option:s@'       => { name => 'ssh_option' },
        'ssh-path:s'          => { name => 'ssh_path' },
        'ssh-command:s'       => { name => 'ssh_command', default => 'ssh' },
        'timeout:s'           => { name => 'timeout', default => 30 },
        'sudo'                => { name => 'sudo' },
        'command:s'           => { name => 'command', default => 'yum' },
        'command-path:s'      => { name => 'command_path', },
        'command-options:s'   => { name => 'command_options', default => 'check-update 2>&1' },
        'filter-package:s'    => { name => 'filter_package' },
        'filter-repository:s' => { name => 'filter_repository' },
    });

    $self->{result} = {};
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout, $exit_code) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options},
        no_quit => 1
    );

    $self->{global}->{total} = 0;
    $self->{updates} = {};
    my @lines = split /\n/, $stdout;
    foreach my $line (@lines) {
        next if ($line !~ /^(\S+)\s+(\d+\S+)\s+(\S+)/
            && $line !~ /\s+(\S+)\s+\(\S+\s\=\>\s(\S+)\)/
            && $line !~ /.*\|.*\|\s+(\S+)\s+\|.*\|\s+(\d+\S+)\s+\|.*/);
        my ($package, $version, $repository) = ($1, $2, $3);
        $repository = "-" if (!defined($repository) || $repository eq '');

        if (defined($self->{option_results}->{filter_package}) && $self->{option_results}->{filter_package} ne '' &&
            $package !~ /$self->{option_results}->{filter_package}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $package . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_repository}) && $self->{option_results}->{filter_repository} ne '' &&
            $repository !~ /$self->{option_results}->{filter_repository}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $repository . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{updates}->{$package} = {
            package => $package,
            version => $version,
            repository => $repository,
        };

        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check pending updates.

=over 8

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (Default: none)

=item B<--ssh-command>

Specify ssh command (Default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'yum').
Use 'apt-get' for Debian, 'zypper' for SUSE.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: 'check-updates 2>&1').
Use 'upgrade -sVq 2>&1' for Debian, 'list-updates 2>&1' for SUSE.

=item B<--warning-total>

Threshold warning for total amount of pending updates.

=item B<--critical-total>

Threshold critical for total amount of pending updates.

=item B<--filter-package>

Filter package name.

=item B<--filter-repository>

Filter repository name.

=back

=cut
