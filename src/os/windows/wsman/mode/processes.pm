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

package os::windows::wsman::mode::processes;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'process-status:s' => { name => 'process_status', default => 'running' },
        'process-name:s'   => { name => 'process_name' },
        'regexp-name'      => { name => 'regexp_name' },
        'warning:s'        => { name => 'warning' },
        'critical:s'       => { name => 'critical' }
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

my %map_process_status = (
    0 => 'running',
    1 => 'other', 
    2 => 'ready', 
    3 => 'running', 
    4 => 'blocked'
);

sub run {
    my ($self, %options) = @_;

    my $WQL = 'select Name,ExecutionState,CommandLine,ExecutablePath,Handle from Win32_Process';
    if (defined($self->{option_results}->{process_name}) && $self->{option_results}->{process_name} ne '') {
        if (defined($self->{option_results}->{regexp_name})) {
            $WQL .= ' where Name like "' . $self->{option_results}->{process_name} . '"';
        } else {
            $WQL .= ' where Name = "' . $self->{option_results}->{process_name} . '"';
        }
    }

    my $results = $options{wsman}->request(
        uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/*',
        wql_filter => $WQL,
        result_type => 'array'
    );

    #
    #CLASS: Win32_Process
    #CommandLine;ExecutablePath;ExecutionState;Handle;Name
    #C:\\Windows\\system32\\svchost.exe -k DcomLaunch -p;C:\\Windows\\system32\\svchost.exe;0;864;svchost.exe
    #"fontdrvhost.exe";C:\\Windows\\system32\\fontdrvhost.exe;0;884;fontdrvhost.exe
    #"fontdrvhost.exe";C:\\Windows\\system32\\fontdrvhost.exe;0;892;fontdrvhost.exe
    #C:\\Windows\\system32\\svchost.exe -k RPCSS -p;C:\\Windows\\system32\\svchost.exe;0;964;svchost.exe
    #
    my $detected = 0;
    foreach (@$results) {
        my $status = (!defined($_->{ExecutionState}) || $_->{ExecutionState} eq '') ? 0 : $_->{ExecutionState};
        $self->{output}->output_add(long_msg =>
            sprintf(
                "Process %s [status: %s] [name: %s]",
                $_->{Handle},
                $map_process_status{$status},
                $_->{Name}
            )
        );
        $detected++;
    }
    
    my $exit = $self->{perfdata}->threshold_check(
        value => $detected, 
        threshold => [
            { label => 'critical', exit_litteral => 'critical' }, 
            { label => 'warning', exit_litteral => 'warning' }
        ]
    );

    $self->{output}->output_add(
        severity => $exit,
        short_msg => "Number of current processes: $detected"
    );
    $self->{output}->perfdata_add(
        nlabel => 'processes.detected.count',
        value => $detected,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
        min => 0
    );

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
(default: 'running').

=item B<--process-name>

Filter process name.

=item B<--regexp-name>

Allows to use WQL wildcard to filter process 
name (with option --process-name).

=item B<--warning>

Warning threshold of matching processes detected.

=item B<--critical>

Critical threshold of matching processes detected.

=back

=cut
