#
# Copyright 2021 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and alarm monitoring for
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

package centreon::common::frogfoot::snmp::mode::load;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_load_output {
    my ($self, %options) = @_;

    return 'Load average ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'loadaverage', type => 0, cb_prefix_output => 'prefix_load_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{loadaverage} = [
        { label => 'load1', nlabel => 'system.loadaverage.1m.count', set => {
                key_values => [ { name => 'load1' } ],
                output_template => '%.2f (1m)',
                perfdatas => [
                    { template => '%.2f', min => 0 }
                ]
            }
        },
        { label => 'load5', nlabel => 'system.loadaverage.5m.count', set => {
                key_values => [ { name => 'load5' } ],
                output_template => '%.2f (5m)',
                perfdatas => [
                    { template => '%.2f', min => 0 }
                ]
            }
        },
        { label => 'load15', nlabel => 'system.loadaverage.15m.count', set => {
                key_values => [ { name => 'load15' } ],
                output_template => '%.2f (15m)',
                perfdatas => [
                    { template => '%.2f', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $mapping = {
    load_descr  => { oid => '.1.3.6.1.4.1.10002.1.1.1.4.2.1.2' }, # loadDescr
    load_value  => { oid => '.1.3.6.1.4.1.10002.1.1.1.4.2.1.3' }  # loadValue
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_load_entry = '.1.3.6.1.4.1.10002.1.1.1.4.2.1'; # loadEntry
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_load_entry,
        start => $mapping->{load_descr}->{oid},
        nothing_quit => 1
    );

    $self->{loadaverage} = {};
    foreach (keys %$snmp_result) {
        next if (! /^$mapping->{load_descr}->{oid}\.(\d+)$/);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);
        if ($result->{load_descr} =~ /(\d+)/) {
            $self->{loadaverage}->{'load' . $1} = $result->{load_value};
        }
    }
};

1;

__END__

=head1 MODE

Check the load average.

=over 8

=item B<--warning-*> B<--critical-*> 

Thresholds where '*' can be: load1, load5, load15

=back

=cut
