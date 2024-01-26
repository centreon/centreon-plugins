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

package os::solaris::local::mode::fcconnected;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'warning:s'  => { name => 'warning' },
        'critical:s' => { name => 'critical' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

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

    my ($stdout) = $options{custom}->execute_command(
        command => 'luxadm',
        command_options => '-e port 2>&1',
        command_path => '/usr/sbin'
    );
    
    $self->{output}->output_add(
        severity => 'OK', 
        short_msg => "Fc connections are ok."
    );
    my $num_connected = 0;
    foreach (split /\n/, $stdout) {
        $self->{output}->output_add(long_msg => $_);
        if ($_ !~ /NOT CONNECTED/i) {
            $num_connected++;
        }
    }

    my ($exit_code) = $self->{perfdata}->threshold_check(
        value => $num_connected, 
        threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]
    );
    if (!$self->{output}->is_status(litteral => 1, value => $exit_code, compare => 'ok')) {
        $self->{output}->output_add(
            severity => $exit_code,
            short_msg => sprintf("Some cards are not connected (see additionnal info for more details)")
        );
    }
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check number of fiber channel connected (need sun/oracle driver and not Emulex/Qlogic).

Command used: '/usr/sbin/luxadm -e port 2>&1'

=over 8

=item B<--warning>

Warning threshold.

=item B<--critical>

Critical threshold.

=back

=cut
