#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package storage::purestorage::restapi::mode::arrays;

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

sub prefix_array_output {
    my ($self, %options) = @_;
    
    return "Array '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'arrays', type => 1, cb_prefix_output => 'prefix_array_output', message_multiple => 'All arrays are ok' }
    ];
    
    $self->{maps_counters}->{arrays} = [
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
        },
        { label => 'data-reduction', nlabel => 'array.data.reduction.count', set => {
                key_values => [ { name => 'data_reduction' } ],
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
        'filter-name:s' => { name => 'filter_name' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->get_object(path => '/array?space=true');

    #[
    #    {"parity": 1.0, "capacity": 90089907364616, "provisioned": 98155035099136, "hostname": "frparadm224", "system": 0, "snapshots": 51928476177070, "volumes": 18963118791241, "data_reduction": 2.116144198166552, "total": 84076618640795, "shared_space": 13185023672484, "thin_provisioning": 0.5184735201906719, "total_reduction": 4.394658003033373}
    #    ...
    #]
    $self->{arrays} = {};
    foreach my $entry (@$results) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $entry->{hostname} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $entry->{hostname} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{arrays}->{ $entry->{hostname} } = {
            display => $entry->{hostname},
            data_reduction => $entry->{data_reduction},
            total => $entry->{capacity},
            used => $entry->{total},
            free => $entry->{capacity} - $entry->{total},
            prct_used => $entry->{total} * 100 / $entry->{capacity},
            prct_free => (100 - ($entry->{total} * 100 / $entry->{capacity}))
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

=item B<--filter-name>

Filter arrays by name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage' (B), 'space-usage-free' (B), 'space-usage-prct' (%),
'data-reduction'.

=back

=cut
