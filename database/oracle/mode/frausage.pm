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

package database::oracle::mode::frausage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'file', type => 1, cb_prefix_output => 'prefix_file_output', message_multiple => 'All recovery areas are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{file} = [
        { label => 'space-usage', nlabel => 'recoveryarea.space.usage.percentage', set => {
                key_values => [ { name => 'percent_space_usage' }, { name => 'display' } ],
                output_template => 'used : %.2f %%',
                perfdatas => [
                    { value => 'percent_space_usage', template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'space-reclaimable', nlabel => 'recoveryarea.space.reclaimable.percentage', set => {
                key_values => [ { name => 'percent_space_reclaimable' }, { name => 'display' } ],
                output_template => 'reclaimable : %.2f %%',
                perfdatas => [
                    { value => 'percent_space_reclaimable', template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-type:s' => { name => 'filter_type' },
    });
    
    return $self;
}

sub prefix_file_output {
    my ($self, %options) = @_;

    return "File type '" . $options{instance_value}->{display} . "' recovery area ";
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $options{sql}->connect();
    if ($options{sql}->is_version_minimum(version => '11')) {
        $options{sql}->query(query => q{
            SELECT file_type, percent_space_used, percent_space_reclaimable
                FROM v$recovery_area_usage
        });
    } else {
        $options{sql}->query(query => q{
            SELECT name, space_used, space_reclaimable, space_limit
                FROM v$recovery_file_dest
        });
    }
    my $result = $options{sql}->fetchall_arrayref();
    $options{sql}->disconnect();

    $self->{file} = {};
    foreach my $row (@$result) {
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $row->[0] !~ /$self->{option_results}->{filter_type}/i) {
            $self->{output}->output_add(long_msg => "skipping  '" . $row->[0] . "': no matching filter.", debug => 1);
            next;
        }

        $self->{file}->{$row->[0]} = { display => $row->[0] };
        if ($options{sql}->is_version_minimum(version => '11')) {
            $self->{file}->{$row->[0]}->{percent_space_usage} = $row->[1];
            $self->{file}->{$row->[0]}->{percent_space_reclaimable} = $row->[2];
        } else {
            $self->{file}->{$row->[0]}->{percent_space_usage} = $row->[1] * 100 / $row->[3];
            $self->{file}->{$row->[0]}->{percent_space_reclaimable} = $row->[2] * 100 / $row->[3];
        }
    }

    if (scalar(keys %{$self->{file}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No file type found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check fast recovery area space usage

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).

=item B<--filter-type>

Filter file type (can be a regexp).

=item B<--warning-*> B<--critical-*> 

Thresholds.
Can be: 'space-usage', 'space-reclaimable'.

=back

=cut
