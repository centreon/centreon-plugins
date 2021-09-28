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

package network::f5::bigip::snmp::mode::apm;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'vs', type => 3, cb_prefix_output => 'prefix_vs_output', cb_long_output => 'vs_long_output', indent_long_output => '    ', message_multiple => 'All virtual servers are ok', 
            group => [                
                { name => 'ap', display_long => 1, cb_prefix_output => 'prefix_ap_output',  message_multiple => 'All access profiles are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'sessions-created', nlabel => 'system.sessions.created.count', set => {
                key_values => [ { name => 'apmAccessStatTotalSessions', diff => 1 } ],
                output_template => 'created sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'sessions-active', nlabel => 'system.sessions.active.count', set => {
                key_values => [ { name => 'apmAccessStatCurrentActiveSessions' } ],
                output_template => 'active sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'sessions-pending', nlabel => 'system.sessions.pending.count', set => {
                key_values => [ { name => 'apmAccessStatCurrentPendingSessions' } ],
                output_template => 'pending sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{ap} = [
        { label => 'ap-sessions-created', nlabel => 'accessprofile.sessions.created.count', set => {
                key_values => [ { name => 'apmPaStatTotalSessions', diff => 1 } ],
                output_template => 'created sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'ap-sessions-active', nlabel => 'accessprofile.sessions.active.count', set => {
                key_values => [ { name => 'apmPaStatCurrentActiveSessions' } ],
                output_template => 'active sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'ap-sessions-pending', nlabel => 'accessprofile.sessions.pending.count', set => {
                key_values => [ { name => 'apmPaStatCurrentPendingSessions' } ],
                output_template => 'pending sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_vs_output {
    my ($self, %options) = @_;

    return "Virtual server '" . $options{instance_value}->{display} . "' : ";
}

sub vs_long_output {
    my ($self, %options) = @_;

    return "checking virtual server '" . $options{instance_value}->{display} . "'";
}

sub prefix_ap_output {
    my ($self, %options) = @_;

    return "access profile '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-vs:s' => { name => 'filter_vs' },
        'filter-ap:s' => { name => 'filter_ap' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        apmPaStatTotalSessions          =>  { oid => '.1.3.6.1.4.1.3375.2.6.1.1.3.1.3' },
        apmPaStatCurrentActiveSessions  =>  { oid => '.1.3.6.1.4.1.3375.2.6.1.1.3.1.5' },
        apmPaStatCurrentPendingSessions =>  { oid => '.1.3.6.1.4.1.3375.2.6.1.1.3.1.6' },
    };
    my $mapping2 = {
        apmAccessStatTotalSessions          => { oid => '.1.3.6.1.4.1.3375.2.6.1.4.2' },
        apmAccessStatCurrentActiveSessions  => { oid => '.1.3.6.1.4.1.3375.2.6.1.4.3' },
        apmAccessStatCurrentPendingSessions => { oid => '.1.3.6.1.4.1.3375.2.6.1.4.4' },
    };

    my $oid_apmPaStatEntry = '.1.3.6.1.4.1.3375.2.6.1.1.3.1';
    my $oid_apmAccessStat = '.1.3.6.1.4.1.3375.2.6.1.4';
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_apmPaStatEntry, start => $mapping->{apmPaStatTotalSessions}->{oid}, end => $mapping->{apmPaStatCurrentPendingSessions}->{oid} },
            { oid => $oid_apmAccessStat },
        ],
        nothing_quit => 1,
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$oid_apmAccessStat}, instance => '0');
    $self->{global} = { %$result };

    $self->{vs} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_apmPaStatEntry}}) {
        next if ($oid !~ /^$mapping->{apmPaStatTotalSessions}->{oid}\.(.*)$/);
        my $instance = $1;

        my @indexes = split(/\./, $instance);
        my $ap_name = $self->{output}->decode(join('', map(chr($_), splice(@indexes, 0, shift(@indexes)) )));
        my $vs_name = $self->{output}->decode(join('', map(chr($_), splice(@indexes, 0, shift(@indexes)) )));

        $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_apmPaStatEntry}, instance => $instance);
        if (defined($self->{option_results}->{filter_vs}) && $self->{option_results}->{filter_vs} ne '' &&
            $vs_name !~ /$self->{option_results}->{filter_vs}/) {
            $self->{output}->output_add(long_msg => "skipping virtual server '" . $vs_name . "'.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_ap}) && $self->{option_results}->{filter_ap} ne '' &&
            $ap_name !~ /$self->{option_results}->{filter_ap}/) {
            $self->{output}->output_add(long_msg => "skipping access profile '" . $ap_name . "'.", debug => 1);
            next;
        }

        if (!defined($self->{vs}->{$vs_name})) {
            $self->{vs}->{$vs_name} = {
                display => $vs_name,
                ap => {},
            };
        }

        $self->{vs}->{$vs_name}->{ap}->{$ap_name} = {
            display => $ap_name,
            %$result
        };
    }

    if (scalar(keys %{$self->{vs}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No virtual server found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = "f5_bigip_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_vs}) ? md5_hex($self->{option_results}->{filter_vs}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_ap}) ? md5_hex($self->{option_results}->{filter_ap}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check access policy manager.

=over 8

=item B<--filter-vs>

Filter virtual server name (can be a regexp).

=item B<--filter-ap>

Filter access profile name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'sessions-created', 'sessions-active', 'sessions-pending',
'ap-sessions-created', 'ap-sessions-active', 'ap-sessions-pending'.

=back

=cut
