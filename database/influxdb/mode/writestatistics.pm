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

package database::influxdb::mode::writestatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
   
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
   
    $self->{maps_counters}->{global} = [
        { label => 'points-written', nlabel => 'points.written.persecond', set => {
                key_values => [ { name => 'pointReq', per_second => 1 } ],
                output_template => 'Points Written: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 },
                ],
            }
        },
        { label => 'writes-ok', nlabel => 'writes.ok.persecond', set => {
                key_values => [ { name => 'writeOk', per_second => 1 } ],
                output_template => 'Writes Ok: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 },
                ],
            }
        },
        { label => 'writes-error', nlabel => 'writes.error.persecond', set => {
                key_values => [ { name => 'writeError', per_second => 1 } ],
                output_template => 'Writes Error: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 },
                ],
            }
        },
        { label => 'writes-drop', nlabel => 'writes.drop.persecond', set => {
                key_values => [ { name => 'writeDrop', per_second => 1 } ],
                output_template => 'Writes Drop: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 },
                ],
            }
        },
        { label => 'writes-timeout', nlabel => 'writes.timeout.persecond', set => {
                key_values => [ { name => 'writeTimeout', per_second => 1 } ],
                output_template => 'Writes Timeout: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 },
                ],
            }
        },
    ];
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
    
    my $results = $self->{custom}->query(queries => [ "SHOW STATS FOR 'write'" ]);
    
    my $i = 0;
    foreach my $column (@{$$results[0]->{columns}}) {
        $column =~ s/influxdb_//;
        $self->{global}->{$column} = $$results[0]->{values}[0][$i];
        $i++;
    }

    $self->{cache_name} = "influxdb_" . $self->{mode} . '_' . $self->{custom}->get_hostname() . '_' . $self->{custom}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check writes statistics to the data node.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'points-written', 'writes-ok', 'writes-error',
'writes-drop', 'writes-timeout'.

=item B<--critical-*>

Threshold critical.
Can be: 'points-written', 'writes-ok', 'writes-error',
'writes-drop', 'writes-timeout'.

=back

=cut
