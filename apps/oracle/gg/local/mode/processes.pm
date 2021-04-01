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

package apps::oracle::gg::local::mode::processes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output { 
    my ($self, %options) = @_;

    return sprintf('status: %s', 
        $self->{result_values}->{status}
    );
}

sub prefix_process_output {
    my ($self, %options) = @_;

    return sprintf(
        "Process '%s' ",
        $options{instance_value}->{name}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'processes', type => 1, cb_prefix_output => 'prefix_process_output', message_multiple => 'All processes are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{processes} = [
        { label => 'status', type => 2, critical_default => '%{status} =~ /ABENDED/i', set => {
                key_values => [ { name => 'status' }, { name => 'group' }, { name => 'type' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'lag', nlabel => 'process.lag.seconds', set => {
                key_values => [ { name => 'lag_secs' }, { name => 'lag_human' } ],
                output_template => 'lag: %s',
                output_use => 'lag_human',
                perfdatas => [
                    { template => '%s', min => 0, unit => 's', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'time-checkpoint', nlabel => 'process.time.checkpoint.seconds', set => {
                key_values => [ { name => 'time_secs' }, { name => 'time_human' } ],
                output_template => 'time since checkpoint: %s',
                output_use => 'time_human',
                perfdatas => [
                    { template => '%s', min => 0, unit => 's', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'  => { name => 'filter_name' },
        'filter-group:s' => { name => 'filter_group' },
        'filter-type:s'  => { name => 'filter_type' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my ($stdout) = $options{custom}->execute_command(
        commands => 'INFO ALL'
    );

    $self->{processes} = {};
    while ($stdout =~ /^(MANAGER|EXTRACT|REPLICAT)\s+(\S+)(.*?)(?:\n|\Z)/msig) {
        my ($type, $status, $data) = ($1, $2, $3);

        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $type !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping process '" . $type . "': no matching filter.", debug => 1);
            next;
        }

        if ($type eq 'MANAGER') {
            $self->{processes}->{$type} = {
                status => $status,
                name => $type,
                type => $type,
                group => '-'
            };
            next;
        }

        next if ($data !~ /\s*(\S+)\s*(?:(\d+:\d+:\d+)\s+(\d+:\d+:\d+))?/);
        
        my ($group, $lag, $time) = ($1, $2, $3);
        my $name = $type . ':' . $group;
        if (defined($self->{option_results}->{filter_group}) && $self->{option_results}->{filter_group} ne '' &&
            $group !~ /$self->{option_results}->{filter_group}/) {
            $self->{output}->output_add(long_msg => "skipping process '" . $group . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping process '" . $group . "': no matching filter.", debug => 1);
            next;
        }

        $self->{processes}->{$name} = {
            status => $status,
            name => $name,
            type => $type,
            group => $group
        };

        next if ($status eq 'STOPPED');

        if (defined($lag)) {
            my ($hour, $min, $sec) = split(/:/, $lag);
            my $lag_secs = ($hour * 3600) + ($min * 60) + $sec;
            $self->{processes}->{$name}->{lag_secs} = $lag_secs;
            $self->{processes}->{$name}->{lag_human} = centreon::plugins::misc::change_seconds(value => $self->{processes}->{$name}->{lag_secs});
        }
        if (defined($time)) {
            my ($hour, $min, $sec) = split(/:/, $time);
            my $time_secs = ($hour * 3600) + ($min * 60) + $sec;
            $self->{processes}->{$name}->{time_secs} = $time_secs;
            $self->{processes}->{$name}->{time_human} = centreon::plugins::misc::change_seconds(value => $self->{processes}->{$name}->{time_secs});
        }
    }

}

1;

__END__

=head1 MODE

Check processes.

=over 8

=item B<--filter-name>

Filter processes by name (can be a regexp).

name is the following concatenation: type:group (eg.: EXTRACT:DB_test)

=item B<--filter-group>

Filter processes by group (can be a regexp).

=item B<--filter-type>

Filter processes by type (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{name}, %{group}, %{type}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{name}, %{group}, %{type}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /ABENDED/i').
Can used special variables like: %{status}, %{name}, %{group}, %{type}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be:  'lag' (s), 'time-checkpoint' (s).

=back

=cut
