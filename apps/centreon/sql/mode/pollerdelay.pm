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

package apps::centreon::sql::mode::pollerdelay;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'poller', type => 1, cb_prefix_output => 'prefix_poller_output', message_multiple => 'All poller delay for last update are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{poller} = [
        { label => 'delay', set => {
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

sub prefix_poller_output {
    my ($self, %options) = @_;

    return "Poller '" . $options{instance_value}->{display} . "' : ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s" => { name => 'filter_name' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    $options{sql}->query(query => q{
        SELECT instance_id, name, last_alive, running FROM centreon_storage.instances WHERE deleted = '0';
    });

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

Check the delay of the last update from a poller to the Central server.
The mode should be used with mysql plugin and dyn-mode option.

=over 8

=item B<--filter-name>

Filter by poller name (can be a regexp).

=item B<--warning-delay>

Threshold warning in seconds.

=item B<--critical-delay>

Threshold critical in seconds.

=back

=cut
