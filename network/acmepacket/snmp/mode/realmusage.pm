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

package network::acmepacket::snmp::mode::realmusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'realm', type => 1, cb_prefix_output => 'prefix_realm_output', message_multiple => 'All realms are ok' }
    ];    
    
    $self->{maps_counters}->{realm} = [
        { label => 'current-in-sessions', nlabel => 'realm.sessions.in.current.count', set => {
                key_values => [ { name => 'apSigRealmStatsCurrentActiveSessionsInbound' }, { name => 'display' } ],
                output_template => 'Current Inbound Sessions : %s',
                perfdatas => [
                    { label => 'current_inbound_sessions', value => 'apSigRealmStatsCurrentActiveSessionsInbound', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'current-in-sessions-rate', nlabel => 'realm.sessions.in.rate.count', set => {
                key_values => [ { name => 'apSigRealmStatsCurrentSessionRateInbound' }, { name => 'display' } ],
                output_template => 'Current Inbound Sessions Rate : %s/s',
                perfdatas => [
                    { label => 'current_inbound_sessions_rate', value => 'apSigRealmStatsCurrentSessionRateInbound', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'total-in-sessions', nlabel => 'realm.sessions.in.total.count', set => {
                key_values => [ { name => 'apSigRealmStatsTotalSessionsInbound', diff => 1 }, { name => 'display' } ],
                output_template => 'Total Inbound Sessions : %s',
                perfdatas => [
                    { label => 'total_inbound_sessions', value => 'apSigRealmStatsTotalSessionsInbound', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'current-out-sessions', nlabel => 'realm.sessions.out.current.count', set => {
                key_values => [ { name => 'apSigRealmStatsCurrentActiveSessionsOutbound' }, { name => 'display' } ],
                output_template => 'Current Outbound Sessions : %s',
                perfdatas => [
                    { label => 'current_outbound_sessions', value => 'apSigRealmStatsCurrentActiveSessionsOutbound', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'current-out-sessions-rate', nlabel => 'realm.sessions.out.current.count', set => {
                key_values => [ { name => 'apSigRealmStatsCurrentSessionRateOutbound' }, { name => 'display' } ],
                output_template => 'Current Outbound Sessions Rate : %s/s',
                perfdatas => [
                    { label => 'current_outbound_sessions_rate', value => 'apSigRealmStatsCurrentSessionRateOutbound', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'total-out-sessions', nlabel => 'realm.sessions.out.total.count', set => {
                key_values => [ { name => 'apSigRealmStatsTotalSessionsOutbound', diff => 1 }, { name => 'display' } ],
                output_template => 'Total Outbound Sessions : %s',
                perfdatas => [
                    { label => 'total_outbound_sessions', value => 'apSigRealmStatsTotalSessionsOutbound', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },        
        { label => 'avg-qos-rfactor', nlabel => 'realm.rfactor.qos.average.count', set => {
                key_values => [ { name => 'apSigRealmStatsAverageQoSRFactor' }, { name => 'display' } ],
                output_template => 'Average QoS RFactor : %s',
                perfdatas => [
                    { label => 'avg_qos_rfactor', value => 'apSigRealmStatsAverageQoSRFactor', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'total-rfactor', nlabel => 'realm.rfactor.execeded.total.count', set => {
                key_values => [ { name => 'apSigRealmStatsTotalMajorRFactorExceeded', diff => 1 }, { name => 'display' } ],
                output_template => 'Total Rfactor Exceeded : %s',
                perfdatas => [
                    { label => 'total_rfactor', value => 'apSigRealmStatsTotalMajorRFactorExceeded', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_realm_output {
    my ($self, %options) = @_;
    
    return "Realm '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"           => { name => 'filter_name' },
                                });
    
    return $self;
}

my $oid_apSigRealmStatsRealmName = '.1.3.6.1.4.1.9148.3.2.1.2.4.1.2';
my $mapping = {
    apSigRealmStatsCurrentActiveSessionsInbound     => { oid => '.1.3.6.1.4.1.9148.3.2.1.2.4.1.3' },
    apSigRealmStatsCurrentSessionRateInbound        => { oid => '.1.3.6.1.4.1.9148.3.2.1.2.4.1.4' },
    apSigRealmStatsCurrentActiveSessionsOutbound    => { oid => '.1.3.6.1.4.1.9148.3.2.1.2.4.1.5' },
    apSigRealmStatsCurrentSessionRateOutbound       => { oid => '.1.3.6.1.4.1.9148.3.2.1.2.4.1.6' },
    apSigRealmStatsTotalSessionsInbound             => { oid => '.1.3.6.1.4.1.9148.3.2.1.2.4.1.7' },
    apSigRealmStatsTotalSessionsOutbound            => { oid => '.1.3.6.1.4.1.9148.3.2.1.2.4.1.11' },
    apSigRealmStatsAverageQoSRFactor                => { oid => '.1.3.6.1.4.1.9148.3.2.1.2.4.1.24' },
    apSigRealmStatsTotalMajorRFactorExceeded        => { oid => '.1.3.6.1.4.1.9148.3.2.1.2.4.1.27' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_apSigRealmStatsRealmName, nothing_quit => 1);
    $self->{realm} = {};
    foreach my $oid (keys %{$snmp_result}) {
        $oid =~ /\.(\d+)$/;
        my $instance = $1;      
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping realm '" . $snmp_result->{$oid} . "'.", debug => 1);
            next;
        }
        
        $self->{realm}->{$instance} = { display => $snmp_result->{$oid} };
    }
    $options{snmp}->load(oids => [$mapping->{apSigRealmStatsCurrentActiveSessionsInbound}->{oid}, $mapping->{apSigRealmStatsCurrentSessionRateInbound}->{oid},
        $mapping->{apSigRealmStatsCurrentActiveSessionsOutbound}->{oid}, $mapping->{apSigRealmStatsCurrentSessionRateOutbound}->{oid},
        $mapping->{apSigRealmStatsTotalSessionsInbound}->{oid}, $mapping->{apSigRealmStatsTotalSessionsOutbound}->{oid},
        $mapping->{apSigRealmStatsAverageQoSRFactor}->{oid}, $mapping->{apSigRealmStatsTotalMajorRFactorExceeded}->{oid}
        ], 
        instances => [keys %{$self->{realm}}], instance_regexp => '^(.*)$');
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    foreach (keys %{$self->{realm}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);        
        
        foreach my $name (keys %$mapping) {
            $self->{realm}->{$_}->{$name} = $result->{$name};
        }
    }
    
    if (scalar(keys %{$self->{realm}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No realm found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "acmepacket_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check realm usage.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'current-in-sessions', 'current-in-sessions-rate', 'total-in-sessions',
'current-out-sessions', 'current-out-sessions-rate', 'total-out-session',
'avg-qos-rfactor', 'total-rfactor'.

=item B<--critical-*>

Threshold critical.
Can be: 'current-in-sessions', 'current-in-sessions-rate', 'total-in-sessions',
'current-out-sessions', 'current-out-sessions-rate', 'total-out-session',
'avg-qos-rfactor', 'total-rfactor'.

=item B<--filter-name>

Filter by realm name (can be a regexp).

=back

=cut
