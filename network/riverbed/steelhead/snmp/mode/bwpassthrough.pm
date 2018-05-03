#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package network::riverbed::steelhead::snmp::mode::bwpassthrough;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'traffic-in', set => {
                key_values => [ { name => 'bwPassThroughIn', diff => 1 } ],
                output_template => 'Traffic In (Wan2Lan): %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'traffic_in', value => 'bwPassThroughIn_absolute',
                    template => '%s', min => 0, unit => 'B/s' },
                ],
            }
        },
        { label => 'traffic-out', set => {
                key_values => [ { name => 'bwPassThroughOut', diff => 1 } ],
                output_template => 'Traffic Out (Lan2Wan): %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'traffic_out', value => 'bwPassThroughOut_absolute',
                    template => '%s', min => 0, unit => 'B/s' },
                ],
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;
    
    return "Passthrough: ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $self->{version} = '0.1';
    $options{options}->add_options(arguments =>
                                { 
                                });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # STEELHEAD-MIB
    my $oids = {
        bwPassThroughIn => '.1.3.6.1.4.1.17163.1.1.5.3.3.1.0',
        bwPassThroughOut => '.1.3.6.1.4.1.17163.1.1.5.3.3.2.0',
    };

    # STEELHEAD-EX-MIB
    my $oids_ex = {
        bwPassThroughIn => '.1.3.6.1.4.1.17163.1.51.5.3.3.1.0',
        bwPassThroughOut => '.1.3.6.1.4.1.17163.1.51.5.3.3.2.0',
    };

    my $result = $options{snmp}->get_leef(oids => [ values %{$oids}, values %{$oids_ex} ], nothing_quit => 1);

    $self->{cache_name} = "riverbed_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() .
        '_' . $self->{mode} . '_' . md5_hex('all');
        
    $self->{global} = {};

    if (defined($result->{$oids->{bwPassThroughIn}})) {
        foreach (keys %{$oids}) {
            $self->{global}->{$_} = $result->{$oids->{$_}};
        }
    } else {
        foreach (keys %{$oids_ex}) {
	        $self->{global}->{$_} = $result->{$oids_ex->{$_}};
        }
    }
}

1;

__END__

=head1 MODE

Check passthrough bandwidth in both directions (STEELHEAD-MIB and STEELHEAD-EX-MIB).

=over 8

=item B<--warning-traffic-*>

Threshold warning (Can be: 'in' (Wan2Lan), 'out' (Lan2Wan))

=item B<--critical-traffic-*>

Threshold critical (Can be: 'in' (Wan2Lan), 'out' (Lan2Wan))

=over 8

=back

=cut
