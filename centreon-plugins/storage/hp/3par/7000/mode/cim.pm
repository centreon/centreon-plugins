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

package storage::hp::3par::7000::mode::cim;

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
                                  "hostname:s"              => { name => 'hostname' },
                                  "timeout:s"               => { name => 'timeout', default => 30 },
                                  "sudo"                    => { name => 'sudo' },
                                  "ssh-option:s@"           => { name => 'ssh_option' },
                                  "ssh-path:s"              => { name => 'ssh_path' },
                                  "ssh-command:s"           => { name => 'ssh_command', default => 'ssh' },
                                  "no-cim:s"                => { name => 'no_cim' },
                                });
    $self->{no_cim} = undef;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify a hostname.");
        $self->{output}->option_exit(); 
    }
    
    if (defined($self->{option_results}->{no_cim})) {
        if ($self->{option_results}->{no_cim} ne '') {
            $self->{no_cim} = $self->{option_results}->{no_cim};
        } else {
            $self->{no_cim} = 'critical';
        }
    }
}

sub run {
    my ($self, %options) = @_;

    $self->{option_results}->{remote} = 1;
    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => "showcim",
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});


    my @results = split("\n",$stdout);
    my $total_cim = 0;
    foreach my $result (@results) {
        if ($result =~ /(\S+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(\d+)\s+\S+/) {
            $total_cim++;
            my $serviceStatus = $1;
            my $serviceState = $2;
            my $slpState = $3;
            my $slpPort = $4;
            my $httpState = $5;
            my $httpPort = $6;
            my $httpsState = $7;
            my $httpsPort = $8;

            $self->{output}->output_add(long_msg => sprintf("CIM service is '%s' and '%s' [SLP on port %d is %s] [HTTP on port %d is %s] [HTTPS on port %d is %s]",
                                        $serviceStatus, $serviceState, $slpPort, $slpState, $httpPort, $httpState, $httpsPort ,$httpsState));
            if ((lc($serviceStatus) ne 'enabled') || (lc($serviceState) ne 'active')){
                $self->{output}->output_add(severity => 'critical',
                                            short_msg => sprintf("CIM service is '%s' and '%s' [SLP on port %d is %s] [HTTP on port %d is %s] [HTTPS on port %d is %s]",
                                        $serviceStatus, $serviceState, $slpPort, $slpState, $httpPort, $httpState, $httpsPort ,$httpsState));
            }
        }
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'CIM service is ok.');
    
    if (defined($self->{option_results}->{no_cim}) && $total_cim == 0) {
        $self->{output}->output_add(severity => $self->{no_cim},
                                    short_msg => 'No CIM service is checked.');
    }
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check CIM service status.

=over 8

=item B<--hostname>

Hostname to query.

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh').

=item B<--sudo>

Use sudo.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--no-cim>

Return an error if no CIM are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=back

=cut