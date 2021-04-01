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

package hardware::devices::cisco::ces::restapi::mode::components;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(?:aiclatency|aocdelay)$';

    $self->{cb_hook2} = 'execute_custom';

    $self->{thresholds} = {
        connection_status => [
            ['NotConnected', 'OK'],
            ['Connected', 'OK'],
            ['Unknown', 'UNKNOWN']
        ],
        connected => [
            ['True', 'OK'],
            ['False', 'WARNING'],
            ['Unknown', 'UNKNOWN']
        ],
        temperature => [
            ['n/a', 'OK'],
            ['Normal', 'OK'],
            ['.*', 'CRITICAL']
        ],
        software_status => [
            ['None', 'OK'],
            ['InProgress', 'OK'],
            ['InstallationFailed', 'CRITICAL'],
            ['Failed', 'CRITICAL'],
            ['Succeeded', 'OK']
        ],
        software_urgency => [
            ['n/a', 'OK'],
            ['Low', 'OK'],
            ['Medium', 'OK'],
            ['Critical', 'CRITICAL']
        ],
        signal_state => [
            ['OK', 'OK'],
            ['Unsupported', 'WARNING'],
            ['Unknown', 'UNKNOWN']
        ],
        format_status => [
            ['Ok', 'OK'],
            ['OutOfRange', 'WARNING'],
            ['NotFound', 'OK'],
            ['Error', 'CRITICAL'],
            ['Interlaced', 'OK'],
            ['Unknown', 'UNKNOWN']
        ],
        webex => [
            ['Disabled', 'OK'],
            ['Stopped', 'OK'],
            ['Error', 'CRITICAL'],
            ['Registered', 'OK'],
            ['Registering', 'OK']
        ],
        st_status => [
            ['Inactive', 'WARNING'],
            ['Active', 'OK']
        ],
        st_availability => [
            ['Unavailable', 'WARNING'],
            ['Available', 'OK'],
            ['Off', 'OK']
        ]
    };

    $self->{components_exec_load} = 0;

    $self->{components_path} = 'hardware::devices::cisco::ces::restapi::mode::components';
    $self->{components_module} = [
        'ad', 'aic', 'aoc', 'camera', 'st', 'software', 'temperature', 'vic',
        'vis', 'voc', 'webex'
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub execute_custom {
    my ($self, %options) = @_;

    $self->{results} = $options{custom}->request_api(
        url_path => '/status.xml',
        ForceArray => ['Microphone', 'HDMI', 'Line', 'InternalSpeaker', 'Camera', 'Connector', 'Source']
    );

    my $system_version = 'unknown';
    $system_version = $self->{results}->{version} if (defined($self->{results}->{version}));

    $self->{output}->output_add(long_msg => 'firmware version: ' . $system_version);
}

1;

=head1 MODE

Check components.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'ad' (audio device), 'aic' (audio input connectors), 'aoc' (audio output connectors),
'camera', 'st' (speakerTrack), 'software', 'temperature', 'vic' (video input connectors),
'vis' (video input source), 'voc', (video output connectors), 'webex'.

=item B<--filter>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --filter='aic,Microphone.1'

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='ad.status,CRITICAL,NotConnected'

=item B<--warning>

Set warning threshold for 'temperature', 'fan', 'psu' (syntax: type,regexp,threshold)
Example: --warning='aiclatency,.*,20'

=item B<--critical>

Set critical threshold for 'temperature', 'fan', 'psu' (syntax: type,regexp,threshold)
Example: --critical='aiclatency,.*,50'

=back

=cut
