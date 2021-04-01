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

package database::oracle::mode::datacachehitratio;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_hitratio_calc {
    my ($self, %options) = @_;

    my $delta_phys = ($options{new_datas}->{$self->{instance} . '_physical_reads'} - $options{old_datas}->{$self->{instance} . '_physical_reads'});
    my $delta_cache = 
        ($options{new_datas}->{$self->{instance} . '_db_block_gets'} - $options{old_datas}->{$self->{instance} . '_db_block_gets'}) +
        ($options{new_datas}->{$self->{instance} . '_consistent_gets'} - $options{old_datas}->{$self->{instance} . '_consistent_gets'});
    $self->{result_values}->{hit_ratio} = ($delta_cache == 0) ? 0 : 
        ((1 - ($delta_phys / $delta_cache)) * 100);

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'usage', set => {
                key_values => [ { name => 'physical_reads', diff => 1 }, { name => 'db_block_gets', diff => 1 },
                    { name => 'consistent_gets', diff => 1 } ],
                closure_custom_calc => $self->can('custom_hitratio_calc'),
                output_template => 'Buffer cache hit ratio is %.2f%%',  output_error_template => 'Buffer cache hit ratio: %s', 
                output_use => 'hit_ratio', threshold_use => 'hit_ratio',
                perfdatas => [
                    { label => 'sga_data_buffer_hit_ratio', value => 'hit_ratio', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;    

    my $query = q{
        SELECT SUM(DECODE(name, 'physical reads', value, 0)),
            SUM(DECODE(name, 'db block gets', value, 0)),
            SUM(DECODE(name, 'consistent gets', value, 0))
        FROM sys.v_$sysstat
    };

    $options{sql}->connect();
    $options{sql}->query(query => $query);
    my @result = $options{sql}->fetchrow_array();
    $options{sql}->disconnect();
    
    $self->{global} = {
        physical_reads => $result[0], 
        db_block_gets => $result[1],
        consistent_gets => $result[2],
    };

    $self->{cache_name} = "oracle_" . $self->{mode} . '_' . $options{sql}->get_unique_id4save() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check Oracle buffer cache hit ratio.

=over 8

=item B<--warning-usage>

Threshold warning.

=item B<--critical-usage>

Threshold critical.

=back

=cut
