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

package network::cisco::firepower::fmc::restapi::mode::devices;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_device_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status};
}

sub domain_long_output {
    my ($self, %options) = @_;

    return "checking domain '" . $options{instance_value}->{name} . "'";
}

sub prefix_domain_output {
    my ($self, %options) = @_;

    return "Domain '" . $options{instance_value}->{name} . "' ";
}

sub prefix_device_output {
    my ($self, %options) = @_;

    return "device '" . $options{instance_value}->{name} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Devices ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'domains', type => 3, cb_prefix_output => 'prefix_domain_output', cb_long_output => 'domain_long_output', indent_long_output => '    ', message_multiple => 'All domains are ok',
            group => [
                { name => 'devices', display_long => 1, cb_prefix_output => 'prefix_device_output', message_multiple => 'devices are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'devices-total', nlabel => 'devices.total.count', display_ok => 0, set => {
                key_values => [ { name => 'devices_total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
    foreach (('green', 'black', 'blue', 'red', 'yellow')) {
        push @{$self->{maps_counters}->{global}},
            { label => 'devices-status-' . $_, nlabel => 'devices.status.' . $_ .  '.count', display_ok => 0, set => {
                    key_values => [ { name => 'devices_' . $_ }, { name => 'devices_total' } ],
                    output_template => $_ . ': %s',
                    perfdatas => [
                        { template => '%s', min => 0, max => 'devices_total' }
                    ]
                }
            };
    }

    $self->{maps_counters}->{devices} = [
        {
            label => 'device-status',
            type => 2,
            warning_default => '%{status} =~ /yellow/i',
            critical_default => '%{status} =~ /red|black/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_device_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-domain-name:s' => { name => 'filter_domain_name' },
        'filter-device-name:s' => { name => 'filter_device_name' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $domains = $options{custom}->request_api(
        endpoint_domain => 'fmc_platform',
        endpoint => '/info/domain'
    );

    $self->{global} = {
        devices_total => 0, devices_black => 0,
        devices_red => 0, devices_yellow => 0,
        devices_green => 0, devices_blue => 0
    };
    $self->{domains} = {};

    foreach my $domain (@{$domains->{items}}) {
        if (defined($self->{option_results}->{filter_domain_name}) && $self->{option_results}->{filter_domain_name} ne '' &&
            $domain->{name} !~ /$self->{option_results}->{filter_domain_name}/) {
            $self->{output}->output_add(long_msg => "skipping domain '" . $domain->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{domains}->{ $domain->{name} } = {
            name => $domain->{name},
            devices => {}
        };

        my $devices = $options{custom}->request_api(
            endpoint_domain => 'fmc_config',
            endpoint => '/domain/' . $domain->{uuid} . '/devices/devicerecords',
            get_param => ['expanded=true']
        );

        foreach my $device (@{$devices->{items}}) {
            if (defined($self->{option_results}->{filter_device_name}) && $self->{option_results}->{filter_device_name} ne '' &&
                $device->{name} !~ /$self->{option_results}->{filter_device_name}/) {
                $self->{output}->output_add(long_msg => "skipping device '" . $device->{name} . "': no matching filter.", debug => 1);
                next;
            }

            $self->{domains}->{ $domain->{name} }->{devices}->{ $device->{name} } = {
                name => $device->{name},
                status => $device->{healthStatus}
            };
            $self->{global}->{'devices_' . lc($device->{name})}++
                if (defined($self->{global}->{'devices_' . lc($device->{name})}));
            $self->{global}->{devices_total}++;
        }
    }
}

1;

__END__

=head1 MODE

Check devices.

=over 8

=item B<--filter-domain-name>

Filter devices by domain name (Can be a regexp).

=item B<--filter-device-name>

Filter devices by name (Can be a regexp).

=item B<--unknown-device-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{name}

=item B<--warning-device-status>

Set warning threshold for status (Default: '%{status} =~ /yellow/i').
Can used special variables like: %{status}, %{name}

=item B<--critical-device-status>

Set critical threshold for status (Default: '%{status} =~ /red|black/i').
Can used special variables like: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'devices-total', 'devices-status-green', 'devices-status-black', 'devices-status-blue', 
'devices-status-red', 'devices-status-yellow'.

=back

=cut
