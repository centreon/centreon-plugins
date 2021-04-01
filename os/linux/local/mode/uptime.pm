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

package os::linux::local::mode::uptime;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use POSIX;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'warning:s'  => { name => 'warning', default => '' },
        'critical:s' => { name => 'critical', default => '' },
        'seconds'    => { name => 'seconds' }
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
        command => 'cat',
        command_options => '/proc/uptime 2>&1'
    );

    my ($uptime, $idletime);
    if ($stdout =~ /([0-9\.]+)\s+([0-9\.]+)/) {
        ($uptime, $idletime) = ($1, $2)
    }
    
    if (!defined($uptime) || !defined($idletime)) {
        $self->{output}->add_option_msg(short_msg => 'Some informations missing.');
        $self->{output}->option_exit();
    }

    my $exit_code = $self->{perfdata}->threshold_check(
        value => floor($uptime),
        threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]
    );
    $self->{output}->perfdata_add(
        label => 'uptime', unit => 's',
        value => floor($uptime),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
        min => 0
    );

    $self->{output}->output_add(
        severity => $exit_code,
        short_msg => sprintf(
            "System uptime is: %s",
            defined($self->{option_results}->{seconds}) ? floor($uptime) . " seconds" : floor($uptime / 86400) . " days"
        )
    );

    $self->{output}->display();
    $self->{output}->exit();
    
}

1;

__END__

=head1 MODE

Check system uptime.

Command used: cat /proc/uptime 2>&1

=over 8

=item B<--warning>

Threshold warning in seconds.

=item B<--critical>

Threshold critical in seconds.

=item B<--seconds>

Display uptime in seconds.

=back

=cut
