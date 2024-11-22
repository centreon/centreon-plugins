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

package network::keysight::nvos::restapi::mode::ports;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_link_output {
    my ($self, %options) = @_;

    return sprintf(
        "link operational status: %s [admin: %s]",
        $self->{result_values}->{operationalStatus},
        $self->{result_values}->{adminStatus}
    );
}

sub port_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking port '%s' [type: %s]",
        $options{instance_value}->{name},
        $options{instance_value}->{type}
    );
}

sub prefix_port_output {
    my ($self, %options) = @_;

    return sprintf(
        "port '%s' [type: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{type}
    );
}

sub prefix_traffic_in_output {
    my ($self, %options) = @_;

    return 'traffic in: ';
}

sub prefix_traffic_out_output {
    my ($self, %options) = @_;

    return 'traffic out: ';
}

sub prefix_packet_other_port_output {
    my ($self, %options) = @_;

    return 'packets ';
}

sub prefix_packet_network_port_output {
    my ($self, %options) = @_;

    return 'packets ';
}

sub custom_signal_perfdata {
    my ($self) = @_;

    my $instances = [];
    foreach (@{$self->{instance_mode}->{custom_perfdata_instances}}) {
        push @$instances, $self->{result_values}->{$_};
    }

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => $instances,
        value => $self->{result_values}->{ $self->{key_values}->[0]->{name} },
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'ports', type => 3, cb_prefix_output => 'prefix_port_output', cb_long_output => 'port_long_output',
          indent_long_output => '    ', message_multiple => 'All ports are ok',
            group => [
                { name => 'license', type => 0, skipped_code => { -10 => 1 } },
                { name => 'link', type => 0, skipped_code => { -10 => 1 } },
                { name => 'traffic_in', type => 0, cb_prefix_output => 'prefix_traffic_in_output', skipped_code => { -10 => 1 } },
                { name => 'traffic_out', type => 0, cb_prefix_output => 'prefix_traffic_out_output', skipped_code => { -10 => 1 } },
                { name => 'packet_network_port', type => 0, cb_prefix_output => 'prefix_packet_network_port_output', skipped_code => { -10 => 1 } },
                { name => 'packet_other_port', type => 0, cb_prefix_output => 'prefix_packet_other_port_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{license} = [
        {
            label => 'license-status',
            type => 2,
            warning_default => '%{status} =~ /invalid_software_version/',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'name' }
                ],
                output_template => 'license status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{link} = [
        {
            label => 'link-status',
            type => 2,
            critical_default => '%{adminStatus} eq "enabled" and %{operationalStatus} ne "up"',
            set => {
                key_values => [
                    { name => 'adminStatus' }, { name => 'operationalStatus' } , { name => 'name' }, { name => 'type' }
                ],
                closure_custom_output => $self->can('custom_link_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{traffic_in} = [
        { label => 'traffic-in-prct', nlabel => 'port.traffic.in.percentage', set => {
                key_values => [ { name => 'traffic_in_util' } ],
                output_template => '%.2f%%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'traffic-in', nlabel => 'port.traffic.in.bytespersecond', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 } ],
                output_template => '%.2f %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%.2f', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{traffic_out} = [
        { label => 'traffic-out-prct', nlabel => 'port.traffic.out.percentage', set => {
                key_values => [ { name => 'traffic_out_util' } ],
                output_template => '%.2f%%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'port.traffic.out.bytespersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 } ],
                output_template => '%.2f %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%.2f', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{packet_other_port} = [
        { label => 'packets-out', nlabel => 'port.packets.out.count', set => {
                key_values => [ { name => 'packets_out', diff => 1 } ],
                output_template => 'out: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'packets-dropped', nlabel => 'port.packets.dropped.count', set => {
                key_values => [ { name => 'packets_dropped', diff => 1 } ],
                output_template => 'dropped: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'packets-pass', nlabel => 'port.packets.pass.count', set => {
                key_values => [ { name => 'packets_pass', diff => 1 } ],
                output_template => 'pass: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'packets-insp', nlabel => 'port.packets.insp.count', set => {
                key_values => [ { name => 'packets_insp', diff => 1 } ],
                output_template => 'insp: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{packet_network_port} = [
        { label => 'packets-in', nlabel => 'port.packets.in.count', set => {
                key_values => [ { name => 'packets_in', diff => 1 } ],
                output_template => 'in: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'packets-pass', nlabel => 'port.packets.pass.count', set => {
                key_values => [ { name => 'packets_pass', diff => 1 } ],
                output_template => 'pass: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'packets-invalid', nlabel => 'port.packets.invalid.count', set => {
                key_values => [ { name => 'packets_invalid', diff => 1 } ],
                output_template => 'invalid: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'packets-deny', nlabel => 'port.packets.deny.count', set => {
                key_values => [ { name => 'packets_deny', diff => 1 } ],
                output_template => 'deny: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'packets-crc-alignment-errors', nlabel => 'port.crc.alignment.errors.count', set => {
                key_values => [ { name => 'packets_crc_alignment_errors', diff => 1 } ],
                output_template => 'crc alignment errors: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-default-name:s' => { name => 'filter_default_name' },
        'filter-name:s'         => { name => 'filter_name' },
        'filter-type:s'         => { name => 'filter_type' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        method => 'POST',
        endpoint => '/api/stats/',
        query_form_post => '',
        header => ['Content-Type: application/json'],
    );

    $self->{ports} = {};
    foreach (@{$result->{stats_snapshot}}) {
        # Only need 'Port Group' and 'Port'
        next if ($_->{type} !~ /Port/i);

        my $type;
        if ($_->{type} eq 'Port Group') {
            $type = $_->{type};
        } elsif (defined($_->{tp_total_tx_count_bytes})) {
            $type = "Tool Port";
        } else {
            $type = "Network Port";
        }

        next if (defined($self->{option_results}->{filter_default_name}) && $self->{option_results}->{filter_default_name} ne '' &&
            $_->{default_name} !~ /$self->{option_results}->{filter_default_name}/);
        next if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $type !~ /$self->{option_results}->{filter_type}/);

        my $info;
        if ($_->{type} eq 'Port Group') {
            $info = $options{custom}->request_api(
                method => 'GET',
                endpoint => '/internal/port_groups/' . $_->{id},
                get_param => ['properties=name,link_status']
            );
        } else {
            $info = $options{custom}->request_api(
                method => 'GET',
                endpoint => '/api/ports/' . $_->{id},
                get_param => ['properties=name,enabled,license_status,link_status']
            );
        }

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $info->{name} !~ /$self->{option_results}->{filter_name}/);

        my $name = $_->{default_name};
        if (defined($info->{name}) && $info->{name} ne '') {
            $name = $info->{name};
        }

        my $adminStatus = 'none';
        if (defined($info->{enabled})) {
            $adminStatus = $info->{enabled} =~ /true|1/i ? 'enabled' : 'disabled';
        }
    
        $self->{ports}->{$name} = {
            name    => $name,
            type    => $type,
            link    => {
                name              => $name,
                type              => $type,
                adminStatus       => $adminStatus,
                operationalStatus => $info->{link_status}->{link_up} =~ /true|1/i ? 'up' : 'down'
            }
        };
        
        if (defined($info->{license_status})) {
            $self->{ports}->{$name}->{license} = {
                name   => $name,
                status => lc($info->{license_status})
            };
        }

        if ($type eq 'Port Group' || $type eq 'Tool Port') {
            $self->{ports}->{$name}->{traffic_out} = {
                traffic_out => $_->{tp_total_tx_count_bytes},
                traffic_out_util => $_->{tp_current_tx_utilization}
            };
            $self->{ports}->{$name}->{packet_other_port} = {
                packets_out => $_->{tp_total_tx_count_packets},
                packets_dropped => $_->{tp_total_drop_count_packets},
                packets_insp => $_->{tp_total_insp_count_packets},
                packets_pass => $_->{tp_total_pass_count_packets}
            };
        } else {
            $self->{ports}->{$name}->{traffic_in} = {
                traffic_in => $_->{np_total_rx_count_bytes},
                traffic_in_util => $_->{np_current_rx_utilization}
            };
            $self->{ports}->{$name}->{packet_network_port} = {
                packets_in => $_->{np_total_rx_count_packets},
                packets_pass => $_->{np_total_pass_count_packets},
                packets_invalid => $_->{np_total_rx_count_invalid_packets},
                packets_deny => $_->{np_total_deny_count_packets},
                packets_crc_alignment_errors => $_->{np_total_rx_count_crc_alignment_errors}
            };
        }
    }

    $self->{cache_name} = 'keysight_nvos_' . $self->{mode} . '_' . $options{custom}->get_hostname()  . '_' . $options{custom}->get_port() . '_' .
        md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
            (defined($self->{option_results}->{filter_default_name}) ? $self->{option_results}->{filter_default_name} : '') . '_' .
            (defined($self->{option_results}->{filter_name}) ? $self->{option_results}->{filter_name} : '') . '_' .
            (defined($self->{option_results}->{filter_type}) ? $self->{option_results}->{filter_type} : '')
    );
}

1;

__END__

=head1 MODE

Check ports.

=over 8

=item B<--filter-default-name>

Filter ports by default name (can be a regexp).

=item B<--filter-name>

Filter ports by name (can be a regexp).

=item B<--filter-type>

Filter ports by type (can be a regexp).
You can use the following types: 'Network Port', 'Port Group' and 'Tool Port'

=item B<--unknown-license-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{name}

=item B<--warning-license-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /invalid_software_version/').
You can use the following variables: %{status}, %{name}

=item B<--critical-license-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{status}, %{name}

=item B<--unknown-link-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{adminStatus}, %{operationalStatus}, %{name}

=item B<--warning-link-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{adminStatus}, %{operationalStatus}, %{name}

=item B<--critical-link-status>

Define the conditions to match for the status to be CRITICAL (default: '%{adminStatus} eq "enabled" and %{operationalStatus} ne "up"').
You can use the following variables: %{adminStatus}, %{operationalStatus}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'traffic-in-prct', 'traffic-in', 'traffic-out-prct', 'traffic-out', 'packets-out', 'packets-in', 'packets-dropped',
'packets-pass', 'packets-insp'.

=back

=cut
