#
# Copyright 2024 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and cluster monitoring for
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

package hardware::devices::hms::netbiter::argos::restapi::mode::alarms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Date::Parse;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Alarms: ';
}

sub prefix_alarms_output {
    my ($self, %options) = @_;
    return sprintf('[%s] Alarm name: "%s", Device name: "%s" ', $options{instance_value}->{timestamp}, $options{instance_value}->{display}, $options{instance_value}->{device_name});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'alarms', type => 1, cb_prefix_output => 'prefix_alarms_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'alarms-total', nlabel => 'alarms.total.count', set => {
                key_values => [ { name => 'total' }  ],
                output_template => 'total current: %s',
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{alarms} = [
        { label => 'alarm-active',
            type => 2,
            critical_default => '%{active} =~ "true"',
            set => {
                key_values => [ { name => 'active' } ],
                output_template => 'active: %s',
                display_ok => 0,
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'alarm-acked',
            type => 2,
            warning_default => '%{acked} =~ "false"',
            set => {
                key_values => [ { name => 'acked' } ],
                output_template => 'acknowledged: %s',
                display_ok => 0,
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'alarm-duration', nlabel => 'alarm.duration.seconds',
            type => 1,
            set => {
                key_values => [ { name => 'duration' }, { name => 'display' } ],
                output_template => 'duration: %ds',
                display_ok => 0,
                perfdatas => [ { template => '%d', min => 0, unit => 's', label_extra_instance => 1, instance_use => 'display' } ]
            }
        },
        { label => 'alarm-severity',
            type => 1,
            set => {
                key_values => [ { name => 'severity' } ],
                output_template => 'severity: %s',
                display_ok => 0,
                closure_custom_perfdata => sub { return 0; }
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-acked'      => { name => 'filter_acked' },
        'filter-active'     => { name => 'filter_active' },
        'filter-severity:s' => { name => 'filter_severity' },
        'system-id:s'       => { name => 'system_id' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{filter_severity}) && $self->{option_results}->{filter_severity} ne '') {
        if (lc($self->{option_results}->{filter_severity}) !~ '/critical|major|minor|warning|cleared/') {
            $self->{output}->add_option_msg(short_msg => 'Unknown severity "' . $self->{option_results}->{filter_severity} . '"');
            $self->{output}->option_exit();
        }
        $self->{severity} = lc($self->{option_results}->{filter_severity});
    }
    if (!(defined($self->{option_results}->{system_id})) || $self->{option_results}->{system_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --system-id option.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global}->{total} = 0;

    my $severity_mapping = {
        critical => '1',
        major    => '2',
        minor    => '3',
        warning  => '4',
        cleared  => '5'
    };
    my $active_alarms = 'false';
    my $url = '/system/' . $self->{option_results}->{system_id} . '/alarm';
    my $get_params;

    if (defined($self->{severity})) {
        my $severity_level = $severity_mapping->{$self->{severity}};
        push @$get_params, 'severity=' . $severity_level;
    }
    if (defined($self->{option_results}->{filter_acked})) {
        push @$get_params, 'acked=false';
    }
    if (defined($self->{option_results}->{filter_active})) {
        $active_alarms = 'true';
    }
    push @$get_params, 'active=' . $active_alarms;

    my $result = $options{custom}->request_api(
        request => $url,
        get_params => $get_params
    );

    foreach (@{$result}) {
        my $timestamp = str2time($_->{timestamp}, 'GMT');
        $self->{alarms}->{$_->{id}} = {
            acked       => ($_->{acked}) ? 'true' : 'false',
            active      => ($_->{active}) ? 'true' : 'false',
            device_name => $_->{deviceName},
            duration    => time() - $timestamp,
            display     => $_->{name},
            id          => $_->{id},
            severity    => $_->{severity},
            timestamp   => POSIX::strftime('%d-%m-%Y %H:%M:%S %Z', localtime($timestamp))
        };
    }

    $self->{global}->{total} = scalar (keys %{$self->{alarms}});
}

1;

__END__

=head1 MODE

Check Netbiter alarms using Argos RestAPI.

Example:
perl centreon_plugins.pl --plugin=hardware::devices::hms::netbiter::argos::restapi::plugin --mode=alarms
--access-key='ABCDEFG1234567890' --system-id='XYZ123' --filter-active --verbose

More information on'https://apidocs.netbiter.net/?page=methods&show=getSystemAlarms'.

=over 8

=item B<--system-id>

Set the Netbiter Argos System ID (mandatory).

=item B<--filter-acked>

Hide acknowledged alarms.

=item B<--filter-active>

Only show active alarms.

=item B<--filter-severity>

Only show alarms with a given severity level.
Can be: 'critical', 'major', 'minor', 'warning', 'cleared'.
Only one value can be set (no multiple values).

=item B<--warning-active-status>

Set warning threshold for active status (default: '').
Typical syntax: --warning-active-status='%{active} =~ "true"'

=item B<--critical-active-status>

Set critical threshold for active status (default: '%{active} =~ "true"').
Typical syntax: --critical-active-status='%{active} =~ "true"'

=item B<--warning-acked-status>

Set warning threshold for acked status (default: '%{acked} =~ "false"').
Typical syntax: --warning-acked-status='%{acked} =~ "false"'

=item B<--critical-acked-status>

Set critical threshold for acked status (default: '').
Typical syntax: --critical-acked-status='%{acked} =~ "false"'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'warning-alarms-total' (count) 'critical-alarms-total' (count),
'warning-alarm-duration' (s), 'critical-alarm-duration' (s),
'warning-alarm-severity' (level from 0 to 5), critical-alarm-severity (level from 0 to 5).

=back

=cut
