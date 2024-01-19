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

package hardware::devices::polycom::trio::restapi::mode::paired;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Devices paired ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'camera-paired', nlabel => 'devices.camera.paired.count', set => {
                key_values => [ { name => 'cameraSrc' } ],
                output_template => 'camera: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'audio-paired', nlabel => 'devices.audio.paired.count', set => {
                key_values => [ { name => 'audioSrcSink' } ],
                output_template => 'audio: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
             }
         },
         { label => 'displayui-paired', nlabel => 'devices.display_ui.paired.count', set => {
                key_values => [ { name => 'displayUI' } ],
                output_template => 'display ui: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
             }
         }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);

    $options{options}->add_options(arguments => {
        'filter-device-name:s' => { name => 'filter_device_name' },
        'filter-device-type:s' => { name => 'filter_device_type' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(url_path => '/api/v1/mgmt/mrpair/info');

    $self->{global} = { cameraSrc => 0, displayUI => 0, audioSrcSink => 0 };
    foreach my $ConnectedDeviceList (@{$result->{data}->{ConnectedDeviceList}}) {
        foreach my $component (@{$ConnectedDeviceList->{ComponentList}}) {
            next if ($component->{componentType} !~ /^(?:cameraSrc|audioSrcSink|displayUI)$/);

            if (defined($self->{option_results}->{filter_device_name}) && $self->{option_results}->{filter_device_name} ne '' &&
                $component->{componentName} !~ /$self->{option_results}->{filter_device_name}/) {
                $self->{output}->output_add(long_msg => "skipping device '" . $component->{componentName} . "': no matching filter.", debug => 1);
                next;
            }
            if (defined($self->{option_results}->{filter_device_type}) && $self->{option_results}->{filter_device_type} ne '' &&
                $component->{componentType} !~ /$self->{option_results}->{filter_device_type}/) {
                $self->{output}->output_add(long_msg => "skipping device '" . $component->{componentName} . "': no matching filter.", debug => 1);
                next;
            }

            $self->{global}->{ $component->{componentType} }++;
            $self->{output}->output_add(
                long_msg => sprintf(
                    'componentType: %s [name: %s] [details: %s] [SerialNumer: %s] [componentUri: %s]',
                    $component->{componentType},
                    $component->{componentName},
                    $component->{componentDetail},
                    $component->{componentSerialNumber},
                    $component->{componentUri}
                )
            );
        }
    }
}

1;

__END__

=head1 MODE

Check paired devices.

=over 8

=item B<--filter-device-name>

Filter devices by name.

=item B<--filter-device-type>

Filter devices by type.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'camera-paired', 'audio-paired', 'displayui-paired'.

=back

=cut

