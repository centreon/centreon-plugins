#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package database::postgres::mode::hitratio;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc qw/is_excluded/;
use centreon::plugins::constants qw(:values);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'warning:s'           => { name => 'warning' },
        'critical:s'          => { name => 'critical' },
        'lookback'            => { name => 'lookback' },
        'include-database:s'  => { name => 'include_database', default => '' },
        'exclude-database:s'  => { name => 'exclude_database', default => '' },
        'include:s'           => { name => 'include_database' },
        'exclude:s'           => { name => 'exclude_database' }
    });

    return $self;
}

sub custom_hitratio_prefix_output {
    my ($self, %options) = @_;

    return "Database '" . $options{instance} . "' ";
}

sub custom_delta_calc {
    my ($self, %options) = @_;

    unless (defined $options{old_datas}->{$self->{instance} . '_blks_hit'}) {
        $self->{error_msg} = "Buffer creation...";
        return BUFFER_CREATION
    }

    my ($new_blks_hit, $new_blks_read) = ($options{new_datas}->{$self->{instance} . '_blks_hit'},
                                          $options{new_datas}->{$self->{instance} . '_blks_read'});

    $self->{result_values} = { hitratio => $new_blks_hit + $new_blks_read ?
                                    $new_blks_hit * 100 / ($new_blks_hit + $new_blks_read) :
                                    100,
                             };
    return 0;
}

sub custom_average_calc {
    my ($self, %options) = @_;

    unless (defined $options{old_datas}->{$self->{instance} . '_blks_hit'}) {
        $self->{error_msg} = "Buffer creation...";
        return BUFFER_CREATION
    }

    my ($old_blks_hit, $old_blks_read) = ( $options{old_datas}->{$self->{instance} . '_blks_hit'},
                                           $options{old_datas}->{$self->{instance} . '_blks_read'} );
    my ($new_blks_hit, $new_blks_read) = ( $options{new_datas}->{$self->{instance} . '_blks_hit'},
                                           $options{new_datas}->{$self->{instance} . '_blks_read'} );

    $old_blks_hit = 0 if $new_blks_hit < $old_blks_hit;
    $old_blks_read = 0 if $new_blks_read < $old_blks_read;

    my $total_read_requests = $new_blks_hit - $old_blks_hit;
    my $total_read_disk = $new_blks_read - $old_blks_read;

    $self->{result_values} = { hitratio_now => $total_read_requests + $total_read_disk ?
                                   $total_read_requests * 100 / ($total_read_requests + $total_read_disk) :
                                   100,
                             };
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'hitratio', type => 1, message_multiple => 'All databases hitratio are ok', cb_prefix_output => 'custom_hitratio_prefix_output', cb_init_count => 'init_counter' },
    ];

    $self->{maps_counters}->{hitratio} = [
        { label => 'delta', nlabel => 'database.hitratio.delta.percentage', set => {
                key_values => [ { name => 'hitratio' }, { name => 'blks_hit' }, { name => 'blks_read' } ],
                output_template =>  'hitratio at %.2f%%',
                closure_custom_calc => $self->can('custom_delta_calc'),
                perfdatas => [
                    { value => 'hitratio', template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'average', nlabel => 'database.hitratio.average.percentage', set => {
                key_values => [ { name => 'hitratio_now' }, { name => 'blks_hit' }, { name => 'blks_read' } ],
                output_template =>  'hitratio at %.2f%%',
                closure_custom_calc => $self->can('custom_average_calc'),
                perfdatas => [
                    { value => 'hitratio_now', template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 },
                ],
            }
        }
    ];
}

sub check_options {
    my ($self, %options) = @_;

    # To keep compatibility, depending on 'lookback' parameter we display either 'delta' or 'average' value and the warning/critical thresholds
    # refer to the corresponding value
    my $redirect;
    if ($options{option_results}->{lookback}) {
        $self->{maps_counters}->{hitratio}->[0]->{display_ok} = 0;
        $self->{maps_counters}->{hitratio}->[1]->{display_ok} = 1;
        $redirect = '-instance-database-hitratio-average-percentage';
    } else {
        $self->{maps_counters}->{hitratio}->[0]->{display_ok} = 1;
        $self->{maps_counters}->{hitratio}->[1]->{display_ok} = 0;
        $redirect = '-instance-database-hitratio-delta-percentage';
    }

    foreach my $label ('unknown', 'warning', 'critical') {
        $options{option_results}->{"$label$redirect"} //= '';
        $options{option_results}->{$label} //= '';
        $options{option_results}->{"$label$redirect"} =$options{option_results}->{$label}
            if $options{option_results}->{$label} ne '' && $options{option_results}->{"$label$redirect"} eq '';
    }

    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();

    $self->{cache_name} = 'postgres_' . $self->{mode} . '_' . $options{sql}->get_unique_id4save();
    $self->{hitratio} = {};

    $options{sql}->query(query => q{
        SELECT sd.blks_hit, sd.blks_read, d.datname
        FROM pg_stat_database sd, pg_database d
        WHERE d.oid=sd.datid
    });

    my $result = $options{sql}->fetchall_arrayref();

    foreach my $row (@{$result}) {
        my ($blks_hit, $blks_read, $datname) = @$row;
        $datname //= '';

        if (is_excluded($row->[2], $self->{option_results}->{include_database}, $self->{option_results}->{exclude_database})) {
            $self->{output}->output_add(long_msg => "Skipping database '" . $row->[2] . '" due to filter rules', debug => 1);
            next
        }

        $self->{hitratio}->{$datname} = { delta => 0,
                                          average => 0,
                                          blks_hit => $blks_hit,
                                          blks_read => $blks_read,
                                          hitratio => 0,
                                          hitratio_now => 0,
                                          database => $datname
                                        };
    }
}

1;

__END__

=head1 MODE

Check hit ratio (in buffer cache) for databases.

=over 8

=item B<--warning>

Warning threshold.

=item B<--critical>

Critical threshold.

=item B<--lookback>

Threshold isn't on the percent calculated from the difference ('xxx_hitratio_now').

=item B<--include-database>

Filter databases using a regular expression.

=item B<--exclude-database>

Exclude databases using a regular expression.

=back

=cut
