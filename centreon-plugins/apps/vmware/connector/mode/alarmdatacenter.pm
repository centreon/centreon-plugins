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

package apps::vmware::connector::mode::alarmdatacenter;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;

sub custom_status_threshold {
    my ($self, %options) = @_;
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        my $label = $self->{label};
        $label =~ s/-/_/g;
        if (defined($self->{instance_mode}->{option_results}->{'critical_' . $label}) && $self->{instance_mode}->{option_results}->{'critical_' . $label} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{'critical_' . $label}") {
            $self->{instance_mode}->{dc_critical}++;
            $status = 'critical';
        } elsif (defined($self->{instance_mode}->{option_results}->{'warning_' . $label}) && $self->{instance_mode}->{option_results}->{'warning_' . $label} ne '' &&
                 eval "$self->{instance_mode}->{option_results}->{'warning_' . $label}") {
            $self->{instance_mode}->{dc_warning}++;
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'alarm [%s] [%s] [%s] [%s] %s/%s', 
        $self->{result_values}->{status},
        $self->{result_values}->{type},
        $self->{result_values}->{entity_name},
        $self->{result_values}->{time},
        $self->{result_values}->{name},
        $self->{result_values}->{description}
    );

    return $msg;
}

sub custom_dcmetrics_perfdata {
    my ($self, %options) = @_;

    my $extra_label;
    # We do it manually. Because we have only 1 instance in group.
    if (scalar(keys %{$self->{instance_mode}->{datacenter}}) > 1 || $self->{output}->use_new_perfdata()) {
        $extra_label = $self->{result_values}->{name};
    }
    
    $self->{output}->perfdata_add(
        label => 'alarm_' . $self->{result_values}->{label_ref},
        nlabel => 'datacenter.alarms.' . $self->{result_values}->{label_ref} . '.current.count',
        instances => $extra_label,
        value => $self->{result_values}->{alarm_value},
        min => 0
    );
}

