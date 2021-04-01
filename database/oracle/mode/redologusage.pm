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

package database::oracle::mode::redologusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_get_hitratio_calc {
    my ($self, %options) = @_;

    my $delta_total = ($options{new_datas}->{$self->{instance} . '_redo_entries'} - $options{old_datas}->{$self->{instance} . '_redo_entries'});
    my $delta_retry = ($options{new_datas}->{$self->{instance} . '_redo_buffer_alloc_retries'} - $options{old_datas}->{$self->{instance} . '_redo_buffer_alloc_retries'});
    $self->{result_values}->{retry_ratio} = $delta_total ? (100 * $delta_retry / $delta_total) : 0;

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', cb_prefix_output => 'prefix_global_output', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'retry-ratio', nlabel => 'redolog.retry.ratio.percentage', set => {
                key_values => [ { name => 'redo_buffer_alloc_retries', diff => 1 }, { name => 'redo_entries', diff => 1 } ],
                closure_custom_calc => $self->can('custom_get_hitratio_calc'),
                output_template => 'retry ratio %.2f%%',
                output_use => 'retry_ratio', threshold_use => 'retry_ratio',
                perfdatas => [
                    { label => 'retry_ratio', value => 'retry_ratio', template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'traffic-io', nlabel => 'redolog.traffic.io.bytespersecond', set => {
                key_values => [ { name => 'redo_size', per_second => 1 } ],
                output_change_bytes => 1,
                output_template => 'traffic io %s %s/s',
                perfdatas => [
                    { label => 'traffic_io', template => '%s', min => 0, unit => 'B/s' }
                ]
            }
        }
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Redo log ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;    

    my $query = q{
        SELECT a.value, b.value, c.value
            FROM v$sysstat a, v$sysstat b, v$sysstat c
            WHERE a.name = 'redo buffer allocation retries'  
            AND b.name = 'redo entries'
            AND c.name = 'redo size'
    };

    $options{sql}->connect();
    $options{sql}->query(query => $query);
    my @result = $options{sql}->fetchrow_array();
    $options{sql}->disconnect();
    
    $self->{global} = {
        redo_buffer_alloc_retries => $result[0],
        redo_entries => $result[1],
        redo_size => $result[2],
    };

    $self->{cache_name} = "oracle_" . $self->{mode} . '_' . $options{sql}->get_unique_id4save() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check Oracle redo log usage.

=over 8

=item B<--warning-*> B<--critical-*> 

Thresholds.
Can be: 'retry-ratio', 'traffic-io'.

=back

=cut
