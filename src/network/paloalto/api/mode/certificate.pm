#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::paloalto::api::mode::certificate;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters);
use DateTime::Format::Strptime;
use centreon::plugins::misc qw(is_excluded is_empty);

sub prefix_device_output {
    my ($self, %options) = @_;
    return "Device '" . $options{instance_value}->{hostname} . "' (" . $options{instance_value}->{serial} . ") ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'devices', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_device_output',
          message_multiple => 'All device certificates are OK' }
    ];

    $self->{maps_counters}->{devices} = [
        {
            label => 'certificate-status',
            type  => COUNTER_KIND_TEXT,
            critical_default => '%{cert_status} !~ /valid/i',
            set => {
                key_values => [ { name => 'cert_status' }, { name => 'serial' }, { name => 'hostname' }, { name => 'connected' } ],
                output_template => 'certificate status: %{cert_status}',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'certificate-subject',
            type  => COUNTER_KIND_TEXT,
            display_ok => 0,
            set => {
                key_values => [ { name => 'cert_subject' }, { name => 'serial' }, { name => 'hostname' }, { name => 'connected' } ],
                output_template => 'subject: %{cert_subject}',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'certificate-expiry',
            nlabel => 'device.certificate.expiry.days',
            set => {
                key_values => [ { name => 'cert_expiry_days' }, { name => 'serial' }, { name => 'hostname' }, { name => 'connected' } ],
                output_template => 'expires in: %{cert_expiry_days} days',
                perfdatas => [
                    { template => '%s', unit => 'd', min => 0, instance_use => 'hostname', label_extra_instance => 1 }
                ]
            }
        },
        {
            label => 'certificate-custom-usage',
            type  => COUNTER_KIND_TEXT,
            display_ok => 0,
            set => {
                key_values => [ { name => 'custom_cert_usage' }, { name => 'serial' }, { name => 'hostname' }, { name => 'connected' } ],
                output_template => 'custom certificate usage: %{custom_cert_usage}',
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
        'include-device-serial:s'     => { name => 'include_device_serial',   default => '' },
        'exclude-device-serial:s'     => { name => 'exclude_device_serial',   default => '' },
        'include-device-hostname:s'   => { name => 'include_device_hostname', default => '' },
        'exclude-device-hostname:s'   => { name => 'exclude_device_hostname', default => '' },
        'connected-only'              => { name => 'connected_only' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $filter = $self->{option_results}->{connected_only} ? 'connected' : 'all';
    my $result = $options{custom}->request_api(
        type => 'op',
        cmd  => "<show><devices><$filter></$filter></devices></show>",
        ForceArray => [ 'entry' ]
    );

    $self->{devices} = {};

    $self->{output}->option_exit(short_msg => "No certificates found !")
        unless $result && ref $result->{devices} eq 'HASH';

    foreach my $device (@{$result->{devices}->{entry}}) {
        my $serial = $device->{name};
        my $hostname = $device->{hostname} // '';

        next if is_excluded($serial, $self->{option_results}->{include_device_serial}, $self->{option_results}->{exclude_device_serial}, output => $self->{output}) ||
                is_excluded($hostname, $self->{option_results}->{include_device_hostname}, $self->{option_results}->{exclude_device_hostname}, output => $self->{output});

        my $connected = lc($device->{connected} // 'no');
        my $cert_expiry_days = -1;
        $cert_expiry_days = $self->_calculate_days_until_expiry($device->{'certificate-expiry'})
            if exists $device->{'certificate-expiry'};

        $self->{devices}->{$serial} = {
            serial              => $serial,
            hostname            => $hostname,
            connected           => $connected,
            cert_status         => $device->{'device-cert-present'} // '',
            cert_subject        => $device->{'certificate-subject-name'} // '',
            cert_expiry_days    => $cert_expiry_days,
            custom_cert_usage   => $device->{'custom-certificate-usage'} // '',
        };
    }
}

sub _calculate_days_until_expiry {
    my ($self, $expiry_str) = @_;

    return -1 if is_empty($expiry_str);

    my $parser = DateTime::Format::Strptime->new(
        pattern => '%Y/%m/%d %H:%M:%S',
        on_error => 'undef',
        time_zone => 'UTC'
    );

    my $expiry_dt = $parser->parse_datetime($expiry_str);
    return -1 unless $expiry_dt;

    return int(($expiry_dt->epoch() - time()) / 86400);
}

1;

__END__

=head1 MODE

Check Palo Alto Panorama managed devices certificate information.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^certificate-status$'

=item B<--include-device-serial>

Include only specific device by serial number (regexp can be used).

=item B<--exclude-device-serial>

Exclude specific device by serial number (regexp can be used).

=item B<--include-device-hostname>

Include only specific device by hostname (regexp can be used).

=item B<--exclude-device-hostname>

Exclude specific device by hostname (regexp can be used).

=item B<--connected-only>

Only check connected devices.

=item B<--unknown-certificate-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{cert_status}, %{serial}, %{hostname}, %{connected}

=item B<--warning-certificate-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{cert_status}, %{serial}, %{hostname}, %{connected}

=item B<--critical-certificate-status>

Define the conditions to match for the status to be CRITICAL (default: '%{cert_status} !~ /valid/i').
You can use the following variables: %{cert_status}, %{serial}, %{hostname}, %{connected}

=item B<--unknown-certificate-subject>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{cert_subject}, %{serial}, %{hostname}, %{connected}

=item B<--warning-certificate-subject>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{cert_subject}, %{serial}, %{hostname}, %{connected}

=item B<--critical-certificate-subject>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{cert_subject}, %{serial}, %{hostname}, %{connected}

=item B<--warning-certificate-expiry>

Warning threshold for certificate expiry in days.

=item B<--critical-certificate-expiry>

Critical threshold for certificate expiry in days.

=item B<--unknown-certificate-custom-usage>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{custom_cert_usage}, %{serial}, %{hostname}, %{connected}

=item B<--warning-certificate-custom-usage>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{custom_cert_usage}, %{serial}, %{hostname}, %{connected}

=item B<--critical-certificate-custom-usage>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{custom_cert_usage}, %{serial}, %{hostname}, %{connected}

=back

=cut
