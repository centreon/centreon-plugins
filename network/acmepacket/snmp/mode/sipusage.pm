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

package network::acmepacket::snmp::mode::sipusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status};
}

sub prefix_sip_output {
    my ($self, %options) = @_;
    
    return "SIP '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'sip', type => 1, cb_prefix_output => 'prefix_sip_output', message_multiple => 'All SIPs are ok' }
    ];
    
    $self->{maps_counters}->{sip} = [
        { label => 'status', type => 2, critical_default => '%{status} =~ /outOfService|constraintsViolation|inServiceTimedOut/i', set => {
                key_values => [ { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'in-sessions-rate', nlabel => 'sip.sessions.in.rate', set => {
                key_values => [ { name => 'sessions_inbound', per_second => 1 }, { name => 'display' } ],
                output_template => 'inbound sessions rate: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'out-sessions-rate', nlabel => 'sip.sessions.out.rate', set => {
                key_values => [ { name => 'sessions_outbound', per_second => 1 }, { name => 'display' } ],
                output_template => 'outbound sessions rate: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'latency', nlabel => 'sip.stats.latency.milliseconds', set => {
                key_values => [ { name => 'average_latency' }, { name => 'display' } ],
                output_template => 'average latency: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'asr', nlabel => 'sip.stats.asr.percentage', set => {
                key_values => [ { name => 'period_asr' }, { name => 'display' } ],
                output_template => 'answer-to-seizure ratio: %s %%',
                perfdatas => [
                    { template => '%s', unit => '%', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' }
    });

    return $self;
}

my %map_status = (
    0 => 'disabled', 1 => 'outOfService',
    2 => 'standby', 3 => 'inService',
    4 => 'constraintsViolation', 5 => 'inServiceTimedOut',
    6 => 'oosprovisionedresponse',
);
my $oid_name = '.1.3.6.1.4.1.9148.3.2.1.2.2.1.2'; # apSipSAStatsSessionAgentHostname
my $mapping = {
    sessions_inbound  => { oid => '.1.3.6.1.4.1.9148.3.2.1.2.2.1.8' }, # apSipSAStatsTotalSessionsInbound
    sessions_outbound => { oid => '.1.3.6.1.4.1.9148.3.2.1.2.2.1.12' }, # apSipSAStatsTotalSessionsOutbound
    period_asr        => { oid => '.1.3.6.1.4.1.9148.3.2.1.2.2.1.19' }, # apSipSAStatsPeriodASR
    average_latency   => { oid => '.1.3.6.1.4.1.9148.3.2.1.2.2.1.20' }, # apSipSAStatsAverageLatency
    status            => { oid => '.1.3.6.1.4.1.9148.3.2.1.2.2.1.22', map => \%map_status } # apSipSAStatsSessionAgentStatus
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_name, nothing_quit => 1);
    $self->{sip} = {};
    foreach my $oid (keys %{$snmp_result}) {
        $oid =~ /\.(\d+)$/;
        my $instance = $1;      
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping SIP '" . $snmp_result->{$oid} . "'.", debug => 1);
            next;
        }
        
        $self->{sip}->{$instance} = { display => $snmp_result->{$oid} };
    }
    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [keys %{$self->{sip}}],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    foreach (keys %{$self->{sip}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);        

        foreach my $name (keys %$mapping) {
            $self->{sip}->{$_}->{$name} = $result->{$name};
        }
    }

    if (scalar(keys %{$self->{sip}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No SIP found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = 'acmepacket_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check SIP usage.

=over 8

=item B<--warning-status>

Set warning threshold for status (Default: -).
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /outOfService|constraintsViolation|inServiceTimedOut/i').
Can used special variables like: %{status}

=item B<--warning-*>

Threshold warning.
Can be: 'in-sessions-rate', 'out-sessions-rate', 'latency', 'asr'.

=item B<--critical-*>

Threshold critical.
Can be: 'in-sessions-rate', 'out-sessions-rate', 'latency', 'asr'.

=item B<--filter-name>

Filter by SIP name (can be a regexp).

=back

=cut
