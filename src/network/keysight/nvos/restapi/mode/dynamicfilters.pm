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

package network::keysight::nvos::restapi::mode::dynamicfilters;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub df_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking dynamic filter '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_df_output {
    my ($self, %options) = @_;

    return sprintf(
        "dynamic filter '%s' ",
        $options{instance_value}->{name}
    );
}

sub prefix_traffic_output {
    my ($self, %options) = @_;

    return 'traffic ';
}

sub prefix_packet_output {
    my ($self, %options) = @_;

    return 'packets ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'df', type => 3, cb_prefix_output => 'prefix_df_output', cb_long_output => 'df_long_output',
          indent_long_output => '    ', message_multiple => 'All dynamic filters are ok',
            group => [
                { name => 'traffic', type => 0, cb_prefix_output => 'prefix_traffic_output', skipped_code => { -10 => 1 } },
                { name => 'packet', type => 0, cb_prefix_output => 'prefix_packet_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{traffic} = [
        { label => 'traffic-pass', nlabel => 'dynamic_filter.traffic.pass.bytespersecond', set => {
                key_values => [ { name => 'traffic_pass', per_second => 1 } ],
                output_template => 'pass: %.2f %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%.2f', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'traffic-insp', nlabel => 'dynamic_filter.traffic.insp.bytespersecond', set => {
                key_values => [ { name => 'traffic_insp', per_second => 1 } ],
                output_template => 'insp: %.2f %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%.2f', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{packet} = [
        { label => 'packets-denied', nlabel => 'dynamic_filter.packets.denied.count', set => {
                key_values => [ { name => 'packets_denied', diff => 1 } ],
                output_template => 'denied: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'packets-pass', nlabel => 'dynamic_filter.packets.pass.count', set => {
                key_values => [ { name => 'packets_pass', diff => 1 } ],
                output_template => 'pass: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'packets-insp', nlabel => 'dynamic_filter.packets.insp.count', set => {
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
        'filter-name:s' => { name => 'filter_name' }
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

    $self->{df} = {};
    foreach (@{$result->{stats_snapshot}}) {
        next if ($_->{type} ne 'Dynamic Filter');

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{default_name} !~ /$self->{option_results}->{filter_name}/);

        $self->{df}->{ $_->{default_name} } = {
            name => $_->{default_name},
            traffic => {
                traffic_pass => $_->{df_total_pass_count_bytes},
                traffic_insp => $_->{df_total_insp_count_bytes}
            },
            packet => {
                packets_denied => $_->{df_total_deny_count_packets},
                packets_insp => $_->{df_total_insp_count_packets},
                packets_pass => $_->{df_total_pass_count_packets}
            }
        };
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

Check dynamic filters.

=over 8

=item B<--filter-name>

Filter dynamic filters by name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'traffic-out-prct', 'traffic-out', 'packets-out', 'packets-dropped',
'packets-pass', 'packets-insp'.

=back

=cut
