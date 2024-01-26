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

package apps::thales::mistral::vs9::restapi::mode::devices;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5;
use DateTime;
use POSIX;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_certificate_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'revoked: %s',
        $self->{result_values}->{revoked}
    );
}

sub custom_certificate_expires_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{time_certificate_unit} },
        unit => $self->{instance_mode}->{option_results}->{time_certificate_unit},
        instances => [
            $self->{result_values}->{sn},
            $self->{result_values}->{certSn},
            $self->{result_values}->{subjectCommonName},
            $self->{result_values}->{issuerCommonName}
        ],
        value => floor($self->{result_values}->{expires_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{time_certificate_unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_certificate_expires_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{expires_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{time_certificate_unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub custom_time_offset_output {
    my ($self, %options) = @_;

    return sprintf(
        'time offset %d second(s): %s',
        $self->{result_values}->{offset},
        $self->{result_values}->{date}
    );
}

sub custom_uptime_output {
    my ($self, %options) = @_;

    return sprintf(
        'uptime: %s',
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{uptime}, start => 'd')
    );
}

sub custom_uptime_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'system.uptime.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{time_uptime_unit} },
        unit => $self->{instance_mode}->{option_results}->{time_uptime_unit},
        instances => $self->{result_values}->{sn},
        value => floor($self->{result_values}->{uptime} / $unitdiv->{ $self->{instance_mode}->{option_results}->{time_uptime_unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_uptime_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{uptime} / $unitdiv->{ $self->{instance_mode}->{option_results}->{time_uptime_unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub custom_mistral_version_output {
    my ($self, %options) = @_;

    return sprintf(
        'firmware version: %s (current) %s (other), configurationId: %s',
        $self->{result_values}->{firmwareCurrentVersion},
        $self->{result_values}->{firmwareOtherVersion},
        $self->{result_values}->{configurationId}
    );
}

sub custom_system_version_output {
    my ($self, %options) = @_;

    return sprintf(
        'system os: %s %s',
        $self->{result_values}->{osName},
        $self->{result_values}->{osRelease}
    );
}

sub custom_traffic_perfdata {
    my ($self, %options) = @_;

    my ($warning, $critical);
    if ($self->{instance_mode}->{option_results}->{traffic_unit} eq 'percent_delta' && defined($self->{result_values}->{speed})) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
    } elsif ($self->{instance_mode}->{option_results}->{traffic_unit} =~ /bps|counter/) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});
    }

    if ($self->{instance_mode}->{option_results}->{traffic_unit} eq 'counter') {
        my $nlabel = $self->{nlabel};
        $nlabel =~ s/bitspersecond/bits/;
        $self->{output}->perfdata_add(
            nlabel => $nlabel,
            unit => 'b',
            instances => [$self->{result_values}->{sn}, $self->{result_values}->{name}],
            value => $self->{result_values}->{traffic_counter},
            warning => $warning,
            critical => $critical,
            min => 0
        );
    } else {
        $self->{output}->perfdata_add(
            nlabel => $self->{nlabel},
            instances => [$self->{result_values}->{sn}, $self->{result_values}->{name}],
            value => sprintf('%.2f', $self->{result_values}->{traffic_per_seconds}),
            warning => $warning,
            critical => $critical,
            min => 0, max => $self->{result_values}->{speed}
        );
    }
}

sub custom_traffic_threshold {
    my ($self, %options) = @_;

    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{traffic_unit} eq 'percent_delta' && defined($self->{result_values}->{speed})) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{traffic_unit} eq 'bps') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_per_seconds}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{traffic_unit} eq 'counter') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_counter}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_traffic_output {
    my ($self, %options) = @_;

    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic_per_seconds}, network => 1);
    return sprintf(
        'traffic %s: %s/s (%s)',
        $self->{result_values}->{label}, $traffic_value . $traffic_unit,
        defined($self->{result_values}->{traffic_prct}) ? sprintf('%.2f%%', $self->{result_values}->{traffic_prct}) : '-'
    );
}

