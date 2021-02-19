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

package apps::antivirus::mcafee::webgateway::snmp::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'cpu-utilization', nlabel => 'system.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_util' } ],
                output_template => 'cpu usage: %.2f%%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ]
            }
        },
        { label => 'dns-resolve-time', nlabel => 'system.dns.resolve.time.milliseconds', set => {
                key_values => [ { name => 'dns_time' } ],
                output_template => 'time to resolve dns: %sms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0 }
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

my $oid_stCPULoad = '.1.3.6.1.4.1.1230.2.7.2.5.1.0';
my $oid_stResolveHostViaDNS = '.1.3.6.1.4.1.1230.2.7.2.5.6.0';

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_leef(
        oids => [ $oid_stCPULoad, $oid_stResolveHostViaDNS ], 
        nothing_quit => 1
    );

    $self->{global} = {
        cpu_util => $results->{$oid_stCPULoad},
        dns_time => $results->{$oid_stResolveHostViaDNS}
    };
}

1;

__END__

=head1 MODE

Check system.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
(Example: --filter-counters='cpu')

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-utilization', 'dns-resolve-time'.

=back

=cut
