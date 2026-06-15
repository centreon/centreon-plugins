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

package database::mssql::mode::lockswaits;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::constants qw(:counters);
use centreon::plugins::misc qw(is_excluded);
use Digest::SHA qw(sha256_hex);

sub prefix_by_instance_output {
    my ($self, %options) = @_;

    return "instance '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'total', type => COUNTER_TYPE_GLOBAL },
        { name => 'by_instance', type => COUNTER_TYPE_INSTANCE}
    ];

    $self->{maps_counters}->{total} = [
        {
            label => 'lockswaits', type => COUNTER_KIND_METRIC, nlabel => 'total#mssql.lockswaits.perminute',
            set   => {
                key_values      => [ { name => 'total', per_minute => 1 } ],
                output_template => '%.2f total locks waits/min',
                perfdatas       => [
                    { template => '%.2f', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{by_instance} = [
        {
            label => 'lockswaits-by-instance', type => COUNTER_KIND_METRIC, nlabel => 'mssql.lockswaits.perminute',
            set   => {
                key_values      => [ { name => 'value', per_minute => 1 }, { name => 'display' } ],
                output_template => '%.2f locks waits/min',
                perfdatas       => [
                    { template => '%.2f', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "filter-database:s"  => { redirect => 'include_instance' },
        "include-instance:s" => { name => 'include_instance', default => '' },
        "exclude-instance:s" => { name => 'exclude_instance', default => '' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    $options{sql}->query(query => q{
        SELECT 
            instance_name, cntr_value
        FROM
            sys.dm_os_performance_counters
        WHERE
            object_name = 'SQLServer:Locks'
        AND
            counter_name LIKE 'Lock Waits/sec%'
    });

    my $query_result = $options{sql}->fetchall_arrayref();
    $self->{total}->{total} = 0;

    foreach my $row (@{$query_result}) {
        my ($instance, $value) = @$row;
        next if $instance eq '_Total';
        next if is_excluded($instance, $self->{option_results}->{include_instance}, $self->{option_results}->{exclude_instance}, output => $self->{output});
        $self->{by_instance}->{$instance} = {
            display => $instance,
            value => $value
        };
        $self->{total}->{total} += $value;
    }

    $self->{output}->option_exit(short_msg => "No locks waits counter found with given filters")
        unless $self->{by_instance} && keys %{$self->{by_instance}};

    $self->{cache_name} = 'mssql_' . $self->{mode} . '_' . $options{sql}->get_unique_id4save() . '_' .
        sha256_hex($self->{option_results}->{include_instance}) . '_' .
        sha256_hex($self->{option_results}->{exclude_instance});
}

1;

__END__

=head1 MODE

Check MSSQL locks-waits per minute

=over 8

=item B<--include-instance>

Filter to include instances (types of locks) to monitor with a regular expression.

=item B<--exclude-instance>

Filter to exclude instances (types of locks) to monitor with a regular expression.

=item B<--filter-database>

Deprecated option: use C<--include-instance> instead.

=item B<--warning-lockswaits>

Threshold.

=item B<--critical-lockswaits>

Threshold.

=item B<--warning-lockswaits-by-instance>

Threshold.

=item B<--critical-lockswaits-by-instance>

Threshold.

=back

=cut
