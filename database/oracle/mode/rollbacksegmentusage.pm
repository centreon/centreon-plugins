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

package database::oracle::mode::rollbacksegmentusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'segment', type => 0, cb_prefix_output => 'prefix_output' },
    ];

    $self->{maps_counters}->{segment} = [    
        { label => 'extends', set => {
                key_values => [ { name => 'extends', per_second => 1 } ],
                output_template => 'Extends : %.2f/s',
                perfdatas => [
                    { label => 'extends', template => '%.2f', unit => '/s', min => 0 },
                ],
            }
        },
        { label => 'wraps', set => {
                key_values => [ { name => 'wraps', per_second => 1 } ],
                output_template => 'Wraps : %.2f/s',
                perfdatas => [
                    { label => 'wraps', template => '%.2f', unit => '/s', min => 0 },
                ],
            }
        },
        { label => 'header-contention', set => {
                key_values => [ { name => 'undoheader', diff => 1 }, { name => 'complete', diff => 1 } ],
                closure_custom_calc => $self->can('custom_contention_calc'), closure_custom_calc_extra_options => { label_ref => 'header' },
                output_template => 'Header Contention :  %.2f %%', output_use => 'header_prct', threshold_use => 'header_prct',
                perfdatas => [
                    { label => 'header_contention', value => 'header_prct', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'block-contention', set => {
                key_values => [ { name => 'undoblock', diff => 1 }, { name => 'complete', diff => 1 } ],
                closure_custom_calc => $self->can('custom_contention_calc'), closure_custom_calc_extra_options => { label_ref => 'block' },
                output_template => 'Block Contention :  %.2f %%', output_use => 'block_prct', threshold_use => 'block_prct',
                perfdatas => [
                    { label => 'block_contention', value => 'block_prct', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'hit-ratio', set => {
                key_values => [ { name => 'waits', diff => 1 }, { name => 'gets', diff => 1 } ],
                closure_custom_calc => $self->can('custom_hitratio_calc'),
                output_template => 'gets/waits Ratio :  %.2f %%', output_use => 'hit_ratio', threshold_use => 'hit_ratio',
                perfdatas => [
                    { label => 'hit_ratio', value => 'hit_ratio', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
}

sub custom_hitratio_calc {
    my ($self, %options) = @_;

    my $delta_waits = $options{new_datas}->{$self->{instance} . '_waits'} - $options{old_datas}->{$self->{instance} . '_waits'};
    my $delta_gets = $options{new_datas}->{$self->{instance} . '_gets'} - $options{old_datas}->{$self->{instance} . '_gets'};
    $self->{result_values}->{hit_ratio} = $delta_gets == 0 ? 100 : (100 - 100 * $delta_waits / $delta_gets);
    
    return 0;
}

sub custom_contention_calc {
    my ($self, %options) = @_;

    my $delta_waits = $options{new_datas}->{$self->{instance} . '_complete'} - $options{old_datas}->{$self->{instance} . '_complete'};
    my $delta_undo = $options{new_datas}->{$self->{instance} . '_undo' . $options{extra_options}->{label_ref}} - $options{old_datas}->{$self->{instance} . '_undo' . $options{extra_options}->{label_ref}};
    $self->{result_values}->{$options{extra_options}->{label_ref} . '_prct'} = $delta_waits == 0 ? 0 : (100 * $delta_undo / $delta_waits);
    
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Rollback Segment ";
}

sub manage_selection {
    my ($self, %options) = @_;
    $self->{sql} = $options{sql};
    $self->{sql}->connect();

    my $query = q{
        SELECT SUM(waits), SUM(gets), SUM(extends), SUM(wraps) FROM v$rollstat
    };
    
    $self->{sql}->query(query => $query);
    my @result = $self->{sql}->fetchrow_array();
    $self->{segment} = { waits => $result[0], gets => $result[1], extends => $result[2], wraps => $result[3] };

    $query = q{
        SELECT ( 
          SELECT SUM(count)
          FROM v$waitstat
          WHERE class = 'undo header' OR class = 'system undo header'
        ) undoheader,
        ( 
          SELECT SUM(count)
          FROM v$waitstat
          WHERE class = 'undo block' OR class = 'system undo block'
        ) undoblock, 
        (
          SELECT SUM(count)
          FROM v$waitstat
        ) complete
        FROM DUAL
    };
    $self->{sql}->query(query => $query);
    @result = $self->{sql}->fetchrow_array();
    $self->{segment}->{undoheader} = $result[0];
    $self->{segment}->{undoblock} = $result[1];
    $self->{segment}->{complete} = $result[2];
    
    $self->{cache_name} = "oracle_" . $self->{mode} . '_' . $self->{sql}->get_unique_id4save() . '_' . 
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    $self->{sql}->disconnect();
}

1;

__END__

=head1 MODE

Check Oracle rollback segment usage.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'header-contention', 'block-contention', 'hit-ratio',
'extends', 'wraps'.

=item B<--critical-*>

Threshold critical.
Can be: 'header-contention', 'block-contention', 'hit-ratio',
'extends', 'wraps'.

=back

=cut
