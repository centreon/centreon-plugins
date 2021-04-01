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

package hardware::server::sun::mgmt_cards::mode::showfaults;

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
                                  "hostname:s"       => { name => 'hostname' },
                                  "username:s"       => { name => 'username' },
                                  "password:s"       => { name => 'password' },
                                  "timeout:s"        => { name => 'timeout', default => 30 },
                                  "command-plink:s"  => { name => 'command_plink', default => 'plink' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

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
}

sub run {
    my ($self, %options) = @_;

    ######
    # Command execution
    ######
    my $cmd = "echo -e '" . $self->{option_results}->{username} . "\n" . $self->{option_results}->{password} . "\nshowfaults\nlogout\n' | " . $self->{option_results}->{command_plink} . ' -T -batch ' . $self->{option_results}->{hostname} . " 2>&1";
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
  
    ######
    # Command treatment
    ######
    my ($otp1, $otp2) = split(/showfaults\n/, $stdout);
    my $long_msg = $otp2;
    $long_msg =~ s/\|/~/mg;
    if (!defined($otp2) || $otp2 !~ /(No failures|ID.*?FRU.*?Fault)/mi) {
        $self->{output}->output_add(long_msg => $stdout);
        $self->{output}->output_add(severity => 'UNKNOWN', 
                                    short_msg => "Command 'showfaults' problems (see additional info).");
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    $self->{output}->output_add(long_msg => $long_msg);
    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "No Problems on system.");
    # Check showfaults
    # Format:
    #   ID FRU               Fault
    #    1 /SYS              SP detected fault: Input power unavailable for PSU at PS1
    while ($otp2 =~ m/^\s+([0-9]+?)\s+([^\s]+?)\s+(.*)$/mg) {
        $self->{output}->output_add(severity => 'CRITICAL', 
                                    short_msg => "[$1][$2] $3.");
    }
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Sun 'T1xxx', 'T2xxx' Hardware (through ALOM4v).

=over 8

=item B<--hostname>

Hostname to query.

=item B<--username>

ssh username.

=item B<--password>

ssh password.

=item B<--command-plink>

Plink command (default: plink). Use to set a path.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=back

=cut
