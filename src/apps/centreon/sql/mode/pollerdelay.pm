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

package apps::centreon::sql::mode::pollerdelay;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::constants qw(:values :counters);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'poller', type => COUNTER_TYPE_INSTANCE, prefix_output => "Poller '%{display}' ", message_multiple => 'All poller delay for last update are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{poller} = [
        { label => 'delay', nlabel => 'centreon.poller.delay.seconds', set => {
                key_values => [ { name => 'delay' }, { name => 'display' } ],
                output_template => 'delay for last update is %d seconds',
                perfdatas => [
                    { label => 'delay', value => 'delay', template => '%s',
                      unit => 's', label_extra_instance => 1 },
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
        'filter-name:s'               => { name => 'filter_name' },
        'centreon-storage-database:s' => { name => 'centreon_storage_database', default => 'centreon_storage' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    $options{sql}->query(query => 'SELECT instance_id, name, last_alive, running FROM ' . $self->{option_results}->{centreon_storage_database} . ".instances WHERE deleted = '0'");

    my $result = $options{sql}->fetchall_arrayref();
    $self->{poller} = {};
    foreach my $row (@{$result}) {
         if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $$row[1] !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping poller '" . $$row[1] . "': no matching filter.", debug => 1);
            next;
        }
        
        if ($$row[3] == 0) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("%s is not running", $$row[1]));
            next;
        }
        
        my $delay = time() - $$row[2];
        $self->{poller}->{$$row[1]} = {
            display => $$row[1],
            delay => abs($delay),
        };
    }
}

1;

__END__

=head1 MODE

Check the delay of the last data update sent from a poller to the Central server.
The mode should be used with the database::mysql::plugin plugin and C<--dyn-mode> option.
Example: C<perl centreon_plugins.pl --plugin=database::mysql::plugin --dyn-mode=apps::centreon::sql::mode::pollerdelay ...>.

=over 8

=item B<--filter-name>

Filter by poller name (can be a regexp).

=item B<--centreon-storage-database>

Centreon storage database name (default: 'centreon_storage').

=item B<--warning-delay>

Warning threshold in seconds.

=item B<--critical-delay>

Critical threshold in seconds.

=back

=cut
