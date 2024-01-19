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

package storage::purestorage::flasharray::v2::restapi::mode::arrays;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub array_long_output {
    my ($self, %options) = @_;

    return "checking array '" . $options{instance_value}->{name} . "'";
}

sub prefix_array_output {
    my ($self, %options) = @_;

    return "Array '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'arrays', type => 3, cb_prefix_output => 'prefix_array_output', cb_long_output => 'array_long_output', indent_long_output => '    ',
            message_multiple => 'All arrays are ok',
            group => [
                { name => 'space', type => 0, skipped_code => { -10 => 1 } },
                { name => 'reduction', type => 0, skipped_code => { -10 => 1 } },
                { name => 'perf', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{space} = [
        { label => 'space-usage', nlabel => 'array.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-free', display_ok => 0, nlabel => 'array.space.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-prct', display_ok => 0, nlabel => 'array.space.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{reduction} = [
        { label => 'data-reduction', nlabel => 'array.data.reduction.count', set => {
                key_values => [ { name => 'data' } ],
                output_template => 'data reduction: %.3f',
                perfdatas => [
                    { template => '%.3f', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{perf} = [
        { label => 'read', nlabel => 'array.io.read.usage.bytespersecond', set => {
                key_values => [ { name => 'read_bytes' }, { name => 'name' }, { name => 'resolution' } ],
                output_template => 'read: %s %s/s',
                output_change_bytes => 1,
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'B/s',
                        instances => [$self->{result_values}->{name}, $self->{result_values}->{resolution}],
                        value => $self->{result_values}->{read_bytes},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
                    );
                }
            }
        },
        { label => 'write', nlabel => 'array.io.write.usage.bytespersecond', set => {
                key_values => [ { name => 'write_bytes' }, { name => 'name' }, { name => 'resolution' } ],
                output_template => 'write: %s %s/s',
                output_change_bytes => 1,
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'B/s',
                        instances => [$self->{result_values}->{name}, $self->{result_values}->{resolution}],
                        value => $self->{result_values}->{write_bytes},
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-id:s'       => { name => 'filter_id' },
        'filter-name:s'     => { name => 'filter_name' },
        'perf-resolution:s' => { name => 'perf_resolution' } 
    });
    
    return $self;
}

my $map_resolution = {
    '1s' => 1000,  '30s' => 30000, '5m' => 300000,
    '30m' => 1800000,  '2h' => 7200000, '8h' => 28800000,
    '24h' => 86400000
};

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{option_results}->{perf_resolution} = '5m'
        if (!defined($self->{option_results}->{perf_resolution}) || $self->{option_results}->{perf_resolution} eq '');

    if (!defined($map_resolution->{ $self->{option_results}->{perf_resolution} })) {
        $self->{output}->add_option_msg(short_msg => 'Unsupported --perf-resolution value. Can be: 1s, 30s, 5m, 30m, 2h, 8h, 24h');
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $items = $options{custom}->request(endpoint => '/arrays/space');
    my $perfs = $options{custom}->request(endpoint => '/arrays/performance', get_param => ['resolution=' . $map_resolution->{ $self->{option_results}->{perf_resolution} }]);

    #{
    #    "capacity": 29159353378407,
    #    "id": "1dcca71d-8bca-4951-9ba5-10ca0f5744d8",
    #    "name": "filer-c",
    #    "parity": 1.0,
    #    "space": {
    #        "data_reduction": 3.808265875566517,
    #        "replication": 0,
    #        "shared": 2182502918574,
    #        "snapshots": 0,
    #        "system": 0,
    #        "thin_provisioning": 0.3114475926111792,
    #        "total_physical": 17760870565810,
    #        "total_provisioned": 98232344510464,
    #        "total_reduction": 5.5308293670898685,
    #        "unique": 15578367647236,
    #        "virtual": 67638117296128
    #     },
    #    "time": 1670839151850
    #}
    $self->{arrays} = {};
    foreach my $item (@$items) {
        next if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $item->{id} !~ /$self->{option_results}->{filter_id}/);
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $item->{name} !~ /$self->{option_results}->{filter_name}/);

        $self->{arrays}->{ $item->{name} } = {
            name => $item->{name},
            reduction => {
                data => $item->{space}->{data_reduction}
            },
            space => {
                total => $item->{capacity},
                used => $item->{space}->{total_physical},
                free => $item->{capacity} - $item->{space}->{total_physical},
                prct_used => $item->{space}->{total_physical} * 100 / $item->{capacity},
                prct_free => (100 - ($item->{space}->{total_physical} * 100 / $item->{capacity}))
            }
        };
    }
    
    foreach my $perf (@$perfs) {
        next if (!defined($self->{arrays}->{ $perf->{name} }));

        $self->{arrays}->{ $perf->{name} }->{perf} = {
            name => $perf->{name},
            resolution => $self->{option_results}->{perf_resolution},
            read_bytes => $perf->{read_bytes_per_sec},
            write_bytes =>  $perf->{write_bytes_per_sec}
        };
    }
}

1;

__END__

=head1 MODE

Check arrays.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='data-reduction'

=item B<--filter-id>

Filter arrays by ID (can be a regexp).

=item B<--filter-name>

Filter arrays by name (can be a regexp).

=item B<--filter-resolution>

Time resolution for array performance.
Can be: 1s, 30s, 5m, 30m, 2h, 8h, 24h (default: 5m).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage' (B), 'space-usage-free' (B), 'space-usage-prct' (%),
'data-reduction', 'read', 'write'.

=back

=cut
