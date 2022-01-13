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

package os::windows::wmi::mode::processcount;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;

my %map_process_status = (
    0 => 'running',
    1 => 'other', 
    2 => 'ready', 
    3 => 'running', 
    4 => 'blocked',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'process-status:s'        => { name => 'process_status', default => 'running' },
        'process-name:s'          => { name => 'process_name' },
        'regexp-name'             => { name => 'regexp_name' },
        'warning:s'               => { name => 'warning' },
        'critical:s'              => { name => 'critical' },
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

    my $WQL = 'select ExecutionState,Name,CommandLine,ExecutablePath,Handle from Win32_Process';
    if(defined($self->{option_results}->{process_name}) || $self->{option_results}->{process_name} ne '') {
        if(defined($self->{option_results}->{regexp_name})) {
            $WQL .= ' where Name like "' . $self->{option_results}->{process_name} . '"';
        } else {
            $WQL .= ' where Name = "' . $self->{option_results}->{process_name} . '"';
        }
    }
    my ($result, $exit_code) = $options{custom}->execute_command(
        query => $WQL,
        no_quit => 1
    );
    $result =~ s/\|/;/g;

    #
    #CLASS: Win32_Process
    #CommandLine;ExecutablePath;ExecutionState;Handle;Name
    #C:\\Windows\\system32\\svchost.exe -k DcomLaunch -p;C:\\Windows\\system32\\svchost.exe;0;864;svchost.exe
    #"fontdrvhost.exe";C:\\Windows\\system32\\fontdrvhost.exe;0;884;fontdrvhost.exe
    #"fontdrvhost.exe";C:\\Windows\\system32\\fontdrvhost.exe;0;892;fontdrvhost.exe
    #C:\\Windows\\system32\\svchost.exe -k RPCSS -p;C:\\Windows\\system32\\svchost.exe;0;964;svchost.exe
    #
    my $count = 0;
    while ($result =~ /^.*?;.*?;(\d+);(\d+);(.*?)$/msg) {
       my $status = $1;
       my $pid  = $2;
       my $name = $3;
       $count++;
       my $long_msg = sprintf("Process '%s'", $pid);
       $long_msg .= sprintf(" [status: %s]", $map_process_status{$status});
       $long_msg .= sprintf(" [name: %s]", $name);
       $self->{output}->output_add(long_msg => $long_msg);

    }
    
    my $num_processes_match = $count;
    my $exit = $self->{perfdata}->threshold_check(value => $num_processes_match, 
                                                  threshold => [ { label => 'critical', exit_litteral => 'critical' }, 
                                                                 { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => "Number of current processes running: $num_processes_match");
    $self->{output}->perfdata_add(label => 'nbproc',
                                  value => $num_processes_match,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check system number of processes.

=over 8

=item B<--process-status>

Filter process status. Can be a regexp. 
(Default: 'running').

=item B<--process-name>

Filter process name.

=item B<--regexp-name>

Allows to use WQL wildcard to filter process 
name (with option --process-name).

=item B<--warning>

Threshold warning of matching processes count.

=item B<--critical>

Threshold critical of matching processes count.

=back

=cut
