#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package os::aix::local::mode::process;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use centreon::plugins::misc qw/trim is_excluded/;

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'Process [command => %s] [arg: %s] [state: %s] [elapsed => %s]', 
        $self->{result_values}->{cmd},
        $self->{result_values}->{args},
        $self->{result_values}->{state}, 
        $self->{result_values}->{elapsed}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'alarms', type => 2, message_multiple => '0 process problem detected', format_output => '%s process(es) problem(s) detected', 
          display_counter_problem => { nlabel => 'processes.alerts.count', min => 0 },
          group => [ { name => 'alarm', skipped_code => { -11 => 1 } } ]
        }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'processes.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Number of current processes: %s',
                perfdatas => [
                    { value => 'total', template => '%s', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{alarm} = [
        { label => 'status', threshold => 0, set => {
                key_values => [
                    { name => 'ppid' }, { name => 'state' },
                    { name => 'elapsed' }, { name => 'cmd' }, { name => 'args' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-command:s'  => { name => 'filter_command',  default => '' },
        'filter-arg:s'      => { name => 'filter_arg',      default => '' },
        'filter-state:s'    => { name => 'filter_state',    default => '' },
        'filter-ppid:s'     => { name => 'filter_ppid',     default => '' },
        'warning-status:s'  => { name => 'warning_status',  default => '' },
        'critical-status:s' => { name => 'critical_status', default => '' },
        'show-all'          => { name => 'show_all' },

    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);

    # show-all implies verbose
    $self->{output}->{option_results}->{verbose} = 1 if $self->{option_results}->{show_all};
}

my %state_map = (
    Z => 'Canceled',
    O => 'Nonexistent',
    A => 'Active',
    W => 'Swapped',
    I => 'Idle',
    T => 'Stopped',
    R => 'Running',
    S => 'Sleeping',
);

sub get_time_seconds {
    my ($self, %options) = @_;

    my $time = $options{value};
    # Format: [[dd-]hh:]mm:ss
    my @values = split /:/, $time;
    my ($seconds, $min, $lpart) = (pop @values, pop @values, pop @values);
    my $total_seconds_elapsed = $seconds + ($min * 60);
    if (defined($lpart)) {
        my ($day, $hour) = split /-/, $lpart;
        if (!defined($hour)) {
            $hour = $day;
            $day = undef;
        }
        if (defined($hour)) {
            $total_seconds_elapsed += ($hour * 60 * 60);
        }
        if (defined($day)) {
            $total_seconds_elapsed += ($day * 86400);
        }
    }

    return $total_seconds_elapsed;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'ps',
        command_options => '-e -o state -o ===%t===%p===%P=== -o comm:50 -o ===%a 2>&1'
    );

    $self->{alarms}->{global} = { alarm => {} };
    my @lines = split /\n/, $stdout;
    my $line = shift @lines;
    foreach my $line (@lines) {
        next if ($line !~ /^(.*?)===(.*?)===(.*?)===(.*?)===(.*?)===(.*)$/);
        my ($state, $elapsed, $pid, $ppid, $cmd, $args) = (
            trim($1), trim($2), trim($3),
            trim($4), trim($5), trim($6)
        );

        next if is_excluded($cmd, $self->{option_results}->{filter_command});
        next if is_excluded($args, $self->{option_results}->{filter_arg});
        next if is_excluded($state_map{$state} || '', $self->{option_results}->{filter_state});
        next if is_excluded($ppid, $self->{option_results}->{filter_ppid});

        my %item = (
            ppid => $ppid, 
            state => $state_map{$state},
            elapsed => $self->get_time_seconds(value => $elapsed), 
            cmd => $cmd,
            args => $args
        );

        $self->{output}->output_add(severity => 'OK', long_msg => custom_status_output({ result_values => \%item }))
            if $self->{option_results}->{show_all};

        $self->{alarms}->{global}->{alarm}->{$pid} = \%item;
    }

    $self->{global} = { total => scalar(keys %{$self->{alarms}->{global}->{alarm}}) };
}

1;

__END__

=head1 MODE

Check AIX processes.
Command used: ps -e -o state -o ===%t===%p===%P=== -o comm:50 -o ===%a 2>&1

=over 8

=item B<--filter-command>

Filter process commands (regexp can be used).

=item B<--filter-arg>

Filter process arguments (regexp can be used).

=item B<--filter-ppid>

Filter process C<ppid> (regexp can be used).

=item B<--filter-state>

Filter process states (regexp can be used).
You can use: 'Canceled', 'Nonexistent', 'Active',
'Swapped', 'Idle', 'Stopped', 'Running', 'Sleeping'.

=item B<--show-all>

Display all processes (not only problems). Implies --verbose.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '')
You can use the following variables: %{ppid}, %{state}, %{elapsed}, %{cmd}, %{args}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '').
You can use the following variables: %{ppid}, %{state}, %{elapsed}, %{cmd}, %{args}

=item B<--warning-status>

Threshold.

=item B<--critical-status>

Threshold.

=item B<--warning-total>

Threshold.

=item B<--critical-total>

Threshold.

=back

=cut
