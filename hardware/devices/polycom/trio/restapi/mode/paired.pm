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

package hardware::devices::polycom::trio::restapi::mode::paired;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'camera-count', nlabel => 'camera.src.count', set => {
                key_values => [ { name => 'cameraSrc' } ],
                output_template => 'cameraSrc: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'audio-count', nlabel => 'audio.src.count', set => {
                key_values => [ { name => 'audioSrcSink' } ],
                output_template => 'audioSrcSink: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
             }
         },
         { label => 'display-count', nlabel => 'display.count', set => {
                key_values => [ { name => 'displayUI' } ],
                output_template => 'audioSrcSink: %d',
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

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
        'filter-device:s' => {name => 'filter_device'}
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{filter_device}) && $self->{option_results}->{filter_device} ne '' && $self->{option_results}->{filter_device} !~ /^(cameraSrc|audioSrcSink|displayUI)$/) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify valid device (can be: cameraSrc, audioSrcSink or displayUI).');
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(url_path => '/api/v1/mgmt/mrpair/info');

    my $componentCount;
    foreach my $ConnectedDeviceList (@{$result->{data}->{ConnectedDeviceList}}) {
        foreach my $component (@{$ConnectedDeviceList->{ComponentList}}) {
            next if ((defined($self->{option_results}->{filter_device}) && $self->{option_results}->{filter_device} ne '' && $self->{option_results}->{filter_device} !~ /^$component->{componentType}$/) || 
                    ((!defined($self->{option_results}->{filter_device}) || $self->{option_results}->{filter_device} eq '') && $component->{componentType} !~ /^cameraSrc|audioSrcSink|displayUI$/));
            $componentCount++;
            $self->{global}->{$component->{componentType}}++;
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
    if (!defined($componentCount) || $componentCount eq '') {
        $self->{output}->add_option_msg(short_msg => 'Cannot find paired devices');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check paired devices.

=over 8

=item B<--filter-device>

Filter result by paired device.
Can be: 'cameraSrc', 'audioSrcSink', 
'displayUI'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'camera-count', 'audio-count',
'display-count'.

=back

=cut
