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

package apps::apcupsd::local::mode::linevoltage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use apps::apcupsd::local::mode::libgetdata;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "hostname:s"         => { name => 'hostname' },
                                  "remote"             => { name => 'remote' },
                                  "ssh-option:s@"      => { name => 'ssh_option' },
                                  "ssh-path:s"         => { name => 'ssh_path' },
                                  "ssh-command:s"      => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"          => { name => 'timeout', default => 30 },
                                  "sudo"               => { name => 'sudo' },
                                  "command:s"          => { name => 'command', default => 'apcaccess' },
                                  "command-path:s"     => { name => 'command_path', default => '/sbin/' },
                                  "command-options:s"  => { name => 'command_options', default => ' status ' },
                                  "command-options2:s" => { name => 'command_options2', default => ' 2>&1' },
                                  "apchost:s"          => { name => 'apchost', default => 'localhost' },
                                  "apcport:s"          => { name => 'apcport', default => '3551' },
                                  "searchpattern:s"    => { name => 'searchpattern', default => 'LINEV' },
                                  "warning:s"          => { name => 'warning', default => '' },
                                  "critical:s"         => { name => 'critical', default => '' },
                                });
    return $self;
}

sub check_options {

    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{apchost})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify an APC Host.");
       $self->{output}->option_exit(); 
    }
    if (!defined($self->{option_results}->{apcport})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify an APC Port.");
       $self->{output}->option_exit(); 
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

sub run {
    my ($self, %options) = @_;
        
    my $result = apps::apcupsd::local::mode::libgetdata::getdata($self);
    my $exit = $self->{perfdata}->threshold_check(value => $result, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf($self->{option_results}->{searchpattern} . ": %f", $result));

    $self->{output}->perfdata_add(label => $self->{option_results}->{searchpattern},
                                  value => $result,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical')
                                  );
    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check apcupsd Status

=over 8

=item B<--apchost>

IP used by apcupsd

=item B<--apcport>

Port used by apcupsd

=item B<--warning>

Warning Threshold

=item B<--critical>

Critical Threshold

=item B<--remote>

If you dont wanna install the apcupsd client on your local system you can run it remotely with 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=back

=cut
