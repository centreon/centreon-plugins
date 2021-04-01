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

package network::freebox::restapi::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'wifi', type => 1, cb_prefix_output => 'prefix_wifi_output', message_multiple => 'All wifis are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'temperature-cpum', set => {
                key_values => [ { name => 'temp_cpum' } ],
                output_template => 'Temperature cpum : %s C',
                perfdatas => [
                    { label => 'temp_cpum', value => 'temp_cpum', template => '%s', 
                      unit => 'C' }
                ]
            }
        },
        { label => 'temperature-cpub', set => {
                key_values => [ { name => 'temp_cpub' } ],
                output_template => 'Temperature cpub : %s C',
                perfdatas => [
                    { label => 'temp_cpub', value => 'temp_cpub', template => '%s', 
                      unit => 'C' }
                ]
            }
        },
        { label => 'temperature-switch', set => {
                key_values => [ { name => 'temp_sw' } ],
                output_template => 'Temperature switch : %s C',
                perfdatas => [
                    { label => 'temp_sw', value => 'temp_sw', template => '%s', 
                      unit => 'C' }
                ]
            }
        },
        { label => 'fan-speed', set => {
                key_values => [ { name => 'fan_rpm' } ],
                output_template => 'fan speed : %s rpm',
                perfdatas => [
                    { label => 'fan_rpm', value => 'fan_rpm', template => '%s', 
                      min => 0, unit => 'rpm' }
                ]
            }
        },
        { label => 'disk-status', threshold => 0, set => {
                key_values => [ { name => 'disk_status' } ],
                closure_custom_calc => $self->can('custom_disk_status_calc'),
                closure_custom_output => $self->can('custom_disk_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
    
    $self->{maps_counters}->{wifi} = [
        { label => 'wifi-status', threshold => 0, set => {
                key_values => [ { name => 'wifi_status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_wifi_status_calc'),
                closure_custom_output => $self->can('custom_wifi_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub custom_disk_status_output {
    my ($self, %options) = @_;

    return 'Disk status : ' . $self->{result_values}->{status};
}

sub custom_disk_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_disk_status'};
    return 0;
}

sub custom_wifi_status_output {
    my ($self, %options) = @_;

    return "Wifi '" . $self->{result_values}->{display} . "' status : " . $self->{result_values}->{status};
}

sub custom_wifi_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_wifi_status'};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'warning-wifi-status:s'  => { name => 'warning_wifi_status', default => '%{status} =~ /bad_param/i' },
        'critical-wifi-status:s' => { name => 'critical_wifi_status', default => '%{status} =~ /failed/i' },
        'warning-disk-status:s'  => { name => 'warning_disk_status', default => '' },
        'critical-disk-status:s' => { name => 'critical_disk_status', default => '%{status} =~ /error/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(
        macros => [
            'warning_wifi_status', 'critical_wifi_status',
            'warning_disk_status', 'critical_disk_status'
        ]
    );
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get_data(path => 'system/');
    $self->{global} = { %{$result} };

    $result = $options{custom}->get_data(path => 'wifi/ap/');
    $self->{wifi} = {};

    $result = [$result] if (ref($result) ne 'ARRAY');
    foreach (@$result) {
        $self->{wifi}->{$_->{id}} = {
            display => $_->{name},
            wifi_status => $_->{status}->{state},
        };
    }
}

1;

__END__

=head1 MODE

Check system.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^temperature-cpum$'

=item B<--warning-wifi-status>

Set warning threshold for wifi status (Default: '%{status} =~ /bad_param/i').
Can used special variables like: %{status}, %{display}

=item B<--critical-wifi-status>

Set critical threshold for wifi status (Default: '%{status} =~ /failed/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-disk-status>

Set warning threshold for disk status.
Can used special variables like: %{status}

=item B<--critical-disk-status>

Set critical threshold for disk status (Default: '%{status} =~ /error/i').
Can used special variables like: %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'temperature-cpum', 'temperature-cpub', 'temperature-switch', 'fan-speed'.

=back

=cut
