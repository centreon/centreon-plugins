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

package storage::hp::3par::7000::mode::physicaldisk;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %states = (    
    'normal'    => 'OK', 
    'new'       => 'OK', 
    'degraded'  => 'WARNING', 
    'failed'    => 'CRITICAL', 
);

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
                                  "no-component:s"          => { name => 'no_component' },
                                });
    $self->{components} = {};
    $self->{no_components} = undef;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify a hostname.");
        $self->{output}->option_exit(); 
    }
    
    if (defined($self->{option_results}->{no_component})) {
        if ($self->{option_results}->{no_component} ne '') {
            $self->{no_components} = $self->{option_results}->{no_component};
        } else {
            $self->{no_components} = 'critical';
        }
    }
}

sub run {
    my ($self, %options) = @_;

    $self->{option_results}->{remote} = 1;
    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => "showpd -showcols Id,State",
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});


    my $total_components = 0;
    my @disks = split("\n",$stdout);
    foreach my $disk (@disks) {
        if ($disk =~ /(\d+)\s+(\S+)/) {
            $total_components++;
            my $diskId = $1;
            my $diskState = $2;

            $self->{output}->output_add(long_msg => sprintf("Physical Disk '%d' state is '%s'", $diskId, $diskState));
            if ($states{$diskState} ne 'OK'){
                $self->{output}->output_add(severity => $states{$diskState},
                                            short_msg => sprintf("Physical Disk '%d' state is '%s'.", $diskId, $diskState));
            }
        }
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All %d physical disks are ok.", $total_components));
     
    if (defined($self->{option_results}->{no_component}) && $total_components == 0) {
        $self->{output}->output_add(severity => $self->{no_components},
                                    short_msg => 'No components are checked.');
    }
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Physical disks.

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

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=back

=cut