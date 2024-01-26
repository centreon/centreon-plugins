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

package storage::purestorage::flashblade::v2::restapi::mode::filesystems;

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

sub filesystem_long_output {
    my ($self, %options) = @_;

    return "checking filesystem '" . $options{instance_value}->{name} . "'";
}

sub prefix_filesystem_output {
    my ($self, %options) = @_;

    return "Filesystem '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'filesystems', type => 3, cb_prefix_output => 'prefix_filesystem_output', cb_long_output => 'filesystem_long_output', indent_long_output => '    ',
            message_multiple => 'All filesystems are ok',
            group => [
                { name => 'space', type => 0, skipped_code => { -10 => 1 } },
                { name => 'reduction', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{space} = [
        { label => 'space-usage', nlabel => 'filesystem.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-free', display_ok => 0, nlabel => 'filesystem.space.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-prct', display_ok => 0, nlabel => 'filesystem.space.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{reduction} = [
        { label => 'data-reduction', nlabel => 'filesystem.data.reduction.count', set => {
                key_values => [ { name => 'data' } ],
                output_template => 'data reduction: %.3f',
                perfdatas => [
                    { template => '%.3f', min => 0, label_extra_instance => 1 }
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
        'filter-id:s'       => { name => 'filter_id' },
        'filter-name:s'     => { name => 'filter_name' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $items = $options{custom}->request(endpoint => '/file-systems');

    $self->{filesystems} = {};
    foreach my $item (@$items) {
        next if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $item->{id} !~ /$self->{option_results}->{filter_id}/);
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $item->{name} !~ /$self->{option_results}->{filter_name}/);

        $self->{filesystems}->{ $item->{name} } = {
            name => $item->{name},
            reduction => {
                data => $item->{space}->{data_reduction}
            },
            space => {
                total => $item->{provisioned},
                used => $item->{space}->{virtual},
                free => $item->{provisioned} - $item->{space}->{virtual},
                prct_used => $item->{space}->{virtual} * 100 / $item->{provisioned},
                prct_free => (100 - ($item->{space}->{virtual} * 100 / $item->{provisioned}))
            }
        };
    }
}

1;

__END__

=head1 MODE

Check filesystems.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='data-reduction'

=item B<--filter-id>

Filter filesystems by ID (can be a regexp).

=item B<--filter-name>

Filter filesystems by name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage' (B), 'space-usage-free' (B), 'space-usage-prct' (%),
'data-reduction'.

=back

=cut