sub custom_dcmetrics_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{label_ref} = $options{extra_options}->{label_ref};
    $self->{result_values}->{alarm_value} = $self->{instance_mode}->{'dc_' . $options{extra_options}->{label_ref}};
    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'datacenter', type => 2, cb_prefix_output => 'prefix_datacenter_output', cb_long_output => 'datacenter_long_output', message_multiple => 'All datacenters are ok', 
            group => [ 
                { name => 'alarm', cb_init => 'alarm_reset', skipped_code => { -11 => 1 } },
                { name => 'dc_metrics', display => 0, skipped_code => { -11 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total-alarm-warning', nlabel => 'datacenter.alarms.warning.current.count', set => {
                key_values => [ { name => 'yellow' } ],
                output_template => '%s warning alarm(s) found(s)',
                perfdatas => [
                    { label => 'total_alarm_warning', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'total-alarm-critical', nlabel => 'datacenter.alarms.critical.current.count', set => {
                key_values => [ { name => 'red' } ],
                output_template => '%s critical alarm(s) found(s)',
                perfdatas => [
                    { label => 'total_alarm_critical', template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{alarm} = [
        { label => 'status', threshold => 0, set => {
                key_values => [
                    { name => 'entity_name' }, { name => 'status' }, 
                    { name => 'time' }, { name => 'description' }, { name => 'name' }, { name => 'type' }, { name => 'since' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold')
            }
        },
    ];
    
    $self->{maps_counters}->{dc_metrics} = [
        { label => 'alarm-warning', threshold => 0, set => {
                key_values => [ { name => 'name' }  ],
                output_template => '',
                closure_custom_threshold_check => sub { return 'ok' },
                closure_custom_calc => $self->can('custom_dcmetrics_calc'), closure_custom_calc_extra_options => { label_ref => 'warning' },
                closure_custom_perfdata => $self->can('custom_dcmetrics_perfdata')
            }
        },
        { label => 'alarm-critical', threshold => 0, set => {
                key_values => [ { name => 'name' }  ],
                output_template => '',
                closure_custom_threshold_check => sub { return 'ok' },
                closure_custom_calc => $self->can('custom_dcmetrics_calc'), closure_custom_calc_extra_options => { label_ref => 'critical' },
                closure_custom_perfdata => $self->can('custom_dcmetrics_perfdata')
            }
        }
    ];
}

sub prefix_datacenter_output {
    my ($self, %options) = @_;

    return "Datacenter '" . $options{instance_value}->{display} . "' ";
}

sub alarm_reset {
    my ($self, %options) = @_;
    
    $self->{dc_warning} = 0;
    $self->{dc_critical} = 0;
}

sub datacenter_long_output {
    my ($self, %options) = @_;

    return "checking datacenter '" . $options{instance_value}->{display} . "'";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "datacenter:s"            => { name => 'datacenter' },
        "filter"                  => { name => 'filter' },
        "filter-time:s"           => { name => 'filter_time', },
        "memory"                  => { name => 'memory', },
        "warning-status:s"        => { name => 'warning_status', default => '%{status} =~ /yellow/i' },
        "critical-status:s"       => { name => 'critical_status', default => '%{status} =~ /red/i' },
    });
    
    centreon::plugins::misc::mymodule_load(output => $self->{output}, module => 'Date::Parse',
                                           error_msg => "Cannot load module 'Date::Parse'.");
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

    $self->{global} = { yellow => 0, red => 0 };
    $self->{datacenter} = {};
    my $response = $options{custom}->execute(params => $self->{option_results},
        command => 'alarmdatacenter');

    my $last_time;
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => "cache_vmware_" . $options{custom}->get_id() . '_' . $self->{mode});
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }

    my ($i, $current_time) = (1, time());
    foreach my $datacenter_id (keys %{$response->{data}}) {
        my $datacenter_name = $response->{data}->{$datacenter_id}->{name};
        $self->{datacenter}->{$datacenter_name} = { display => $datacenter_name, alarm => {}, dc_metrics => { 1 => { name => $datacenter_name } } };
        
        foreach (keys %{$response->{data}->{$datacenter_id}->{alarms}}) {
            my $create_time = Date::Parse::str2time($response->{data}->{$datacenter_id}->{alarms}->{$_}->{time});
            if (!defined($create_time)) {
                $self->{output}->output_add(severity => 'UNKNOWN',
                                                       short_msg => "Can't Parse date '" . $response->{data}->{$datacenter_id}->{alarms}->{$_}->{time} . "'");
                next;
            }

            next if (defined($self->{option_results}->{memory}) && defined($last_time) && $last_time > $create_time);

            my $diff_time = $current_time - $create_time;
            if (defined($self->{option_results}->{filter_time}) && $self->{option_results}->{filter_time} ne '') {
                next if ($diff_time > $self->{option_results}->{filter_time});
            }

            $self->{datacenter}->{$datacenter_name}->{alarm}->{$i} = { %{$response->{data}->{$datacenter_id}->{alarms}->{$_}}, since => $diff_time };
            $self->{global}->{$response->{data}->{$datacenter_id}->{alarms}->{$_}->{status}}++;
            $i++;
        }
    }

    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->write(data => { last_time => $current_time });
    }
}

1;

__END__

=head1 MODE

Check datacenter alarms (red an yellow).

=over 8

=item B<--datacenter>

Datacenter to check.
If not set, we check all datacenters.

=item B<--filter>

Datacenter is a regexp.

=item B<--filter-time>

Don't check alarm older (value in seconds).

=item B<--memory>

Check new alarms only.

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /yellow/i).
Can used special variables like: %{status}, %{name}, %{entity}, %{type}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /red/i').
Can used special variables like: %{status}, %{name}, %{entity}, %{type}.

=item B<--warning-*>

Threshold warning.
Can be: 'total-alarm-warning', 'total-alarm-critical'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-alarm-warning', 'total-alarm-critical'.

=back

=cut
