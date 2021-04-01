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

package apps::backup::rubrik::restapi::mode::storage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_space});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_space});
    my $msg = sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space}
    );
    return $msg;
}

sub prefix_ss_output {
    my ($self, %options) = @_;

    return 'Storage system ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'ss', type => 0, cb_prefix_output => 'prefix_ss_output' }
    ];
    
    $self->{maps_counters}->{ss} = [
        { label => 'usage', nlabel => 'storage.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { value => 'used_space', template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'usage-free', nlabel => 'storage.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { value => 'free_space', template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'usage-prct', nlabel => 'storage.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_space' }, { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'full-remaining-days', nlabel => 'storage.full.remaining.days.count', set => {
                key_values => [ { name => 'full_remaining_days' } ],
                output_template => 'remaining days before filled: %s',
                perfdatas => [
                    { template => '%s', unit => 'd', min => 0 }
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
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $storage = $options{custom}->request_api(endpoint => '/stats/system_storage');
    my $runway = $options{custom}->request_api(endpoint => '/stats/runway_remaining');

    $self->{ss} = {
        total_space => $storage->{total},
        used_space => $storage->{total} - $storage->{available},
        free_space => $storage->{available},
        prct_used_space => 
            (($storage->{total} - $storage->{available}) * 100 / $storage->{total}),
        prct_free_space => 
            ($storage->{available} * 100 / $storage->{total}),
        full_remaining_days => $runway->{days}
    };
}

1;

__END__

=head1 MODE

Check storage system.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='remaining'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%),
'full-remaining-days'.

=back

=cut
