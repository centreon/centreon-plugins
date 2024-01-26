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

package apps::virtualization::hpe::simplivity::restapi::mode::omnistackclusters;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_space_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_space});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_space});
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space}
    );
}

sub prefix_ratio_output {
    my ($self, %options) = @_;

    return 'ratio ';
}

sub cluster_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking cluster '%s'",
        $options{instance},
    );
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return sprintf(
        "cluster '%s' ",
        $options{instance}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'clusters', type => 3, cb_prefix_output => 'prefix_cluster_output', cb_long_output => 'cluster_long_output', indent_long_output => '    ', message_multiple => 'All omnistack clusters are ok',
            group => [
                { name => 'ratio', type => 0, cb_prefix_output => 'prefix_ratio_output', skipped_code => { -10 => 1 } },
                { name => 'space', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{space} = [
         { label => 'space-usage', nlabel => 'omnistack_cluster.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-free', nlabel => 'omnistack_cluster.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-prct', nlabel => 'omnistack_cluster.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_space' }, { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{ratio} = [
        { label => 'ratio-deduplication', nlabel => 'omnistack_cluster.ratio.deduplication.count', set => {
                key_values => [ { name => 'deduplication' } ],
                output_template => 'deduplication: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'ratio-compression', nlabel => 'omnistack_cluster.ratio.compression.count', set => {
                key_values => [ { name => 'compression' } ],
                output_template => 'compression: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'ratio-efficiency', nlabel => 'omnistack_cluster.ratio.efficiency.count', set => {
                key_values => [ { name => 'efficiency' } ],
                output_template => 'efficiency: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $clusters = $options{custom}->get_omnistack_clusters();

    $self->{clusters} = {};
    foreach my $cluster (@{$clusters->{omnistack_clusters}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $cluster->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $cluster->{name}  . "': no matching filter.", debug => 1);
            next;
        }

        $self->{clusters}->{ $cluster->{name} } = {
            ratio => {},
            space => {
                total_space => $cluster->{allocated_capacity},
                used_space => $cluster->{used_capacity},
                free_space => $cluster->{allocated_capacity} - $cluster->{used_capacity},
                prct_used_space => $cluster->{used_capacity} * 100 / $cluster->{allocated_capacity},
                prct_free_space => 100 - ($cluster->{used_capacity} * 100 / $cluster->{allocated_capacity})
            }
        };

        $self->{clusters}->{ $cluster->{name} }->{ratio}->{efficiency} = $1
            if ($cluster->{efficiency_ratio} =~ /^\s*([0-9\.]+)\s*:/);
        $self->{clusters}->{ $cluster->{name} }->{ratio}->{deduplication} = $1
            if ($cluster->{deduplication_ratio} =~ /^\s*([0-9\.]+)\s*:/);
        $self->{clusters}->{ $cluster->{name} }->{ratio}->{compression} = $1
            if ($cluster->{compression_ratio} =~ /^\s*([0-9\.]+)\s*:/);
    }
}


1;

__END__

=head1 MODE

Check omnistack clusters.

=over 8

=item B<--filter-name>

Filter clusters by name.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage', 'space-usage-free', 'space-usage-prct',
'ratio-compression', 'ratio-deduplication', 'ratio-efficiency'.

=back

=cut
