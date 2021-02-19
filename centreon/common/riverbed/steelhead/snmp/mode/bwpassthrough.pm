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

package centreon::common::riverbed::steelhead::snmp::mode::bwpassthrough;

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
                key_values => [ { name => 'bwPassThroughIn', per_second => 1 } ],
                output_template => 'Traffic In (Wan2Lan): %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'traffic_in', template => '%s', min => 0, unit => 'B/s' }
                ]
            }
        },
        { label => 'traffic-out', set => {
                key_values => [ { name => 'bwPassThroughOut', per_second => 1 } ],
                output_template => 'Traffic Out (Lan2Wan): %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'traffic_out', template => '%s', min => 0, unit => 'B/s' }
                ]
            }
        }
    ];
}

sub prefix_output {
    my ($self, %options) = @_;
    
    return 'Passthrough ';
}

my $mappings = {
    common    => {
        bwPassThroughIn => { oid => '.1.3.6.1.4.1.17163.1.1.5.3.3.1' },
        bwPassThroughOut => { oid => '.1.3.6.1.4.1.17163.1.1.5.3.3.2' }
    },
    ex => {
        bwPassThroughIn => { oid => '.1.3.6.1.4.1.17163.1.51.5.3.3.1' },
        bwPassThroughOut => { oid => '.1.3.6.1.4.1.17163.1.51.5.3.3.2' }
    }
};

my $oids = {
    common => '.1.3.6.1.4.1.17163.1.1.5.3.3',
    ex => '.1.3.6.1.4.1.17163.1.51.5.3.3'
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oids->{common}, start => $mappings->{common}->{bwPassThroughIn}->{oid}, end => $mappings->{common}->{bwPassThroughOut}->{oid} },
            { oid => $oids->{ex}, start => $mappings->{ex}->{bwPassThroughIn}->{oid}, end => $mappings->{ex}->{bwPassThroughOut}->{oid} }
        ]
    );

    foreach my $equipment (keys %{$oids}) {
        next if (!%{$results->{$oids->{$equipment}}});

        $self->{global} = $options{snmp}->map_instance(mapping => $mappings->{$equipment}, results => $results->{$oids->{$equipment}}, instance => 0);
    }

    $self->{cache_name} = 'riverbed_steelhead_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() .
        '_' . $self->{mode} . '_' . md5_hex('all');
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
