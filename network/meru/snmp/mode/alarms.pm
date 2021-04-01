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

package network::meru::snmp::mode::alarms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Alarms ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'alarms-critical', nlabel => 'alarms.critical.count', set => {
                key_values => [ { name => 'critical' } ],
                output_template => 'critical: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'alarms-major', nlabel => 'alarms.major.count', set => {
                key_values => [ { name => 'major' } ],
                output_template => 'major: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'alarms-minor', nlabel => 'alarms.minor.count', set => {
                key_values => [ { name => 'minor' } ],
                output_template => 'minor: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    return $self;
}

my $mapping = {
    critical => { oid => '.1.3.6.1.4.1.15983.1.1.3.1.13.16' }, # mwSystemGeneralTotalCritAlarms
    major    => { oid => '.1.3.6.1.4.1.15983.1.1.3.1.13.17' }, # mwSystemGeneralTotalMajorAlarms
    minor    => { oid => '.1.3.6.1.4.1.15983.1.1.3.1.13.18' }  # mwSystemGeneralTotalMinorAlarms
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    $self->{global} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);
}

1;

__END__

=head1 MODE

Check alarms.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'alarms-critical', 'alarms-major', 'alarms-minor'.

=back

=cut
