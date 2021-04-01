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

package apps::java::weblogic::jmx::mode::workmanager;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_threshold_output {
    my ($self, %options) = @_;

    return $self->{instance_mode}->get_severity(section => 'health', value => $self->{result_values}->{health_state});
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{health_state} = $options{new_datas}->{$self->{instance} . '_health_state'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'wm', type => 1, cb_prefix_output => 'prefix_wm_output', message_multiple => 'All WorkerManagers are ok' }
    ];
    
    $self->{maps_counters}->{wm} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'health_state' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                output_template => 'State : %s', output_error_template => 'State : %s',
                output_use => 'health_state',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_threshold_output'),
            }
        },
        { label => 'request-completed', set => {
                key_values => [ { name => 'completed', diff => 1 }, { name => 'display' } ],
                output_template => 'Requests completed : %s',
                perfdatas => [
                    { label => 'request_completed', value => 'completed', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'request-pending', set => {
                key_values => [ { name => 'pending' }, { name => 'display' } ],
                output_template => 'Requests pending : %s',
                perfdatas => [
                    { label => 'request_pending', value => 'pending', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'thread-stuck', set => {
                key_values => [ { name => 'stuck' }, { name => 'display' } ],
                output_template => 'Threads stuck : %s',
                perfdatas => [
                    { label => 'thread_stuck', value => 'stuck', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_wm_output {
    my ($self, %options) = @_;
    
    return "WorkerManager '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "filter-application:s"    => { name => 'filter_application' },
        "filter-name:s"           => { name => 'filter_name' },
        "filter-runtime:s"        => { name => 'filter_runtime' },
        "threshold-overload:s@"   => { name => 'threshold_overload' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
}

my $thresholds = {
    health => [
        ['HEALTH_OK', 'OK'],
        ['HEALTH_WARNING', 'WARNING'],
        ['HEALTH_CRITICAL', 'CRITICAL'],
        ['HEALTH_FAILED', 'CRITICAL'],
        ['HEALTH_OVERLOADED', 'CRITICAL'],
        ['LOW_MEMORY_REASON', 'CRITICAL'],
    ],
};

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default

    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }

    return $status;
}

my %map_state = (
    0 => 'HEALTH_OK',
    1 => 'HEALTH_WARNING',
    2 => 'HEALTH_CRITICAL',
    3 => 'HEALTH_FAILED',
    4 => 'HEALTH_OVERLOADED',
    5 => 'LOW_MEMORY_REASON',
);

sub manage_selection {
    my ($self, %options) = @_;

    my $request = [
         { mbean => 'com.bea:ApplicationRuntime=*,Name=*,ServerRuntime=*,Type=WorkManagerRuntime',
           attributes => [ { name => 'HealthState' }, { name => 'StuckThreadCount' }, { name => 'CompletedRequests' }, { name => 'PendingRequests' } ] }
    ];
    my $result = $options{custom}->get_attributes(request => $request, nothing_quit => 1);

    $self->{wm} = {};
    foreach my $mbean (keys %{$result}) {
        next if ($mbean !~ /ApplicationRuntime=(.*?),Name=(.*?),ServerRuntime=(.*?),/);
        my ($app, $name, $runtime) = ($1, $2, $3);
        my $health_state = defined($map_state{$result->{$mbean}->{HealthState}->{state}}) ?
                            $map_state{$result->{$mbean}->{HealthState}->{state}} : 'unknown';

        if (defined($self->{option_results}->{filter_application}) && $self->{option_results}->{filter_application} ne '' &&
            $app !~ /$self->{option_results}->{filter_application}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $app . "': no matching filter application.");
            next;
        }
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter name.");
            next;
        }
        if (defined($self->{option_results}->{filter_runtime}) && $self->{option_results}->{filter_runtime} ne '' &&
            $runtime !~ /$self->{option_results}->{filter_runtime}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $runtime . "': no matching filter runtime.");
            next;
        }

        $self->{wm}->{$app . '/' . $name . '/' . $runtime} = {
            health_state => $health_state, 
            display => $app . '/' . $name . '/' . $runtime,
            completed => $result->{$mbean}->{CompletedRequests}, 
            pending => $result->{$mbean}->{PendingRequests},
            stuck => $result->{$mbean}->{StuckThreadCount}
        };
    }

    if (scalar(keys %{$self->{wm}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }

     $self->{cache_name} = "weblogic_" . $self->{mode} . '_' . md5_hex($self->{connector}->{url})  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_application}) ? md5_hex($self->{option_results}->{filter_application}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_runtime}) ? md5_hex($self->{option_results}->{filter_runtime}) : md5_hex('all'));

}

1;

__END__

=head1 MODE

Check WebLogic WorkManagers.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'thread-stuck', 'request-completed', 'request-pending'.

=item B<--critical-*>

Threshold critical.
Can be: 'thread-stuck', 'request-completed', 'request-pending'.

=item B<--filter-application>

Filter by application runtime.

=item B<--filter-name>

Filter by name (regexp can be used).

=item B<--filter-runtime>

Filter by server runtime.

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='health,CRITICAL,^(?!(HEALTH_OK)$)'

=back

=cut

