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

package os::solaris::local::mode::hwraidctl;

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
        command => 'raidctl',
        command_options => '-S 2>&1',
        command_path => '/usr/sbin'
    );

    my $long_msg = $stdout;
    $long_msg =~ s/\|/~/mg;
    $self->{output}->output_add(long_msg => $long_msg);

    my $volumes_errors = 0;
    my $disks_errors = 0;
    my $volumes = '';
    my $disks = '';
    foreach (split(/\n/, $stdout)) {
        #1 "LSI_1030"
        #c1t2d0 2 0.2.0 0.3.0 1 OPTIMAL
        #0.0.0 GOOD
        #0.1.0 GOOD
        #0.2.0 GOOD
        #0.3.0 GOOD
        #4 "LSI_1030"

        # For Disk
        if (/^\s*(\S+)\s+(FAILED)$/i ) {
            my $disk = $1;

            $disks_errors++;
            $disks .= ' [' . $disk . '/FAILED' . ']';
        } elsif (/^\s*(\S+).*?(DEGRADED|FAILED)$/i) {
            $volumes_errors++;
            $volumes .= ' [' . $1 . '/' . $2 . ']';
        }
    }

    my ($exit_code) = $self->{perfdata}->threshold_check(
        value => $volumes_errors, 
        threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]
    );
    if ($volumes_errors > 0) {
        $self->{output}->output_add(
            severity => $exit_code,
            short_msg => sprintf("Some volumes problems:" . $volumes)
        );
    } else {
        $self->{output}->output_add(
            severity => 'OK', 
            short_msg => "No problems on volumes"
        );
    }

    ($exit_code) = $self->{perfdata}->threshold_check(
        value => $disks_errors, 
        threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]
    );
    if ($disks_errors > 0) {
        $self->{output}->output_add(
            severity => $exit_code,
            short_msg => sprintf("Some disks problems:" . $disks)
        );
    } else {
        $self->{output}->output_add(
            severity => 'OK', 
            short_msg => "No problems on disks"
        );
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check hardware raid status

Command used: '/usr/sbin/raidctl -S 2>&1'

=over 8

=item B<--warning>

Warning threshold.

=item B<--critical>

Critical threshold.

=back

=cut
