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

package apps::gorgone::restapi::mode::events;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub prefix_path_output {
    my ($self, %options) = @_;

    return "Path '" . $options{instance_value}->{display} . "' ";
}

sub path_long_output {
    my ($self, %options) = @_;

    return "checking path '" . $options{instance_value}->{display} . "'";
}

sub prefix_event_output {
    my ($self, %options) = @_;

    return "event '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'paths', type => 3, cb_prefix_output => 'prefix_path_output', cb_long_output => 'path_long_output', indent_long_output => '    ', message_multiple => 'All paths are ok',
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'events', cb_prefix_output => 'prefix_event_output', message_multiple => 'All events are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'events-total', nlabel => 'path.events.total.count', set => {
                key_values => [ { name => 'total', diff => 1 } ],
                output_template => 'total events: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{events} = [
         { label => 'event-total', nlabel => 'event.total.count', set => {
                key_values => [ { name => 'total', diff => 1 } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
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

    my $infos = $options{custom}->request_api(endpoint => '/api/internal/information');

    $self->{paths} = {};
    foreach my $path (('internal', 'external')) {
        next if (!defined($infos->{data}->{counters}->{$path}));

        $self->{paths}->{$path} = {
            display => $path,
            global => { total => $infos->{data}->{counters}->{$path}->{total} },
            events => {}
        };
        foreach my $event (keys %{$infos->{data}->{counters}->{$path}}) {
            next if ($event eq 'total');
            $self->{paths}->{$path}->{events}->{$event} = {
                display => $event,
                total => $infos->{data}->{counters}->{$path}->{$event}
            };
        }
    }

    $self->{cache_name} = 'gorgone_' . $self->{mode} . '_' . $options{custom}->get_hostname()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check events.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='events-total'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'events-total', 'event-total'.

=back

=cut
