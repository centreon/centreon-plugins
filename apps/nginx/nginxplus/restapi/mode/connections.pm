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

package apps::nginx::nginxplus::restapi::mode::connections;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub prefix_connection_output {
    my ($self, %options) = @_;
    
    return 'Connections ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'connection', type => 0, cb_prefix_output => 'prefix_connection_output' }
    ];

    $self->{maps_counters}->{connection} = [
        { label => 'active', nlabel => 'connections.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => 'active: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'idle', nlabel => 'connections.idle.count', set => {
                key_values => [ { name => 'idle' } ],
                output_template => 'idle: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'accepted', nlabel => 'connections.accepted.count', display_ok => 0, set => {
                key_values => [ { name => 'accepted', diff => 1 } ],
                output_template => 'accepted: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'dropped', nlabel => 'connections.dropped.count', display_ok => 0, set => {
                key_values => [ { name => 'dropped', diff => 1 } ],
                output_template => 'dropped: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
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

    my $result = $options{custom}->request_api(
        endpoint => '/connections'
    );

    $self->{connection} = {};
    foreach (keys %$result) {
        $self->{connection}->{$_} = $result->{$_};
    }

    $self->{cache_name} = 'nginx_nginxplus_' . $options{custom}->get_hostname()  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check connections.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='accepted'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'active', 'idle', 'accepted', 'dropped'.

=back

=cut
