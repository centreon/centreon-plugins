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

package database::mongodb::mode::queries;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
   
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output' },
    ];
   
    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'queries.total.persecond', set => {
                key_values => [ { name => 'total', diff => 1 } ],
                per_second => 1,
                output_template => 'Total : %d',
                perfdatas => [
                    { value => 'total_per_second', template => '%d', unit => '/s', min => 0 },
                ],
            }
        },
    ];
    
    foreach ('insert', 'query', 'update', 'delete', 'getmore', 'command') {
        push @{$self->{maps_counters}->{global}}, {
            label => $_, nlabel => 'queries.' . $_ . '.persecond',  display_ok => 0, set => {
                key_values => [ { name => $_, diff => 1 } ],
                per_second => 1,
                output_template => $_ . ' : %.2f',
                perfdatas => [
                    { value => $_ . '_per_second',template => '%.2f', unit => '/s', min => 0 },
                ],
            }
        };
        push @{$self->{maps_counters}->{global}}, {
            label => $_ . '-count', , nlabel => 'queries.' . $_ . '.count', display_ok => 0, set => {
                key_values => [ { name => $_, diff => 1 } ],
                output_template => $_ . ' count : %d',
                perfdatas => [
                    { value => $_ . '_absolute', template => '%d', min => 0 },
                ],
            }
        };
    }
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Requests ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{custom} = $options{custom};

    $self->{global} = {};
    
    my $server_stats = $self->{custom}->run_command(
        database => 'admin',
        command => $self->{custom}->ordered_hash(serverStatus => 1),
    );
    
    foreach my $querie (keys %{$server_stats->{opcounters}}) {
        $self->{global}->{$querie} = $server_stats->{opcounters}->{$querie};
        $self->{global}->{total} += $server_stats->{opcounters}->{$querie};
    }

    $self->{cache_name} = "mongodb_" . $self->{mode} . '_' . $self->{custom}->get_hostname() . '_' . $self->{custom}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check number of queries executed (absolute and per second).

=over 8

=item B<--warning-queries-*-persecond>

Threshold warning.
Can be: 'total', 'insert', 'query', 'update',
'delete', 'getmore', 'command'

=item B<--critical-queries-*-persecond>

Threshold critical.
Can be: 'total', 'insert', 'query', 'update',
'delete', 'getmore', 'command'

=item B<--warning-queries-*-count>

Threshold warning.
Can be: 'insert', 'query', 'update',
'delete', 'getmore', 'command'

=item B<--critical-queries-*-count>

Threshold critical.
Can be: 'insert', 'query', 'update',
'delete', 'getmore', 'command'

=back

=cut