sub custom_traffic_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{traffic_per_seconds} = ($options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref} } - $options{old_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref} }) / $options{delta_time};
    $self->{result_values}->{traffic_counter} = $options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref} };

    $self->{result_values}->{traffic_per_seconds} = sprintf('%d', $self->{result_values}->{traffic_per_seconds});

    if (defined($options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}}) &&
        $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}} ne '' &&
        $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}} > 0) {
        $self->{result_values}->{traffic_prct} = $self->{result_values}->{traffic_per_seconds} * 100 / $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}};
        $self->{result_values}->{speed} = $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}};
    }

    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{sn} = $options{new_datas}->{$self->{instance} . '_sn'};
    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    return 0;
}

sub custom_connection_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{time_connection_unit} },
        unit => $self->{instance_mode}->{option_results}->{time_connection_unit},
        instances => $self->{result_values}->{sn},
        value => floor($self->{result_values}->{connection_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{time_connection_unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_connection_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{connection_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{time_connection_unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub device_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking device '%s'",
        $options{instance_value}->{sn}
    );
}

sub prefix_device_output {
    my ($self, %options) = @_;

    return sprintf(
        "device '%s' ",
        $options{instance_value}->{sn}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of devices ';
}

sub prefix_interface_output {
    my ($self, %options) = @_;

    return sprintf(
        "interface '%s' ",
        $options{instance_value}->{name}
    );
}

sub prefix_autotest_output {
    my ($self, %options) = @_;

    return sprintf(
        "autotest '%s' ",
        $options{instance_value}->{name}
    );
}

sub prefix_certificate_output {
    my ($self, %options) = @_;

    return sprintf(
        "certificate '%s' [subject: %s, issuer: %s, usages: %s] ",
        $options{instance_value}->{certSn},
        $options{instance_value}->{subjectCommonName},
        $options{instance_value}->{issuerCommonName},
        $options{instance_value}->{usages}
    );
}

sub prefix_ike_sa_output {
    my ($self, %options) = @_;

    return sprintf(
        "vpn ike sa '%s' ",
        $options{instance_value}->{name}
    );
}

sub prefix_sa_output {
    my ($self, %options) = @_;

    return sprintf(
        "vpn sa '%s' ",
        $options{instance_value}->{name}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'devices', type => 3, cb_prefix_output => 'prefix_device_output', cb_long_output => 'device_long_output', indent_long_output => '    ', message_multiple => 'All devices are ok',
            group => [
                { name => 'system', type => 0, skipped_code => { -10 => 1 } },
                { name => 'connection', type => 0, skipped_code => { -10 => 1 } },
                { name => 'mistral', type => 0, skipped_code => { -10 => 1 } },
                { name => 'autotests', type => 1, cb_prefix_output => 'prefix_autotest_output', message_multiple => 'autotests are ok', display_long => 1, skipped_code => { -10 => 1 } },
                { name => 'interfaces', type => 1, cb_prefix_output => 'prefix_interface_output', message_multiple => 'interfaces are ok', display_long => 1, skipped_code => { -10 => 1 } },
                { name => 'certificates', type => 1, cb_prefix_output => 'prefix_certificate_output', message_multiple => 'certificates are ok', display_long => 1, skipped_code => { -10 => 1 } },
                { name => 'ike_service', type => 0, skipped_code => { -10 => 1 } },
                { name => 'ike_sa', type => 1, cb_prefix_output => 'prefix_ike_sa_output', message_multiple => 'ike sa are ok', display_long => 1, skipped_code => { -10 => 1 } },
                { name => 'sa', type => 1, cb_prefix_output => 'prefix_sa_output', message_multiple => 'sa are ok', display_long => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'devices-detected', display_ok => 0, nlabel => 'devices.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{connection} = [
        {
            label => 'connection-status',
            type => 2,
            unknown_default => '%{connectionStatus} =~ /unknown/i',
            warning_default => '%{connectionStatus} =~ /disconnected|unpaired/i',
            set => {
                key_values => [ { name => 'connectionStatus' }, { name => 'sn' } ],
                output_template => "connection status: %s",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'connection-last-time', nlabel => 'device.connection.last.time', set => {
                key_values      => [ { name => 'connection_seconds' }, { name => 'connection_human' }, { name => 'sn' } ],
                output_template => 'last connection: %s',
                output_use => 'connection_human',
                closure_custom_perfdata => $self->can('custom_connection_perfdata'),
                closure_custom_threshold_check => $self->can('custom_connection_threshold')
            }
        }
    ];

    $self->{maps_counters}->{mistral} = [
        {
            label => 'mistral-version',
            type => 2,
            set => {
                key_values => [ { name => 'firmwareCurrentVersion' }, { name => 'firmwareOtherVersion' }, { name => 'configurationId' } ],
                closure_custom_output => $self->can('custom_mistral_version_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'operating-state',
            type => 2,
            critical_default => '%{operatingState} !~ /operating/i',
            set => {
                key_values => [ { name => 'operatingState' }, { name => 'sn' } ],
                output_template => "operating state: %s",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'temperature', nlabel => 'device.temperature.celsius', set => {
                key_values => [ { name => 'temperature' }, { name => 'sn' } ],
                output_template => 'temperature: %.2f C',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'C',
                        instances => $self->{result_values}->{sn},
                        value => $self->{result_values}->{temperature},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
                    );
                }
            }
        }
    ];

    $self->{maps_counters}->{autotests} = [
        {
            label => 'autotest-state',
            type => 2,
            critical_default => '%{state} !~ /success/i',
            set => {
                key_values => [ { name => 'state' }, { name => 'name' }, { name => 'sn' } ],
                output_template => "state: %s",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{system} = [
        {
            label => 'system-version',
            type => 2,
            set => {
                key_values => [ { name => 'osName' }, { name => 'osRelease' } ],
                closure_custom_output => $self->can('custom_system_version_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'system-uptime', set => {
                key_values => [ { name => 'uptime' }, { name => 'sn' } ],
                closure_custom_output => $self->can('custom_uptime_output'),
                closure_custom_perfdata => $self->can('custom_uptime_perfdata'),
                closure_custom_threshold_check => $self->can('custom_uptime_threshold')
            }
        },
        { label => 'system-time-offset', nlabel => 'system.time.offset.seconds', set => {
                key_values => [ { name => 'offset' }, { name => 'date' }, { name => 'sn' } ],
                closure_custom_output => $self->can('custom_time_offset_output'),
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 's',
                        instances => $self->{result_values}->{sn},
                        value => $self->{result_values}->{offset},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
                    );
                }
            }
        }
    ];

    $self->{maps_counters}->{interfaces} = [
        {
            label => 'interface-status',
            type => 2,
            warning_default => '%{operatingStatus} !~ /up/i',
            set => {
                key_values => [ { name => 'operatingStatus' }, { name => 'name' }, { name => 'sn' } ],
                output_template => "operating status: %s",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'interface-traffic-in', nlabel => 'interface.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'in', diff => 1 }, { name => 'speed_in' }, { name => 'name' }, { name => 'sn' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_traffic_output'),
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'interface-traffic-out', nlabel => 'interface.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'out', diff => 1 }, { name => 'speed_out' }, { name => 'name' }, { name => 'sn' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_traffic_output'),
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        }
    ];

    $self->{maps_counters}->{certificates} = [
        {
            label => 'certificate-status',
            type => 2,
            set => {
                key_values => [
                    { name => 'revoked' },
                    { name => 'certSn' }, { name => 'subjectCommonName' }, { name => 'issuerCommonName' },
                    { name => 'sn' }
                ],
                closure_custom_output => $self->can('custom_certificate_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'certificate-expires', nlabel => 'certificate.expires', set => {
                key_values      => [
                    { name => 'expires_seconds' }, { name => 'expires_human' },
                    { name => 'certSn' }, { name => 'subjectCommonName' }, { name => 'issuerCommonName' },
                    { name => 'sn' }
                ],
                output_template => 'expires in %s',
                output_use => 'expires_human',
                closure_custom_perfdata => $self->can('custom_certificate_expires_perfdata'),
                closure_custom_threshold_check => $self->can('custom_certificate_expires_threshold')
            }
        }
    ];

    $self->{maps_counters}->{ike_service} = [
        {
            label => 'vpn-ike-service-state',
            type => 2,
            critical_default => '%{state} =~ /stopped/i',
            set => {
                key_values => [ { name => 'state' }, { name => 'sn' } ],
                output_template => 'vpn ike service state: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{ike_sa} = [
        {
            label => 'vpn-ike-sa-state',
            type => 2,
            critical_default => '%{state} =~ /down/i',
            set => {
                key_values => [ { name => 'state' }, { name => 'name' }, { name => 'sn' } ],
                output_template => 'vpn state: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

     $self->{maps_counters}->{sa} = [
        {
            label => 'vpn-sa-state',
            type => 2,
            critical_default => '%{state} =~ /down/i',
            set => {
                key_values => [ { name => 'state' }, { name => 'name' }, { name => 'sn' } ],
                output_template => 'state: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'vpn-sa-traffic', nlabel => 'vpn.sa.traffic.bitspersecond', set => {
                key_values => [ { name => 'traffic', per_second => 1 }, { name => 'name' }, { name => 'sn' } ],
                output_template => 'traffic: %s %s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'b/s',
                        instances => [$self->{result_values}->{sn}, $self->{result_values}->{name}],
                        value => $self->{result_values}->{traffic},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
                    );
                }
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-id:s'             => { name => 'filter_id' },
        'filter-sn:s'             => { name => 'filter_sn' },
        'filter-cert-revoked'     => { name => 'filter_cert_revoked' },
        'add-interfaces'          => { name => 'add_interfaces' },
        'add-status'              => { name => 'add_status' },
        'add-system'              => { name => 'add_system' },
        'add-mistral'             => { name => 'add_mistral' },
        'add-certificates'        => { name => 'add_certificates' },
        'add-tunnels'             => { name => 'add_tunnels' },
        'time-connection-unit:s'  => { name => 'time_connection_unit', default => 's' },
        'time-uptime-unit:s'      => { name => 'time_uptime_unit', default => 's' },
        'time-certificate-unit:s' => { name => 'time_certificate_unit', default => 's' },
        'traffic-unit:s'          => { name => 'traffic_unit', default => 'percent_delta' },
        'speed:s'                 => { name => 'speed' },
        'ntp-hostname:s'          => { name => 'ntp_hostname' },
        'ntp-port:s'              => { name => 'ntp_port', default => 123 }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{checking} = '';
    my $selected = 0;
    foreach ('status', 'interfaces', 'tunnels', 'mistral', 'system', 'certificates') {
        if (defined($self->{option_results}->{'add_' . $_})) {
            $selected = 1;
            $self->{checking} .= $_;
        }
    }
    if ($selected == 0) {
        $self->{option_results}->{add_status} = 1;
    }

    if ($self->{option_results}->{time_connection_unit} eq '' || !defined($unitdiv->{$self->{option_results}->{time_connection_unit}})) {
        $self->{option_results}->{time_connection_unit} = 's';
    }
    if ($self->{option_results}->{time_uptime_unit} eq '' || !defined($unitdiv->{$self->{option_results}->{time_uptime_unit}})) {
        $self->{option_results}->{time_uptime_unit} = 's';
    }
    if ($self->{option_results}->{time_certificate_unit} eq '' || !defined($unitdiv->{$self->{option_results}->{time_certificate_unit}})) {
        $self->{option_results}->{time_certificate_unit} = 's';
    }

    if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') {
        if ($self->{option_results}->{speed} !~ /^[0-9]+(\.[0-9]+){0,1}$/) {
            $self->{output}->add_option_msg(short_msg => "Speed must be a positive number '" . $self->{option_results}->{speed} . "' (can be a float also)");
            $self->{output}->option_exit();
        } else {
            $self->{option_results}->{speed} *= 1000000;
        }
    }

    $self->{option_results}->{traffic_unit} = 'percent_delta'
        if (!defined($self->{option_results}->{traffic_unit}) ||
            $self->{option_results}->{traffic_unit} eq '' ||
            $self->{option_results}->{traffic_unit} eq '%');
    if ($self->{option_results}->{traffic_unit} !~ /^(?:percent|percent_delta|bps|counter)$/) {
        $self->{output}->add_option_msg(short_msg => 'Wrong option --traffic-unit');
        $self->{output}->option_exit();
    }

    if (defined($self->{option_results}->{ntp_hostname}) && $self->{option_results}->{ntp_hostname} ne '') {
        centreon::plugins::misc::mymodule_load(
            output => $self->{output}, module => 'Net::NTP',
            error_msg => "Cannot load module 'Net::NTP'."
        );
    }
}

sub add_interfaces {
    my ($self, %options) = @_;

    $self->{devices}->{ $options{device}->{id} }->{interfaces} = {};

    my $interfaces = $options{custom}->request_api(endpoint => '/ssIpsecGwHws/' . $options{device}->{id} . '/interfacesStatistics');
    foreach my $interface (@{$interfaces->{listInterfaces}}) {
        $self->{devices}->{ $options{device}->{id} }->{interfaces}->{ $interface->{name} } = {
            name => $interface->{name},
            sn => $options{device}->{serialNumber},
            operatingStatus => $interface->{operatingStatus},
            in => $interface->{interfaceStats}->{inOctets} * 8,
            out => $interface->{interfaceStats}->{outOctets} * 8,
            speed_in => defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '' ? $self->{option_results}->{speed} : $interface->{speed},
            speed_out => defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '' ? $self->{option_results}->{speed} : $interface->{speed}
        };
    }
}

sub add_system {
    my ($self, %options) = @_;

    my $system = $options{custom}->request_api(endpoint => '/ssIpsecGwHws/' . $options{device}->{id} . '/systemStateStatistics');
    $self->{devices}->{ $options{device}->{id} }->{system} = {
        sn => $options{device}->{serialNumber},
        osName => $system->{platform}->{osName},
        osRelease => $system->{platform}->{osRelease}
    };

    if ($system->{clock}->{bootDatetime} =~ /^\s*(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})\.\d+([+-].*)$/) {
        my $dt = DateTime->new(
            year       => $1,
            month      => $2,
            day        => $3,
            hour       => $4,
            minute     => $5,
            second     => $6,
            time_zone  => $7
        );
        $self->{devices}->{ $options{device}->{id} }->{system}->{uptime} = time() - $dt->epoch();
    }

    if ($system->{clock}->{currentDatetime} =~ /^\s*(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})\.\d+([+-].*)$/) {
        my $ref_time;
        if (defined($self->{option_results}->{ntp_hostname}) && $self->{option_results}->{ntp_hostname} ne '') {
            my %ntp;

            eval {
                %ntp = Net::NTP::get_ntp_response($self->{option_results}->{ntp_hostname}, $self->{option_results}->{ntp_port});
            };
            if ($@) {
                $self->{output}->add_option_msg(short_msg => "Couldn't connect to ntp server: " . $@);
                $self->{output}->option_exit();
            }

            $ref_time = $ntp{'Transmit Timestamp'};
        } else {
            $ref_time = time();
        }

        my $timezone = $7;
        my $dt = DateTime->new(
            year       => $1,
            month      => $2,
            day        => $3,
            hour       => $4,
            minute     => $5,
            second     => $6,
            time_zone  => $timezone
        );
         my $remote_date_formated = sprintf(
            'local time: %02d-%02d-%02dT%02d:%02d:%02d (%s)',
            $dt->year, $dt->month, $dt->day, $dt->hour, $dt->minute, $dt->second, $timezone
        );
       
        my $offset = $dt->epoch() - $ref_time;

        $self->{devices}->{ $options{device}->{id} }->{system}->{offset} = sprintf('%d', $offset);
        $self->{devices}->{ $options{device}->{id} }->{system}->{date} = $remote_date_formated;
    }
}

sub add_mistral {
    my ($self, %options) = @_;

    my $mistral = $options{custom}->request_api(endpoint => '/ssIpsecGwHws/' . $options{device}->{id} . '/mistralStateStatistics');
    $self->{devices}->{ $options{device}->{id} }->{mistral} = {
        sn => $options{device}->{serialNumber},
        firmwareCurrentVersion => $mistral->{firmwareCurrent}->{version},
        firmwareOtherVersion => $mistral->{firmwareOther}->{version},
        configurationId => $mistral->{configurationId},
        operatingState => lc($mistral->{operatingState}),
        temperature => $mistral->{temperature}
    };

    $self->{devices}->{ $options{device}->{id} }->{autotests} = {};
    foreach (@{$mistral->{autotestStates}}) {
        $self->{devices}->{ $options{device}->{id} }->{autotests}->{ name => $_->{name} } = {
            sn => $options{device}->{serialNumber},
            name => $_->{name},
            state => lc($_->{state})
        };
    }
}

sub add_certificates {
    my ($self, %options) = @_;

    $self->{devices}->{ $options{device}->{id} }->{certificates} = {};
    foreach my $cert (@{$options{device}->{certificates}}) {
        if ($cert->{validityPeriodEnd} =~ /^\s*(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})\.\d+([+-].*)$/) {
            my $dt = DateTime->new(
                year       => $1,
                month      => $2,
                day        => $3,
                hour       => $4,
                minute     => $5,
                second     => $6,
                time_zone  => $7
            );

            my $revoked = $cert->{revoked} =~ /true|1/i ? 'yes' : 'no';
            next if (defined($self->{option_results}->{filter_cert_revoked}) && $revoked eq 'yes');

            $self->{devices}->{ $options{device}->{id} }->{certificates}->{ $cert->{gwCertificateName} } = {
                sn => $options{device}->{serialNumber},
                certSn => $cert->{serialNumber},
                subjectCommonName => $cert->{subjectCommonName},
                issuerCommonName => defined($cert->{issuerCommonName}) ? $cert->{issuerCommonName} : '',
                usages => join(' ', @{$cert->{usages}}),
                revoked => $revoked,
                expires_seconds => $dt->epoch() - time()
            };
            $self->{devices}->{ $options{device}->{id} }->{certificates}->{ $cert->{gwCertificateName} }->{expires_seconds} = 0
                if ($self->{devices}->{ $options{device}->{id} }->{certificates}->{ $cert->{gwCertificateName} }->{expires_seconds} < 0);
            $self->{devices}->{ $options{device}->{id} }->{certificates}->{ $cert->{gwCertificateName} }->{expires_human} = centreon::plugins::misc::change_seconds(
                value => $self->{devices}->{ $options{device}->{id} }->{certificates}->{ $cert->{gwCertificateName} }->{expires_seconds}
            );
        }
    }
}

sub add_tunnels {
    my ($self, %options) = @_;

    my $tunnels = $options{custom}->request_api(endpoint => '/ssIpsecGwHws/' . $options{device}->{id} . '/vpnStatistics');
    $self->{devices}->{ $options{device}->{id} }->{ike_service} = {
        sn => $options{device}->{serialNumber},
        state => lc($tunnels->{ikev2State}->{serviceState})
    };

    $self->{devices}->{ $options{device}->{id} }->{ike_sa} = {};
    foreach (@{$tunnels->{ikev2State}->{ikeSaState}}) {
        $self->{devices}->{ $options{device}->{id} }->{ike_sa}->{ $_->{name} } = {
            sn => $options{device}->{serialNumber},
            name => $_->{name},
            state => lc($_->{saState})
        };
    }

    $self->{devices}->{ $options{device}->{id} }->{sa} = {};
    foreach my $sa (@{$tunnels->{sadState}->{listSaName}}) {
        foreach my $saState (@{$sa->{listSaState}}) {
            my $name = $sa->{name};

            foreach my $spd (@{$tunnels->{spdState}->{listSpState}}) {
                if ($saState->{spi} eq $spd->{spi}) {
                    $name .= '.' . lc($spd->{direction}) . '(src:' . $spd->{sourceTs}->{ipAddress} . ',dst:' . $spd->{destinationTs}->{ipAddress} . ')';
                    last;
                }
            }

            $self->{devices}->{ $options{device}->{id} }->{sa}->{$name} = {
                sn => $options{device}->{serialNumber},
                name => $name,
                state => lc($saState->{state}),
                traffic => $saState->{lifetime}->{byteCurrent} * 1000
            };
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $inventory = $options{custom}->get_gateway_inventory();

    $self->{global} = { detected => 0 };
    $self->{devices} = {};
    foreach my $device (@$inventory) {
        next if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $device->{id} !~ /$self->{option_results}->{filter_id}/);
        next if (defined($self->{option_results}->{filter_sn}) && $self->{option_results}->{filter_sn} ne '' &&
            $device->{serialNumber} !~ /$self->{option_results}->{filter_sn}/);

        $self->{global}->{detected}++;

        $self->{devices}->{ $device->{id} } = {
            sn => $device->{serialNumber},
            name => defined($device->{name}) ? $device->{name} : ''
        };
        if (defined($self->{option_results}->{add_status})) {
            $self->{devices}->{ $device->{id} }->{connection} = {
                sn => $device->{serialNumber},
                connectionStatus => defined($device->{status}) ? lc($device->{status}->{connectedStatus}) : 'unpaired'
            };
            if (defined($device->{status})) {
                $self->{devices}->{ $device->{id} }->{connection}->{connection_seconds} = time() - ($device->{status}->{statusEpochMilli} / 1000);
                $self->{devices}->{ $device->{id} }->{connection}->{connection_human} = centreon::plugins::misc::change_seconds(
                    value => $self->{devices}->{ $device->{id} }->{connection}->{connection_seconds}
                );
            }
        }

        $self->add_interfaces(custom => $options{custom}, device => $device)
            if (defined($self->{option_results}->{add_interfaces}));

        $self->add_system(custom => $options{custom}, device => $device)
            if (defined($self->{option_results}->{add_system}));

        $self->add_mistral(custom => $options{custom}, device => $device)
            if (defined($self->{option_results}->{add_mistral}));

        $self->add_certificates(custom => $options{custom}, device => $device)
            if (defined($self->{option_results}->{add_certificates}));

        $self->add_tunnels(custom => $options{custom}, device => $device)
            if (defined($self->{option_results}->{add_tunnels}));
    }

    $self->{cache_name} = 'thales_mistral_' . $options{custom}->get_connection_info()  . '_' . $self->{mode} . '_' .
        Digest::MD5::md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
            (defined($self->{option_results}->{filter_id}) ? $self->{option_results}->{filter_id} : '') . '_' .
            (defined($self->{option_results}->{filter_sn}) ? $self->{option_results}->{filter_sn} : '') . '_' .
            $self->{checking}
        );
}

1;

__END__

=head1 MODE

Check devices.

=over 8

=item B<--filter-id>

Filter devices by id.

=item B<--filter-sn>

Filter devices by serial number.

=item B<--filter-cert-revoked>

Skip revoked certificates.

=item B<--add-status>

Check connection status.

=item B<--add-interfaces>

Check interfaces.

=item B<--add-system>

Check system.

=item B<--add-mistral>

Check mistral (operating status, temperature, autotests).

=item B<--add-certificates>

Check certificates.

=item B<--add-tunnels>

Check tunnels.

=item B<--unknown-certificate-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{revoked}, %{sn}, %{certSn}, %{subjectCommonName}, %{issuerCommonName}

=item B<--warning-certificate-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{revoked}, %{sn}, %{certSn}, %{subjectCommonName}, %{issuerCommonName}

=item B<--critical-certificate-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{revoked}, %{sn}, %{certSn}, %{subjectCommonName}, %{issuerCommonName}

=item B<--unknown-connection-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{connectionStatus} =~ /unknown/i').
You can use the following variables: %{sn}, %{connectionStatus}

=item B<--warning-connection-status>

Define the conditions to match for the status to be WARNING (default: '%{connectionStatus} =~ /disconnected|unpaired/i').
You can use the following variables: %{sn}, %{connectionStatus}

=item B<--critical-connection-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{sn}, %{connectionStatus}

=item B<--unknown-operating-state>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{sn}, %{operatingState}

=item B<--warning-operating-state>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{sn}, %{operatingState}

=item B<--critical-operating-state>

Define the conditions to match for the status to be CRITICAL  (default: '%{operatingState} !~ /operating/i').
You can use the following variables: %{sn}, %{operatingState}

=item B<--unknown-autotest-state>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{sn}, %{name}, %{state}

=item B<--warning-autotest-state>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{sn}, %{name}, %{state}

=item B<--critical-autotest-state>

Define the conditions to match for the status to be CRITICAL  (default: '%{state} !~ /success/i').
You can use the following variables: %{sn}, %{name}, %{state}

=item B<--unknown-interface-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{sn}, %{name}, %{operatingStatus}

=item B<--warning-interface-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{sn}, %{name}, %{operatingStatus}

=item B<--critical-interface-status>

Define the conditions to match for the status to be CRITICAL  (default: '%{operatingStatus} !~ /up/i').
You can use the following variables: %{sn}, %{name}, %{operatingStatus}

=item B<--unknown-vpn-ike-service-state>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{sn}, %{state}

=item B<--warning-vpn-ike-service-state>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{sn}, %{state}

=item B<--critical-vpn-ike-service-state>

Define the conditions to match for the status to be CRITICAL  (default: '%{state} =~ /stopped/i').
You can use the following variables: %{sn}, %{state}

=item B<--unknown-vpn-ike-sa-state>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{sn}, %{name}, %{state}

=item B<--warning-vpn-ike-sa-state>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{sn}, %{name}, %{state}

=item B<--critical-vpn-ike-sa-state>

Define the conditions to match for the status to be CRITICAL  (default: '%{state} =~ /down/i').
You can use the following variables: %{sn}, %{name}, %{state}

=item B<--unknown-vpn-sa-state>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{sn}, %{name}, %{state}

=item B<--warning-vpn-sa-state>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{sn}, %{name}, %{state}

=item B<--critical-vpn-sa-state>

Define the conditions to match for the status to be CRITICAL  (default: '%{state} =~ /down/i').
You can use the following variables: %{sn}, %{name}, %{state}

=item B<--ntp-hostname>

Set the ntp hostname (if not set, localtime is used).

=item B<--ntp-port>

Set the ntp port (default: 123).

=item B<--time-connection-unit>

Select the time unit for connection threshold. May be 's' for seconds, 'm' for minutes,
'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=item B<--time-uptime-unit>

Select the time unit for uptime threshold. May be 's' for seconds, 'm' for minutes,
'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=item B<--time-certificate-unit>

Select the time unit for certificate threshold. May be 's' for seconds, 'm' for minutes,
'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=item B<--traffic-unit>

Units of thresholds for the traffic (default: 'percent_delta') ('percent_delta', 'bps', 'counter').

=item B<--speed>

Set interface speed (in Mb).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'devices-detected', 'connection-last-time',
'interface-traffic-in', 'interface-traffic-out',
'system-uptime', 'system-time-offset', temperature',
'certificate-expires', 'vpn-sa-traffic'.

=back

=cut
