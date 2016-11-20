#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package storage::ibm::storwize::ssh::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;
    
    $self->{regexp_threshold_overload_check_section_option} = 
        '^(array|drive|enclosure|enclosurebattery|enclosurecanister|enclosurepsu|host|portfc|portsas|vdisk|node|quorum|mdisk)$';
    $self->{regexp_threshold_numeric_check_section_option} = '^(systemstats)$';
    
    $self->{cb_hook2} = 'ssh_execute';
    
    $self->{thresholds} = {
        default => [
            ['online', 'OK'],
            ['offline', 'CRITICAL'],
            ['degraded', 'WARNING'],
            ['excluded', 'OK'], # lsarray
            ['mask', 'OK'], # lshost
        ],
        portfc => [
            ['active', 'OK'],
            ['inactive_unconfigured', 'OK'],
            ['.*', 'CRITICAL'],
        ],
        portsas => [
            ['online', 'OK'],
            ['offline_unconfigured', 'OK'],
            ['excluded', 'OK'],
            ['offline', 'CRITICAL'],
            ['degraded', 'WARNING'],
        ],
        mdisk => [
            ['online', 'OK'],
            ['excluded', 'OK'],
            ['offline', 'CRITICAL'],
            ['degraded_paths', 'WARNING'],
            ['degraded_ports', 'WARNING'],
            ['degraded', 'WARNING'],
        ],
    };
    
    $self->{components_path} = 'storage::ibm::storwize::ssh::mode::components';
    $self->{components_module} = ['array', 'drive', 'enclosure', 'enclosurebattery', 'enclosurecanister',
                                  'enclosurepsu', 'host', 'portfc', 'portsas', 'vdisk', 'node', 'quorum', 'mdisk', 'systemstats'];
}

sub ssh_execute {
    my ($self, %options) = @_;
    
    $self->{results} = centreon::plugins::misc::execute(output => $self->{output},
                                                        options => $self->{option_results},
                                                        sudo => $self->{option_results}->{sudo},
                                                        command => defined($self->{option_results}->{command}) && $self->{option_results}->{command} ne '' ? $self->{option_results}->{command} : $self->{ssh_commands} . " exit ;",
                                                        command_path => $self->{option_results}->{command_path},
                                                        command_options => defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '' ? $self->{option_results}->{command_options} : undef);
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        $self->{option_results}->{remote} = 1;
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "hostname:s"        => { name => 'hostname' },
                                  "ssh-option:s@"     => { name => 'ssh_option' },
                                  "ssh-path:s"        => { name => 'ssh_path' },
                                  "ssh-command:s"     => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"         => { name => 'timeout', default => 30 },
                                  "sudo"              => { name => 'sudo' },
                                  "command:s"         => { name => 'command' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "command-options:s" => { name => 'command_options' },
                                });

    $self->{ssh_commands} = '';
    return $self;
}

sub get_hasharray {
    my ($self, %options) = @_;

    my $result = [];
    return $result if ($options{content} eq '');
    my ($header, @lines) = split /\n/, $options{content};
    my @header_names = split /$options{delim}/, $header;
    
    for (my $i = 0; $i <= $#lines; $i++) {
        my @content = split /$options{delim}/, $lines[$i];
        my $data = {};
        for (my $j = 0; $j <= $#header_names; $j++) {
            $data->{$header_names[$j]} = $content[$j];
        }
        push @$result, $data;
    }
    
    return $result;
}

1;

__END__

=head1 MODE

Check components.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'array', 'drive', 'enclosure', 'enclosurebattery', 'enclosurecanister',
'enclosurepsu', 'host', 'portfc', 'portsas', 'vdisk', 'node', 'quorum', 'mdisk', 'systemstats'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=host --filter=enclosurecanister)
Can also exclude specific instance: --filter=host,10

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: ---threshold-overload='host,.*,OK,degraded'

=item B<--warning>

Set warning threshold for temperatures (syntax: type,regexp,threshold)
Example: --warning='systemstats,cpu_pc,30'

=item B<--critical>

Set critical threshold for temperatures (syntax: type,regexp,threshold)
Example: --critical='systemstats,cpu_pc,40'

=item B<--hostname>

Hostname to query.

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

Command to get information. Used it you have output in a file.

=item B<--command-path>

Command path.

=item B<--command-options>

Command options.

=back

=cut
