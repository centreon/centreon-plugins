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

package centreon::common::riverbed::steelhead::snmp::mode::diskutilization;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'usage', set => {
                key_values => [ { name => 'dsAveDiskUtilization' } ],
                output_template => 'Datastore Usage: %.2f%%',
                perfdatas => [
                    { label => 'used', template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'hits', set => {
                key_values => [ { name => 'dsHitsTotal', per_second => 1 } ],
                output_template => 'Hits: %s/s',
                perfdatas => [
                    { label => 'hits', template => '%.2f', min => 0, unit => 'hits/s' }
                ]
            }
        },
        { label => 'misses', set => {
                key_values => [ { name => 'dsMissTotal', per_second => 1 } ],
                output_template => 'Misses: %s/s',
                perfdatas => [
                    { label => 'misses', template => '%.2f', min => 0, unit => 'misses/s' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments =>{
    });

    return $self;
}

my $mappings = {
    common    => {
        dsHitsTotal => { oid => '.1.3.6.1.4.1.17163.1.1.5.4.1' },
        dsMissTotal => { oid => '.1.3.6.1.4.1.17163.1.1.5.4.2' },
        dsCostPerSegment => { oid => '.1.3.6.1.4.1.17163.1.1.5.4.3' },
        dsAveDiskUtilization => { oid => '.1.3.6.1.4.1.17163.1.1.5.4.4' }
    },
    ex => {
        dsHitsTotal => { oid => '.1.3.6.1.4.1.17163.1.51.5.4.1' },
        dsMissTotal => { oid => '.1.3.6.1.4.1.17163.1.51.5.4.2' },
        dsCostPerSegment => { oid => '.1.3.6.1.4.1.17163.1.51.5.4.3' },
        dsAveDiskUtilization => { oid => '.1.3.6.1.4.1.17163.1.51.5.4.4' }
    }
};

my $oids = {
    common => '.1.3.6.1.4.1.17163.1.1.5.4',
    ex => '.1.3.6.1.4.1.17163.1.51.5.4',
};

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oids->{common}, start => $mappings->{common}->{dsHitsTotal}->{oid}, end => $mappings->{common}->{dsAveDiskUtilization}->{oid} },
            { oid => $oids->{ex}, start => $mappings->{ex}->{dsHitsTotal}->{oid}, end => $mappings->{ex}->{dsAveDiskUtilization}->{oid} }
        ]
    );

    foreach my $equipment (keys %{$oids}) {
        next if (!%{$results->{$oids->{$equipment}}});

        my $result = $options{snmp}->map_instance(mapping => $mappings->{$equipment}, results => $results->{$oids->{$equipment}}, instance => 0);

        $self->{global} = {
            dsHitsTotal => $result->{dsHitsTotal},
            dsMissTotal => $result->{dsMissTotal},
            dsAveDiskUtilization => $result->{dsAveDiskUtilization}
        };
    }

    $self->{cache_name} = 'riverbed_steelhead_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() .
        '_' . $self->{mode} . '_' . md5_hex('all');
}

1;

__END__

=head1 MODE

Check disk utilization : usage, hits and misses.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'usage' (%), 'hits' (/s), 'misses' (/s).


=item B<--critical-usage>

Threshold critical.
Can be: 'usage' (%), 'hits' (/s), 'misses' (/s).

=back

=cut
