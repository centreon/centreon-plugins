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

package apps::voip::asterisk::remote::mode::activecalls;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use apps::voip::asterisk::remote::lib::ami;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.2';

    $options{options}->add_options(arguments =>
                                {
                                  "hostname:s"        => { name => 'hostname' },
                                  "port:s"            => { name => 'port', default => 5038 },
                                  "username:s"        => { name => 'username' },
                                  "password:s"        => { name => 'password' },
                                  "remote:s"          => { name => 'remote', default => 'ssh' },
                                  "ssh-option:s@"     => { name => 'ssh_option' },
                                  "ssh-path:s"        => { name => 'ssh_path' },
                                  "ssh-command:s"     => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"         => { name => 'timeout', default => 30 },
                                  "command:s"         => { name => 'command', default => 'asterisk_sendcommand.pm' },
                                  "command-path:s"    => { name => 'command_path', default => '/home/centreon/bin' },
                                  "protocol:s"        => { name => 'protocol', },
                                  "warning:s"         => { name => 'warning', },
                                  "critical:s"        => { name => 'critical', },
                                });
    $self->{result} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the --hostname option");
        $self->{output}->option_exit();
    }

    if ($self->{option_results}->{remote} eq 'ami')
    {
    	if (!defined($self->{option_results}->{username})) {
	        $self->{output}->add_option_msg(short_msg => "Please set the --username option");
	        $self->{output}->option_exit();
	    }

	    if (!defined($self->{option_results}->{password})) {
	        $self->{output}->add_option_msg(short_msg => "Please set the --password option");
	        $self->{output}->option_exit();
	    }
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    my @result;

    $self->{asterisk_command} = 'core show channels';

    if ($self->{option_results}->{remote} eq 'ami')
    {
    	apps::voip::asterisk::remote::lib::ami::connect($self);
        @result = apps::voip::asterisk::remote::lib::ami::action($self);
        apps::voip::asterisk::remote::lib::ami::quit();
    }
    else
    {
    	my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => "'".$self->{asterisk_command}."'",
                                                  );
        @result = split /\n/, $stdout;
    }

    # Compute data
    foreach my $line (@result) {
        if ($line =~ /^(\d*) active call/)
        {
	        $self->{result}->{activecalls} = {value => $1, status => '1'};
        }
        elsif ($line =~ /^Unable to connect .*/)
        {
        	$self->{result}->{activecalls} = {value => $line, status => '0'};
        }
    }
}

sub run {
    my ($self, %options) = @_;

    my $msg;
    my $old_status = 'ok';

    $self->manage_selection();

    # Send formated data to Centreon
    if ($self->{result}->{activecalls}->{status} eq '0')
    {
    	$self->{output}->output_add(severity => $self->{result}->{activecalls}->{status},
                                short_msg => $self->{result}->{activecalls}->{value});
        $self->{output}->display();
        $self->{output}->exit();
    }
    my $exit_code = $self->{perfdata}->threshold_check(value => $self->{result}->{activecalls}->{value},
                              threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->perfdata_add(label => 'Active Calls',
                                  value => $self->{result}->{activecalls}->{value},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("Current active calls: %s", $self->{result}->{activecalls}->{value})
                                );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Show number of current active calls

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--remote>

Execute command remotely; can be 'ami' or 'ssh' (default: ssh).

=item B<--hostname>

Hostname to query (need --remote option).

=item B<--port>

AMI remote port (default: 5038).

=item B<--username>

AMI username.

=item B<--password>

AMI password.

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--command>

Command to get information (Default: 'asterisk_sendcommand.pm').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: /home/centreon/bin).

=back

=cut
