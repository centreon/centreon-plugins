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

package apps::centreon::sql::mode::dsmqueue;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'host', type => 1, cb_prefix_output => 'prefix_host_output', message_multiple => 'All host queues are ok' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total-queue-cache', set => {
                key_values => [ { name => 'total_queue_cache' } ],
                output_template => 'Total current cache queue : %s',
                perfdatas => [
                    { label => 'total_queue_cache', value => 'total_queue_cache', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'total-queue-lock', set => {
                key_values => [ { name => 'total_queue_lock' } ],
                output_template => 'Total current lock queue : %s',
                perfdatas => [
                    { label => 'total_queue_lock', value => 'total_queue_lock', template => '%s', min => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{host} = [
        { label => 'host-queue-cache', set => {
                key_values => [ { name => 'num' }, { name => 'display' } ],
                output_template => 'current cache queue : %s',
                perfdatas => [
                    { label => 'host_queue_cache', value => 'num', template => '%s', 
                      min => 0, label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub prefix_host_output {
    my ($self, %options) = @_;
    
    return "Host '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-host-queue:s"         => { name => 'filter_host_queue' },
                                  "centreon-storage-database:s" => { name => 'centreon_storage_database', default => 'centreon_storage' },
                                  "centreon-database:s"         => { name => 'centreon_database', default => 'centreon' },
                                });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();

    $self->{global} = { total_queue_cache => 0, total_queue_lock => 0 };    
    my $query = "SELECT COUNT(*) as nb FROM " . $self->{option_results}->{centreon_storage_database} . ".mod_dsm_cache";
    $options{sql}->query(query => $query);
    if ((my $row = $options{sql}->fetchrow_hashref())) {
        $self->{global}->{total_queue_cache} = $row->{nb};
    }
    
    $query = "SELECT COUNT(*) as nb FROM " . $self->{option_results}->{centreon_storage_database} . ".mod_dsm_locks";
    $options{sql}->query(query => $query);
    if ((my $row = $options{sql}->fetchrow_hashref())) {
        $self->{global}->{total_queue_lock} = $row->{nb};
    }
    
    # check by poller
    $self->{host} = {};
    $query = "SELECT mod_dsm_pool.pool_host_id, mod_dsm_pool.pool_prefix, COUNT(*) as nb FROM " .  $self->{option_results}->{centreon_database} . ".mod_dsm_pool" . 
        " LEFT JOIN " . $self->{option_results}->{centreon_storage_database} . ".mod_dsm_cache ON mod_dsm_pool.pool_host_id = mod_dsm_cache.host_id AND mod_dsm_pool.pool_prefix = mod_dsm_cache.pool_prefix" .
        " GROUP BY mod_dsm_pool.pool_host_id, mod_dsm_pool.pool_prefix";
    $options{sql}->query(query => $query);
    while ((my $row = $options{sql}->fetchrow_hashref())) {
        my $name = $row->{pool_host_id} . '/' . $row->{pool_prefix};
        if (defined($self->{option_results}->{filter_host_queue}) && $self->{option_results}->{filter_host_queue} ne '' &&
            $name !~ /$self->{option_results}->{filter_host_queue}/) {
            $self->{output}->output_add(long_msg => "Skipping '" . $row->{name} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{host}->{$name} = { display => $name, num => $row->{nb} };
    }
}

1;

__END__

=head1 MODE

Check Centreon DSM queue usage.

=over 8

=item B<--centreon-storage-database>

Centreon storage database name (default: 'centreon_storage').

=item B<--centreon-database>

Centreon storage database name (default: 'centreon').

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^total-queue-cache$'

=item B<--warning-*>

Threshold warning.
Can be: Can be: 'total-queue-cache', 'total-queue-lock', 'host-queue-cache'.

=item B<--critical-*>

Threshold critical.
Can be: Can be: 'total-queue-cache', 'total-queue-lock', 'host-queue-cache'.

=item B<--filter-host-queue>

Filter by host and pool prefix name (regexp can be used).
Example: host1.queue1

=back

=cut
