#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package database::mssql::mode::pagelifeexpectancy;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 1, cb_prefix_output => 'prefix_instance_output',
            message_multiple => 'All page life expectancy are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'page-life-expectancy', nlabel => 'page.life.expectancy.seconds', set => {
            key_values => [ { name => 'page_life_expectancy' },  { name => 'display' },],
            output_template => 'Page life expectancy : %d second(s)',
            perfdatas => [
                { value => 'page_life_expectancy_absolute', template => '%d', unit => 's', min => 0,
                    label_extra_instance => 1, instance_use => 'display_absolute' },
            ]
        }}
    ];
}

sub prefix_instance_output {
    my ($self, %options) = @_;

    return "Instance '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "filter-instance:s"     => {name => 'filter_instance'},
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
    $self->{sql}->query(query => q{
        SELECT object_name,cntr_value
        FROM sys.dm_os_performance_counters
        WHERE counter_name = 'Page life expectancy'
        AND object_name LIKE '%Manager%'
    });
    my $result =  $self->{sql}->fetchall_arrayref();

    foreach my $row (@$result) {
        if (defined($self->{option_results}->{filter_instance}) && $self->{option_results}->{filter_instance} ne '' &&
            $$row[0] !~ /$self->{option_results}->{filter_instance}/i) {
            $self->{output}->output_add(debug => 1, long_msg => "Skipping instance " . $$row[0] . ": no matching filter.");
            next;
        }

        $self->{global}->{$$row[0]} = {
            page_life_expectancy => $$row[1],
            display => get_instances_name($$row[0]),
        };
    }
}

sub get_instances_name {
    my ($object_name) = @_;
    
    my ($instance) = $object_name =~ /(?<=\$)(.*?)(?=\:)/;
    
    return $instance;
}

1;

__END__

=head1 MODE

Check MSSQL page life expectancy.

=over 8

=item B<--filter-instance>

Filter instance by name (Can be a regex).

=item B<--warning-page-life-expectancy>

Threshold warning.

=item B<--critical-page-life-expectancy>

Threshold critical.

=back

=cut
