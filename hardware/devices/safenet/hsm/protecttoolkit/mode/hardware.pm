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

package hardware::devices::safenet::hsm::protecttoolkit::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;
use centreon::plugins::misc;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|memory)$';
    
    $self->{cb_hook2} = 'cmd_execute';
    
    $self->{thresholds} = {
        hwstatus => [
            ['BATTERY OK', 'OK'],
            ['.*', 'CRITICAL']
        ]
    };
    
    $self->{components_path} = 'hardware::devices::safenet::hsm::protecttoolkit::mode::components';
    $self->{components_module} = ['hwstatus', 'temperature', 'memory'];
}

sub cmd_execute {
    my ($self, %options) = @_;
    
    ($self->{stdout}) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options}
    );

    $self->{stdout} =~ s/\r//msg;
    my ($model, $firmware, $fm_status, $transport_mode, $security_mode) = ('unknown', 'unknown', 'unknown', 'unknown', 'unknown');
    $model = $1 if ($self->{stdout} =~ /^Model\s+:\s+(.*?)\s*\n/msi);
    $firmware = $1 if ($self->{stdout} =~ /^Firmware Version\s+:\s+(.*?)\s*\n/msi);
    $fm_status = $1 if ($self->{stdout} =~ /^FM Status\s+:\s+(.*?)\s*\n/msi);
    $transport_mode = $1 if ($self->{stdout} =~ /^Transport Mode\s+:\s+(.*?)\s*\n/msi);
    $security_mode = $1 if ($self->{stdout} =~ /^Security Mode\s+:\s+(.*?)\s*\n/msi);
    $self->{output}->output_add(long_msg => sprintf("model: %s, firmware version: %s", $model, $firmware));
    $self->{output}->output_add(long_msg => sprintf("fm status: '%s', transport mode: '%s', security mode: '%s'", 
                                                    $fm_status, $transport_mode, $security_mode));
}

sub display {
    my ($self, %options) = @_;

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => sprintf("Hardware status is OK")
    );
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s'        => { name => 'hostname' },
        'remote'            => { name => 'remote' },
        'ssh-option:s@'     => { name => 'ssh_option' },
        'ssh-path:s'        => { name => 'ssh_path' },
        'ssh-command:s'     => { name => 'ssh_command', default => 'ssh' },
        'timeout:s'         => { name => 'timeout', default => 30 },
        'sudo'              => { name => 'sudo' },
        'command:s'         => { name => 'command', default => 'ctconf' },
        'command-path:s'    => { name => 'command_path' },
        'command-options:s' => { name => 'command_options', default => '-v' }
    });

    return $self;
}

1;

__END__

=head1 MODE

Check HSM hardware status.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'hwstatus', 'temperature', 'memory'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=temperature)

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='hwstats,CRITICAL,^(?!(OK)$)'

=item B<--warning>

Set warning threshold for 'temperature', 'memory' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,50'

=item B<--critical>

Set critical threshold for 'temperature', 'memory' (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,60'

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

Command to get information (Default: 'ctconf').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: '').

=item B<--command-options>

Command options (Default: '-v').

=back

=cut
    
