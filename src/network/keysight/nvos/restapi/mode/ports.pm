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
        "checking port '%s' - type '%s'",
        $options{instance_value}->{name},
        $options{instance_value}->{type}
    );
}

sub prefix_port_output {
    my ($self, %options) = @_;

    return sprintf(
        "port '%s' - type:'%s' - ",
        $options{instance_value}->{name},
        $options{instance_value}->{type}
    );
}

sub prefix_traffic_output {
    my ($self, %options) = @_;

    return 'traffic out: ';
}

sub prefix_packet_output {
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
                { name => 'traffic', type => 0, cb_prefix_output => 'prefix_traffic_output', skipped_code => { -10 => 1 } },
                { name => 'packet', type => 0, cb_prefix_output => 'prefix_packet_output', skipped_code => { -10 => 1 } }
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
                closure_custom_output => sub { return 0; },
                closure_custom_perfdata => $self->can('custom_signal_perfdata'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{traffic} = [
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

    $self->{maps_counters}->{packet} = [
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
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
        'filter-type:s' => { name => 'filter_type' }
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
        #Type may be 'Dynamic filter' but no request here by the customer.
        next if ($_->{type} ne 'Port' && $_->{type} ne 'Port Group');
        #Exclude Loopback dedup
        next if (defined($_->{tp_total_tx_count_bytes}) && defined($_->{np_total_deny_count_packets}));

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{default_name} !~ /$self->{option_results}->{filter_name}/){
            $self->{output}->output_add(long_msg => "With filter-name: $self->{option_results}->{filter_name} - Skipping object '" . $_->{default_name} . "'.", debug => 1);
            next;
        };
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $_->{type} !~ /$self->{option_results}->{filter_type}$/){
            $self->{output}->output_add(long_msg => "With filter-type: $self->{option_results}->{filter_type} - Skipping object '" . $_->{default_name} . " with type '" . $_->{type} . "'.", debug => 1);
            next;
        };

        my $info = $options{custom}->request_api(
            method => 'GET',
            endpoint => '/api/ports/' . $_->{default_name},
            get_param => ['properties=enabled,license_status,link_status']
        );

        $self->{ports}->{ $_->{default_name} } = {
            name    => $_->{default_name},
            license => {
                name   => $_->{default_name},
                status => lc($info->{license_status}),
            },
            link    => {
                name              => $_->{default_name},
                adminStatus       => $info->{enabled} =~ /true|1/i ? 'enabled' : 'disabled',
                operationalStatus => $info->{link_status}->{link_up} =~ /true|1/i ? 'up' : 'down'
            }
        };

        if (defined($_->{tp_total_tx_count_bytes})) {
            # Tool Port and Port Group
            if($_->{type} eq 'Port Group'){
                $self->{ports}->{$_->{default_name}}{type}=$_->{type};
            }else{
                $self->{ports}->{$_->{default_name}}{type}="Tool Port";
            }
            $self->{ports}->{$_->{default_name}}{traffic}{traffic_out} = $_->{tp_total_tx_count_bytes};
            $self->{ports}->{$_->{default_name}}{traffic}{traffic_out_util} = $_->{tp_current_tx_utilization};
            $self->{ports}->{$_->{default_name}}{packet}{packets_out} = $_->{tp_total_tx_count_packets};
            $self->{ports}->{$_->{default_name}}{packet}{packets_dropped} = $_->{tp_total_drop_count_packets};
            $self->{ports}->{$_->{default_name}}{packet}{packets_insp} = $_->{tp_total_insp_count_packets};
            $self->{ports}->{$_->{default_name}}{packet}{packets_pass} = $_->{tp_total_pass_count_packets};
        }else{
            #Network Port
            $self->{ports}->{$_->{default_name}}{type}="Network Port";
            $self->{ports}->{$_->{default_name}}{traffic}{traffic_out} = $_->{np_total_rx_count_bytes}; #ok
            $self->{ports}->{$_->{default_name}}{traffic}{traffic_out_util} = $_->{np_current_rx_utilization}; #ok
            $self->{ports}->{$_->{default_name}}{packet}{packets_out} = $_->{np_total_rx_count_packets}; #ok

            # Confirmation nécessaire de ces métriques
            $self->{ports}->{$_->{default_name}}{packet}{packets_dropped} = $_->{np_total_drop_count_packets}; #$_->{np_total_rx_count_invalid_packets};
            $self->{ports}->{$_->{default_name}}{packet}{packets_insp} = $_->{np_total_rx_count_crc_alignment_errors};
            $self->{ports}->{$_->{default_name}}{packet}{packets_pass} = $_->{np_total_pass_count_packets};  #$_->{np_total_deny_count_packets};
        }
    }

    $self->{cache_name} = 'keysight_nvos_' . $self->{mode} . '_' . $options{custom}->get_hostname()  . '_' . $options{custom}->get_port() . '_' .
        md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
            (defined($self->{option_results}->{filter_name}) ? $self->{option_results}->{filter_name} : '')
    );
}

1;

__END__

=head1 MODE

Check ports.

=over 8

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
Can be: 'traffic-out-prct', 'traffic-out', 'packets-out', 'packets-dropped',
'packets-pass', 'packets-insp'.

=back

=cut
