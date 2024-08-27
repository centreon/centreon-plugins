#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package hardware::server::sun::mgmt_cards::mode::showenvironment;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;
use centreon::plugins::misc;

sub set_system {
    my ($self, %options) = @_;

    $self->{cb_hook2} = 'execute_command';

    $self->{components_exec_load} = 0;

    $self->{thresholds} = {        
        temperature => [
            ['^(?!(OK)$)', 'CRITICAL'],
            ['^OK$', 'OK']
        ],
        si => [
            ['^(?!(OFF)$)', 'CRITICAL'],
            ['^OFF$', 'OK']
        ],
        disk => [
            ['^(?!(OK|NOT PRESENT)$)', 'CRITICAL'],
            ['^OK|NOT PRESENT$', 'OK']
        ],
        fan => [
            ['^(?!(OK|NOT PRESENT)$)', 'CRITICAL'],
            ['^OK|NOT PRESENT$', 'OK']
        ],
        voltage => [
            ['^(?!(OK)$)', 'CRITICAL'],
            ['^OK$', 'OK']
        ],
        psu => [
            ['^(?!(OK|NOT PRESENT)$)', 'CRITICAL'],
            ['^OK|NOT PRESENT$', 'OK']
        ],
        sensors => [
            ['^(?!(OK)$)', 'CRITICAL'],
            ['^OK$', 'OK']
        ]
    };

    $self->{components_path} = 'hardware::server::sun::mgmt_cards::components::showenvironment';
    $self->{components_module} = ['temperature', 'si', 'disk', 'fan', 'voltage', 'psu', 'sensors'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_performance => 1, no_absent => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'hostname:s'       => { name => 'hostname' },
        'port:s'           => { name => 'port', default => 23 },
        'username:s'       => { name => 'username' },
        'password:s'       => { name => 'password' },
        'timeout:s'        => { name => 'timeout', default => 30 },
        'command-plink:s'  => { name => 'command_plink' },
        'ssh'              => { name => 'ssh' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{hostname})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify a hostname.");
       $self->{output}->option_exit(); 
    }
    if (!defined($self->{option_results}->{username})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify a username.");
       $self->{output}->option_exit(); 
    }
    if (!defined($self->{option_results}->{password})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify a password.");
       $self->{output}->option_exit(); 
    }

    if (!defined($self->{option_results}->{ssh})) {
        require hardware::server::sun::mgmt_cards::lib::telnet;
    }

    centreon::plugins::misc::check_security_command(
        output => $self->{output},
        command => $self->{option_results}->{command_plink}
    );

    $self->{option_results}->{command} = 'plink'
        if (!defined($self->{option_results}->{command}) || $self->{option_results}->{command} eq '');
}

sub ssh_command {
    my ($self, %options) = @_;
    
    my $cmd_in = $self->{option_results}->{username} . '\n' . $self->{option_results}->{password} . '\nshowenvironment\nlogout\n';
    my $cmd = "echo -e '$cmd_in' | " . $self->{option_results}->{command_plink} . " -batch " . $self->{option_results}->{hostname} . " 2>&1";
    my ($lerror, $stdout, $exit_code) = centreon::plugins::misc::backtick(
        command => $cmd,
        timeout => $self->{option_results}->{timeout},
        wait_exit => 1
    );

    $stdout =~ s/\r//g;
    if ($lerror <= -1000) {
        $self->{output}->output_add(severity => 'UNKNOWN', 
                                    short_msg => $stdout);
        $self->{output}->display();
        $self->{output}->exit();
    }
    if ($exit_code != 0) {
        $stdout =~ s/\n/ - /g;
        $self->{output}->output_add(severity => 'UNKNOWN', 
                                    short_msg => "Command error: $stdout");
        $self->{output}->display();
        $self->{output}->exit();
    }

    if ($stdout !~ /Environmental Status/mi) {
        $self->{output}->output_add(long_msg => $stdout);
        $self->{output}->output_add(severity => 'UNKNOWN', 
                                    short_msg => "Command 'showenvironment' problems (see additional info).");
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    return $stdout;
}

sub execute_command {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{ssh})) {
        $self->{stdout} = $self->ssh_command();
    } else {
        my $telnet_handle = hardware::server::sun::mgmt_cards::lib::telnet::connect(
            username => $self->{option_results}->{username},
            password => $self->{option_results}->{password},
            hostname => $self->{option_results}->{hostname},
            port => $self->{option_results}->{port},
            timeout => $self->{option_results}->{timeout},
            output => $self->{output}
        );
        my @lines = $telnet_handle->cmd("showenvironment");
        $self->{stdout} = join("", @lines);
    }
    $self->{stdout} =~ s/\r//msg;
}

1;

__END__

=head1 MODE

Check Sun vXXX (v240, v440, v245,...) Hardware (through ALOM).

=over 8

=item B<--hostname>

Hostname to query.

=item B<--port>

telnet port (default: 23).

=item B<--username>

telnet username.

=item B<--password>

telnet password.

=item B<--timeout>

Timeout in seconds for the command (default: 30).

=item B<--command-plink>

Plink command (default: plink). Use to set a path.

=item B<--ssh>

Use ssh (with plink) instead of telnet.

=item B<--component>

Which component to check (default: '.*').
Can be: 'temperature', 'si', 'disk', 'fan', 'voltage', 'psu', 'sensors'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=fan).
You can also exclude items from specific instances: --filter=fan,F1.RS

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,status,regexp).
Example: --threshold-overload='fan,CRITICAL,^(?!(OK|NOT PRESENT)$)'

=back

=cut
