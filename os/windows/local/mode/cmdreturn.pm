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

package os::windows::local::mode::cmdreturn;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use Time::HiRes qw(gettimeofday tv_interval);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'warning-time:s'    => { name => 'warning_time' },
        'critical-time:s'   => { name => 'critical_time' },
        'timeout:s'         => { name => 'timeout', default => 30 },
        'command:s'         => { name => 'command' },
        'command-path:s'    => { name => 'command_path' },
        'command-options:s' => { name => 'command_options' },
        'manage-returns:s'  => { name => 'manage_returns', default => '' },
    });

    $self->{manage_returns} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (!defined($self->{option_results}->{command})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify command option.");
       $self->{output}->option_exit();
    }
    
    foreach my $entry (split(/#/, $self->{option_results}->{manage_returns})) {
        next if (!($entry =~ /(.*?),(.*?),(.*)/));
        next if (!$self->{output}->is_litteral_status(status => $2));
        if ($1 ne '') {
            $self->{manage_returns}->{$1} = {return => $2, msg => $3};
        } else {
            $self->{manage_returns}->{default} = {return => $2, msg => $3};
        }
    }
    if ($self->{option_results}->{manage_returns} eq '' || scalar(keys %{$self->{manage_returns}}) == 0) {
       $self->{output}->add_option_msg(short_msg => "Need to specify manage-returns option correctly.");
       $self->{output}->option_exit();
    }
    
    if (($self->{perfdata}->threshold_validate(label => 'warning-time', value => $self->{option_results}->{warning_time})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning_time} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-time', value => $self->{option_results}->{critical_time})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical_time} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    my $timing0 = [gettimeofday];
    my ($stdout, $exit_code) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options},
        no_quit => 1
    );
    my $timeelapsed = tv_interval($timing0, [gettimeofday]);
    
    my $long_msg = $stdout;
    $long_msg =~ s/\|/-/mg;
    $self->{output}->output_add(long_msg => $long_msg);
    
    if (defined($self->{manage_returns}->{$exit_code})) {
        $self->{output}->output_add(severity => $self->{manage_returns}->{$exit_code}->{return}, 
                                    short_msg => $self->{manage_returns}->{$exit_code}->{msg});
    } elsif (defined($self->{manage_returns}->{default})) {
        $self->{output}->output_add(severity => $self->{manage_returns}->{default}->{return}, 
                                    short_msg => $self->{manage_returns}->{default}->{msg});
    } else {
        $self->{output}->output_add(severity => 'UNKNWON', 
                                    short_msg => 'Exit code from command');
    }
    
    if (defined($exit_code)) {
        $self->{output}->perfdata_add(
            label => 'code',
            value => $exit_code
        );
    }
    
    my $exit = $self->{perfdata}->threshold_check(value => $timeelapsed,
        threshold => [ { label => 'critical-time', exit_litteral => 'critical' }, { label => 'warning-time', exit_litteral => 'warning' } ]);
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Response time %.3fs", $timeelapsed));
    }

    $self->{output}->perfdata_add(
        label => 'time', unit => 's',
        value => sprintf('%.3f', $timeelapsed),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_time'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_time'),
        min => 0
    );
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check command returns.

=over 8

=item B<--manage-returns>

Set action according command exit code.
Example: 0,OK,File xxx exist#1,CRITICAL,File xxx not exist#,UNKNOWN,Command problem

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--command>

Command to test (Default: none).

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: none).

=item B<--warning-time>

Threshold warning in seconds.

=item B<--critical-time>

Threshold critical in seconds.

=back

=cut
