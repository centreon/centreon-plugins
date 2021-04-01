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

package centreon::common::fortinet::fortigate::snmp::mode::sessions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_average_output {
    my ($self, %options) = @_;

    return 'Average session setup rate: ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'average', type => 0, cb_prefix_output => 'prefix_average_output' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'active', nlabel => 'sessions.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => 'Current active sessions: %d',
                perfdatas => [
                    { label => 'sessions', template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{average} = [
        { label => 'setup-1min', nlabel => 'sessions.setup.1min.count', set => {
                key_values => [ { name => 'setup_1min' } ],
                output_template => '%d (1min)',
                perfdatas => [
                    { label => 'session_avg_setup1', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'setup-10min', nlabel => 'sessions.setup.10min.count', set => {
                key_values => [ { name => 'setup_10min' } ],
                output_template => '%d (10min)',
                perfdatas => [
                    { label => 'session_avg_setup10', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'setup-30min', nlabel => 'sessions.setup.30min.count', set => {
                key_values => [ { name => 'setup_30min' } ],
                output_template => '%d (30min)',
                perfdatas => [
                    { label => 'session_avg_setup30', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'setup-60min', nlabel => 'sessions.setup.60min.count', set => {
                key_values => [ { name => 'setup_60min' } ],
                output_template => '%d (60min)',
                perfdatas => [
                    { label => 'session_avg_setup60', template => '%d', min => 0 }
                ]
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_fgSysSesCount = '.1.3.6.1.4.1.12356.101.4.1.8.0';
    my $oid_fgSysSesRate1 = '.1.3.6.1.4.1.12356.101.4.1.11.0';
    my $oid_fgSysSesRate10 = '.1.3.6.1.4.1.12356.101.4.1.12.0';
    my $oid_fgSysSesRate30 = '.1.3.6.1.4.1.12356.101.4.1.13.0';
    my $oid_fgSysSesRate60 = '.1.3.6.1.4.1.12356.101.4.1.14.0';
    my $result = $options{snmp}->get_leef(
        oids => [
            $oid_fgSysSesCount, $oid_fgSysSesRate1, 
            $oid_fgSysSesRate10, $oid_fgSysSesRate30, $oid_fgSysSesRate60
        ],
        nothing_quit => 1
    );

    $self->{global} = { active => $result->{$oid_fgSysSesCount} };
    $self->{average} = {
        setup_1min => $result->{$oid_fgSysSesRate1},
        setup_10min => $result->{$oid_fgSysSesRate10},
        setup_30min => $result->{$oid_fgSysSesRate30},
        setup_60min => $result->{$oid_fgSysSesRate60}
    };
}

1;

__END__

=head1 MODE

Check sessions (FORTINET-FORTIGATE-MIB).

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'active', 'setup-1min', 'setup-10min', 'setup-30min', 'setup-60min'.

=back

=cut
