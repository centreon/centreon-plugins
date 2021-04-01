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

package database::oracle::mode::librarycacheusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_pin_hitratio_calc {
    my ($self, %options) = @_;

    my $delta_total = ($options{new_datas}->{$self->{instance} . '_pins'} - $options{old_datas}->{$self->{instance} . '_pins'});
    my $delta_cache = ($options{new_datas}->{$self->{instance} . '_pin_hits'} - $options{old_datas}->{$self->{instance} . '_pin_hits'});
    $self->{result_values}->{hit_ratio} = $delta_total ? (100 * $delta_cache / $delta_total) : 0;

    return 0;
}

sub custom_get_hitratio_calc {
    my ($self, %options) = @_;

    my $delta_total = ($options{new_datas}->{$self->{instance} . '_gets'} - $options{old_datas}->{$self->{instance} . '_gets'});
    my $delta_cache = ($options{new_datas}->{$self->{instance} . '_get_hits'} - $options{old_datas}->{$self->{instance} . '_get_hits'});
    $self->{result_values}->{hit_ratio} = $delta_total ? (100 * $delta_cache / $delta_total) : 0;

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', cb_prefix_output => 'prefix_global_output', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'get-hits', nlabel => 'library.cache.get.hitratio.percentage', set => {
                key_values => [ { name => 'get_hits', diff => 1 }, { name => 'gets', diff => 1 } ],
                closure_custom_calc => $self->can('custom_get_hitratio_calc'),
                output_template => 'get hit ratio %.2f%%',
                output_use => 'hit_ratio', threshold_use => 'hit_ratio',
                perfdatas => [
                    { label => 'get_hit_ratio', value => 'hit_ratio', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'pin-hits', nlabel => 'library.cache.pin.hitratio.percentage', set => {
                key_values => [ { name => 'pin_hits', diff => 1 }, { name => 'pins', diff => 1 } ],
                closure_custom_calc => $self->can('custom_pin_hitratio_calc'),
                output_template => 'pin hit ratio %.2f%%',
                output_use => 'hit_ratio', threshold_use => 'hit_ratio',
                perfdatas => [
                    { label => 'pin_hit_ratio', value => 'hit_ratio', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'reloads', nlabel => 'library.cache.reloads.persecond', set => {
                key_values => [ { name => 'reloads', per_second => 1 }, ],
                output_template => 'reloads %.2f/s',
                perfdatas => [
                    { label => 'reloads', template => '%.2f', min => 0, unit => '/s' },
                ],
            }
        },
        { label => 'invalids', nlabel => 'library.cache.invalids.persecond', set => {
                key_values => [ { name => 'invalids', per_second => 1 }, ],
                output_template => 'invalids %.2f/s',
                perfdatas => [
                    { label => 'invalids', template => '%.2f', min => 0, unit => '/s' },
                ],
            }
        }
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'SGA library cache ';
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
        SELECT SUM(gethits), SUM(gets), SUM(pinhits), SUM(pins),
            SUM(reloads), SUM(invalidations)
        FROM v$librarycache
    };

    $options{sql}->connect();
    $options{sql}->query(query => $query);
    my @result = $options{sql}->fetchrow_array();
    $options{sql}->disconnect();
    
    $self->{global} = {
        get_hits => $result[0],
        gets => $result[1],
        pin_hits => $result[2],
        pins => $result[3],
        reloads => $result[4],
        invalids => $result[5],
    };

    $self->{cache_name} = "oracle_" . $self->{mode} . '_' . $options{sql}->get_unique_id4save() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check Oracle library cache usage.

=over 8

=item B<--warning-*> B<--critical-*> 

Thresholds.
Can be: 'get-hits', 'pin-hits', 'reloads', 'invalid'.

=back

=cut
