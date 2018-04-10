#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

my $instance_mode;

sub custom_status_threshold {
    my ($self, %options) = @_;
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        if (defined($instance_mode->{option_results}->{critical_status}) && $instance_mode->{option_results}->{critical_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_status}) && $instance_mode->{option_results}->{warning_status} ne '' &&
                 eval "$instance_mode->{option_results}->{warning_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'Status : ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_apSipSAStatsSessionAgentStatus'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'sip', type => 1, cb_prefix_output => 'prefix_sip_output', message_multiple => 'All SIPs are ok' }
    ];
    
    $self->{maps_counters}->{sip} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'apSipSAStatsSessionAgentStatus' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
        { label => 'in-sessions-rate', set => {
                key_values => [ { name => 'apSipSAStatsTotalSessionsInbound', diff => 1 }, { name => 'display' } ],
                output_template => 'Inbound Sessions Rate : %.2f/s',
                per_second => 1,
                perfdatas => [
                    { label => 'inbound_sessions_rate', value => 'apSipSAStatsTotalSessionsInbound_per_second', template => '%.2f',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'out-sessions-rate', set => {
                key_values => [ { name => 'apSipSAStatsTotalSessionsOutbound', diff => 1 }, { name => 'display' } ],
                output_template => 'Outbound Sessions Rate : %.2f/s',
                per_second => 1,
                perfdatas => [
                    { label => 'outbound_sessions_rate', value => 'apSipSAStatsTotalSessionsOutbound_per_second', template => '%.2f',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'latency', set => {
                key_values => [ { name => 'apSipSAStatsAverageLatency' }, { name => 'display' } ],
                output_template => 'Average Latency : %s ms',
                perfdatas => [
                    { label => 'avg_latency', value => 'apSipSAStatsAverageLatency_absolute', template => '%s',
                      unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'asr', set => {
                key_values => [ { name => 'apSipSAStatsPeriodASR' }, { name => 'display' } ],
                output_template => 'Answer-to-seizure Ratio : %s %%',
                perfdatas => [
                    { label => 'asr', value => 'apSipSAStatsPeriodASR_absolute', template => '%s',
                      unit => '%', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub prefix_sip_output {
    my ($self, %options) = @_;
    
    return "SIP '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"       => { name => 'filter_name' },
                                  "warning-status:s"    => { name => 'warning_status', default => '' },
                                  "critical-status:s"   => { name => 'critical_status', default => '%{status} =~ /outOfService|constraintsViolation|inServiceTimedOut/i' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $instance_mode = $self;
    $self->change_macros();
}

sub change_macros {
    my ($self, %options) = @_;

    foreach (('warning_status', 'critical_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

my %map_status = (
    0 => 'disabled', 1 => 'outOfService',
    2 => 'standby', 3 => 'inService',
    4 => 'constraintsViolation', 5 => 'inServiceTimedOut',
    6 => 'oosprovisionedresponse',
);
my $oid_apSipSAStatsSessionAgentHostname = '.1.3.6.1.4.1.9148.3.2.1.2.2.1.2';
my $mapping = {
    apSipSAStatsTotalSessionsInbound    => { oid => '.1.3.6.1.4.1.9148.3.2.1.2.2.1.8' },
    apSipSAStatsTotalSessionsOutbound   => { oid => '.1.3.6.1.4.1.9148.3.2.1.2.2.1.12' },
    apSipSAStatsPeriodASR               => { oid => '.1.3.6.1.4.1.9148.3.2.1.2.2.1.19' },
    apSipSAStatsAverageLatency          => { oid => '.1.3.6.1.4.1.9148.3.2.1.2.2.1.20' },
    apSipSAStatsSessionAgentStatus      => { oid => '.1.3.6.1.4.1.9148.3.2.1.2.2.1.22', map => \%map_status },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_apSipSAStatsSessionAgentHostname, nothing_quit => 1);
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
    $options{snmp}->load(oids => [$mapping->{apSipSAStatsTotalSessionsInbound}->{oid}, $mapping->{apSipSAStatsTotalSessionsOutbound}->{oid},
        $mapping->{apSipSAStatsPeriodASR}->{oid}, $mapping->{apSipSAStatsAverageLatency}->{oid},
        $mapping->{apSipSAStatsSessionAgentStatus}->{oid}
        ], 
        instances => [keys %{$self->{sip}}], instance_regexp => '^(.*)$');
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
    
    $self->{cache_name} = "acmepacket_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
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
