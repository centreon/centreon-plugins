#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package apps::centreon::sql::mode::executiontime;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_value_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "Service '%s' of host '%s' execution time is '%.2fs'",
        $self->{result_values}->{description},
        $self->{result_values}->{name},
        $self->{result_values}->{execution_time}
    );
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'services', type => 1 }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'count', nlabel => 'services.execution.exceed.count', set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Number of services exceeding execution time: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{services} = [
        { label => 'list', set => {
                key_values => [ { name => 'description' }, { name => 'name' } , { name => 'execution_time' } ],
                closure_custom_output => $self->can('custom_value_output'),
                closure_custom_perfdata => sub { return 0; }
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-poller:s'             => { name => 'filter_poller' },
        'centreon-storage-database:s' => { name => 'centreon_storage_database', default => 'centreon_storage' },
        'execution-time:s'            => { name => 'execution_time', default => '20' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    $options{sql}->query(
        query => 'SELECT h.name, s.description, s.execution_time
            FROM ' . $self->{option_results}->{centreon_storage_database} .  '.services s, ' . $self->{option_results}->{centreon_storage_database} .  '.hosts h
            WHERE s.execution_time > ' . $self->{option_results}->{execution_time} .  '
                AND h.enabled = 1
                AND (h.name NOT LIKE "\_Module\_%" OR h.name LIKE "\_Module\_Meta%")
                AND s.enabled = 1
                AND h.host_id = s.host_id'
    );
    
    $self->{global}->{count} = 0;
    $self->{services} = {};
    while ((my $row = $options{sql}->fetchrow_hashref())) {
        if (defined($self->{option_results}->{filter_poller}) && $self->{option_results}->{filter_poller} ne '' &&
            $row->{poller} !~ /$self->{option_results}->{filter_poller}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $row->{self} . "': no matching filter.", debug => 1);
            next;
        }
        $self->{global}->{count}++;
        $self->{services}->{ $row->{name} . "-" . $row->{description} } = $row;
    }
}

1;

__END__

=head1 MODE

Check the number of services exceeding defined execution time.

=over 8

=item B<--execution-time>

Set the number of seconds which defines the
limit of execution time (default: '20').

=item B<--centreon-storage-database>

Centreon storage database name (default: 'centreon_storage').

=item B<--filter-poller>

Filter by poller name (regexp can be used).

=item B<--warning-count> B<--critical-count>

Thresholds on the number of services exceeding
defined execution time.

=back

=cut
