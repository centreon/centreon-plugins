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

package cloud::aws::cloudwatch::mode::getalarms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'alarm [name: %s] [state: %s] [metric: %s] [reason: %s] %s',
        $self->{result_values}->{alarm_name},
        $self->{result_values}->{state_value}, $self->{result_values}->{metric_name}, 
        $self->{result_values}->{state_reason}, centreon::plugins::misc::change_seconds(value => $self->{result_values}->{last_update})
    );
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{alarm_name} = $options{new_datas}->{$self->{instance} . '_AlarmName'};
    $self->{result_values}->{state_value} = $options{new_datas}->{$self->{instance} . '_StateValue'};
    $self->{result_values}->{metric_name} = $options{new_datas}->{$self->{instance} . '_MetricName'};
    $self->{result_values}->{last_update} = $options{new_datas}->{$self->{instance} . '_LastUpdate'};
    $self->{result_values}->{state_reason} = $options{new_datas}->{$self->{instance} . '_StateReason'};
    return 0;
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'alarms', type => 2, message_multiple => '0 problem(s) detected', display_counter_problem => { label => 'alerts', min => 0 },
          group => [ { name => 'alarm', skipped_code => { -11 => 1 } } ] 
        }
    ];

    $self->{maps_counters}->{alarm} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'AlarmName' }, { name => 'StateValue' }, { name => 'MetricName' }, { name => 'StateReason' }, { name => 'LastUpdate' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-alarm-name:s' => { name => 'filter_alarm_name' },
        'warning-status:s'    => { name => 'warning_status', default => '%{state_value} =~ /INSUFFICIENT_DATA/i' },
        'critical-status:s'   => { name => 'critical_status', default => '%{state_value} =~ /ALARM/i' },
        'memory'              => { name => 'memory' },
    });

    centreon::plugins::misc::mymodule_load(
        output => $self->{output}, module => 'Date::Parse',
        error_msg => "Cannot load module 'Date::Parse'."
    );
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->check_options(%options);
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{alarms}->{global} = { alarm => {} };
    my $alarm_results = $options{custom}->cloudwatch_get_alarms();

    my $last_time;
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => 'cache_aws_' . $self->{mode} . '_' . $self->{option_results}->{region});
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }

    my ($i, $current_time) = (1, time());
    foreach my $alarm (@{$alarm_results}) {        
        my $create_time = Date::Parse::str2time($alarm->{StateUpdatedTimestamp});
        if (!defined($create_time)) {
            $self->{output}->output_add(
                severity => 'UNKNOWN',
                short_msg => "Can't Parse date '" . $alarm->{StateUpdatedTimestamp} . "'"
            );
            next;
        }

        next if (defined($self->{option_results}->{memory}) && defined($last_time) && $last_time > $create_time);
        if (defined($self->{option_results}->{filter_alarm_name}) && $self->{option_results}->{filter_alarm_name} ne '' &&
            $alarm->{AlarmName} !~ /$self->{option_results}->{filter_alarm_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $alarm->{AlarmName} . "': no matching filter.", debug => 1);
            next;
        }

        my $diff_time = $current_time - $create_time;

        $self->{alarms}->{global}->{alarm}->{$i} = { 
            %$alarm,
            LastUpdate => $diff_time,
        };
        $i++;
    }

    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->write(data => { last_time => $current_time });
    }
}

1;

__END__

=head1 MODE

Check cloudwatch alarms.

=over 8

=item B<--filter-alarm-name>

Filter by alarm name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '%{state_value} =~ /INSUFFICIENT_DATA/i')
Can used special variables like: %{alarm_name}, %{state_value}, %{metric_name}, %{last_update}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state_value} =~ /ALARM/i').
Can used special variables like: %{alarm_name}, %{state_value}, %{metric_name}, %{last_update}

=item B<--memory>

Only check new alarms.

=back

=cut
