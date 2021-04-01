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

package apps::backup::tsm::local::mode::drives;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'online', set => {
                key_values => [ { name => 'online' } ],
                output_template => 'online : %s',
                perfdatas => [
                    { label => 'online', value => 'online', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'offline', set => {
                key_values => [ { name => 'offline' } ],
                output_template => 'offline : %s',
                perfdatas => [
                    { label => 'offline', value => 'offline', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'unavailable', set => {
                key_values => [ { name => 'unavailable' } ],
                output_template => 'unavailable : %s',
                perfdatas => [
                    { label => 'unavailable', value => 'unavailable', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'empty', set => {
                key_values => [ { name => 'empty' } ],
                output_template => 'empty : %s',
                perfdatas => [
                    { label => 'empty', value => 'empty', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'loaded', set => {
                key_values => [ { name => 'loaded' } ],
                output_template => 'loaded : %s',
                perfdatas => [
                    { label => 'loaded', value => 'loaded', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'unloaded', set => {
                key_values => [ { name => 'unloaded' } ],
                output_template => 'unloaded : %s',
                perfdatas => [
                    { label => 'unloaded', value => 'unloaded', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'reserved', set => {
                key_values => [ { name => 'reserved' } ],
                output_template => 'reserved : %s',
                perfdatas => [
                    { label => 'reserved', value => 'reserved', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'unknown', set => {
                key_values => [ { name => 'unknown' } ],
                output_template => 'unknown : %s',
                perfdatas => [
                    { label => 'unknown', value => 'unknown', template => '%s', min => 0 },
                ],
            }
        },
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return "Total Drives ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $response = $options{custom}->execute_command(
        query => "SELECT library_name, drive_name, online, drive_state FROM drives"
    );
    $self->{global} = { 
        online => 0, offline => 0, 
        unavailable => 0, empty => 0, loaded => 0, unloaded => 0, reserved => 0, unknown => 0,
    };

    my %mapping_online = (yes => 'online', no => 'offline');
    while ($response =~ /^(.*?),(.*?),(yes|no),(unavailable|empty|loaded|unloaded|reserved|unknown)$/mgi) {
        my ($library, $drive, $online, $state) = ($1, $2, lc($3), lc($4));
                
        $self->{global}->{$mapping_online{$online}}++;
        $self->{global}->{$state}++;
    }
}

1;

__END__

=head1 MODE

Check drives.

=over 8

=item B<--warning-*>

Set warning threshold. Can be : 'online', 'offline', 'unavailable',
'empty', 'loaded', 'unloaded', 'reserved', 'unknown'.

=item B<--critical-*>

Set critical threshold. Can be : Can be : 'online', 'offline', 'unavailable',
'empty', 'loaded', 'unloaded', 'reserved', 'unknown'.

=back

=cut

