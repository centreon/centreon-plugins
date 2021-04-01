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

package hardware::devices::polycom::rprm::snmp::mode::license;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-license-usage', nlabel => 'rprm.license.total.usage.count', set => {
                key_values => [ { name => 'total_license_usage' }, { name => 'total_license_capability' }, { name => 'total_license_usage_prct' }, { name => 'license_mode' } ],
                closure_custom_output => $self->can('custom_license_output'),
                perfdatas => [ { template => '%d', max => 'total_license_capability' } ]
            }
        },
        { label => 'audio-license-usage', nlabel => 'rprm.license.audio.usage.count', set => {
                key_values => [ { name => 'audio_license_usage' }, { name => 'audio_license_capability' }, { name => 'audio_license_usage_prct' } ],
                output_template => 'Audio licenses used: %s',
                perfdatas => [ {  template => '%d', max => 'audio_license_capability' } ]
            }
        },
        { label => 'video-license-usage', nlabel => 'rprm.license.video.usage.count', set => {
                key_values => [ { name => 'video_license_usage' }, { name => 'video_license_capability' }, { name => 'video_license_usage_prct' } ],
                output_template => 'Video licenses used: %s',
                perfdatas => [ { template => '%d', max => 'video_license_capability' } ]
            }
        }
    ];
}

sub custom_license_output {
    my ($self, %options) = @_;

    return sprintf(
        'Current license usage (mode: "%s"): Total %s of %s (%.2f%%)',
        $self->{result_values}->{license_mode},
        $self->{result_values}->{total_license_usage},
        $self->{result_values}->{total_license_capability},
        $self->{result_values}->{total_license_usage_prct}
    );
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options();

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my %license_mode = (0 => 'user', 1 => 'device');

    my $oid_serviceLicenseCapability = '.1.3.6.1.4.1.13885.102.1.2.20.1.0';
    my $oid_serviceLicenseUsage = '.1.3.6.1.4.1.13885.102.1.2.20.2.0';
    my $oid_serviceLicenseMode = '.1.3.6.1.4.1.13885.102.1.2.20.3.0';
    my $oid_serviceAudioEPLicenseCapability = '.1.3.6.1.4.1.13885.102.1.2.23.1.0';
    my $oid_serviceAudioEPLicenseUsage = '.1.3.6.1.4.1.13885.102.1.2.23.2.0';
    my $oid_serviceVideoEPLicenseCapability = '.1.3.6.1.4.1.13885.102.1.2.24.1.0';
    my $oid_serviceVideoEPLicenseUsage = '.1.3.6.1.4.1.13885.102.1.2.24.2.0';

    my $result = $options{snmp}->get_leef(
        oids => [
            $oid_serviceLicenseCapability,
            $oid_serviceLicenseUsage,
            $oid_serviceLicenseMode,
            $oid_serviceAudioEPLicenseCapability,
            $oid_serviceAudioEPLicenseUsage,
            $oid_serviceVideoEPLicenseCapability,
            $oid_serviceVideoEPLicenseUsage
        ],
        nothing_quit => 1
    );

    my $total_license_usage_prct = defined($result->{$oid_serviceLicenseCapability}) && $result->{$oid_serviceLicenseCapability} != '0' ? ($result->{$oid_serviceLicenseUsage} * 100 / $result->{$oid_serviceLicenseCapability}) : 0;
    my $audio_license_usage_prct = defined($result->{$oid_serviceAudioEPLicenseCapability}) && $result->{$oid_serviceAudioEPLicenseCapability} != '0' ? ($result->{$oid_serviceAudioEPLicenseUsage} * 100 / $result->{$oid_serviceAudioEPLicenseCapability}) : 0;
    my $video_license_usage_prct = defined($result->{$oid_serviceVideoEPLicenseCapability}) && $result->{$oid_serviceVideoEPLicenseCapability} != '0' ? ($result->{$oid_serviceVideoEPLicenseUsage} * 100 / $result->{$oid_serviceVideoEPLicenseCapability}) : 0;

    $self->{global} = {
        total_license_usage => $result->{$oid_serviceLicenseUsage},
        total_license_capability => $result->{$oid_serviceLicenseCapability},
        total_license_usage_prct => $total_license_usage_prct,
        license_mode => $license_mode{$result->{$oid_serviceLicenseMode}},
        audio_license_usage => $result->{$oid_serviceAudioEPLicenseUsage},
        audio_license_capability => $result->{$oid_serviceAudioEPLicenseCapability},
        audio_license_usage_prct => $audio_license_usage_prct,
        video_license_usage => $result->{$oid_serviceVideoEPLicenseUsage},
        video_license_capability => $result->{$oid_serviceVideoEPLicenseCapability},
        video_license_usage_prct => $video_license_usage_prct
    };
}

1;

__END__

=head1 MODE

Check licenses statistics of Polycom RPRM devices.

=over 8

=item B<--warning-* --critical-*>

Warning & Critical Thresholds for the collected metrics. Possible values:
total-license-usage, audio-license-usage, video-license-usage.

=back

=cut
