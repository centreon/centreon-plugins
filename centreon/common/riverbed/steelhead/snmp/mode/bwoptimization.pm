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

package centreon::common::riverbed::steelhead::snmp::mode::bwoptimization;

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
        { label => 'wan2lan-lan', set => {
                key_values => [ { name => 'bwHCAggInLan', per_second => 1 } ],
                output_template => 'Wan2Lan on Lan: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'wan2lan_lan', template => '%s', min => 0, unit => 'B/s' }
                ]
            }
        },
        { label => 'wan2lan-wan', set => {
                key_values => [ { name => 'bwHCAggInWan', per_second => 1 } ],
                output_template => 'Wan2Lan on Wan: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'wan2lan_wan', template => '%s', min => 0, unit => 'B/s' }
                ]
            }
        },
        { label => 'lan2wan-lan', set => {
                key_values => [ { name => 'bwHCAggOutLan', per_second => 1 } ],
                output_template => 'Lan2Wan on Lan: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'lan2wan_lan', template => '%s', min => 0, unit => 'B/s' }
                ]
            }
        },
        { label => 'lan2wan-wan', set => {
                key_values => [ { name => 'bwHCAggOutWan', per_second => 1 } ],
                output_template => 'Lan2Wan on Wan: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'lan2wan_wan', template => '%s', min => 0, unit => 'B/s' }
                ]
            }
        }
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return 'Optimized ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
    });

    return $self;
}

my $mappings = {
    common    => {
        bwHCAggInLan => { oid => '.1.3.6.1.4.1.17163.1.1.5.6.1.1' },
        bwHCAggInWan => { oid => '.1.3.6.1.4.1.17163.1.1.5.6.1.2' },
        bwHCAggOutLan => { oid => '.1.3.6.1.4.1.17163.1.1.5.6.1.3' },
        bwHCAggOutWan => { oid => '.1.3.6.1.4.1.17163.1.1.5.6.1.4' }
    },
    ex => {
        bwHCAggInLan => { oid => '.1.3.6.1.4.1.17163.1.51.5.6.1.1' },
        bwHCAggInWan => { oid => '.1.3.6.1.4.1.17163.1.51.5.6.1.2' },
        bwHCAggOutLan => { oid => '.1.3.6.1.4.1.17163.1.51.5.6.1.3' },
        bwHCAggOutWan => { oid => '.1.3.6.1.4.1.17163.1.51.5.6.1.4' }
    }
};

my $oids = {
    common => '.1.3.6.1.4.1.17163.1.1.5.6.1',
    ex => '.1.3.6.1.4.1.17163.1.51.5.6.1'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_multiple_table(
        oids => [ 
            { oid => $oids->{common}, start => $mappings->{common}->{bwHCAggInLan}->{oid}, end => $mappings->{common}->{bwHCAggOutWan}->{oid} },
            { oid => $oids->{ex}, start => $mappings->{ex}->{bwHCAggInLan}->{oid}, end => $mappings->{ex}->{bwHCAggOutWan}->{oid} }
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

Total optimized bytes across all application ports in both directions and on both sides,
in bytes per second (STEELHEAD-MIB and STEELHEAD-EX-MIB).

=over 8

=item B<--warning-*>

Threshold warning (Can be: 'wan2lan-lan', 'wan2lan-wan',
'lan2wan-lan', 'lan2wan-wan')

=item B<--critical-*>

Threshold critical (Can be: 'wan2lan-lan', 'wan2lan-wan',
'lan2wan-lan', 'lan2wan-wan')

=over 8

=back

=cut
