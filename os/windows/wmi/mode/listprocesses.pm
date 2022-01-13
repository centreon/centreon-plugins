#
# Copyright 2021 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# servic performance.
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

package os::windows::wmi::mode::listprocesses;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my %map_status = (
    0 => 'running',
    1 => 'other',
    2 => 'ready',
    3 => 'running',
    4 => 'blocked',
);

sub manage_selection {
    my ($self, %options) = @_;

    my $WQL = 'select ExecutionState,Name,CommandLine,ExecutablePath,Handle from Win32_Process';
    
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

    my $results = {};
    while ($result =~ /^.*?;.*?;(\d+);(\d+);(.*?)$/msg) {
        my ($status, $pid, $name) = ($1, $2, $3);
        next if ($name =~ /System Idle Process/);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $results->{$pid} = { 
            name   => $name, 
            status => $status,
            pid    => $pid 
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;
  
    my $results = $self->manage_selection(%options);
    foreach (sort keys %$results) {
        $self->{output}->output_add(long_msg => '[name = ' . $results->{$_}->{name} .
            "] [status = " . $map_status{$results->{$_}->{status}} .
            "] [pid = " . $results->{$_}->{pid} ."]"
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List processes:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'status', 'pid']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach (sort keys %$results) {
        $self->{output}->add_disco_entry(
            name   => $results->{$_}->{name},
            status => $map_status{$results->{$_}->{status}},
            pid    => $results->{$_}->{pid}
        );
    }
}

1;

__END__

=head1 MODE

List processes.

=over 8

=item B<--filter-name>

Filter by service name (can be a regexp).

=item B<--add-stats>

Add cpu and memory stats.

=back

=cut
