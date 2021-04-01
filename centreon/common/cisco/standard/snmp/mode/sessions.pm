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

package centreon::common::cisco::standard::snmp::mode::sessions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'connections', type => 0, cb_prefix_output => 'prefix_connections_output', skipped_code => { -10 => 1 } },
        { name => 'sessions', type => 0, cb_prefix_output => 'prefix_sessions_output', skipped_code => { -10 => 1 } },
    ];
    $self->{maps_counters}->{connections} = [
        { label => 'connections-current', set => {
                key_values => [ { name => 'cufwConnGlobalNumActive' } ],
                output_template => 'current : %s', output_error_template => "current : %s",
                perfdatas => [
                    { label => 'connections_current', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'connections-1m', set => {
                key_values => [ { name => 'cufwConnGlobalConnSetupRate1' } ],
                output_template => 'average last 1min : %s', output_error_template => "average last 1min : %s",
                perfdatas => [
                    { label => 'connections_1m', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'connections-5m', set => {
                key_values => [ { name => 'cufwConnGlobalConnSetupRate5' } ],
                output_template => 'average last 5min : %s', output_error_template => "average last 5min : %s",
                perfdatas => [
                    { label => 'connections_5m', template => '%d', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{sessions} = [
        { label => 'sessions-total', set => {
                key_values => [ { name => 'crasNumSessions' } ],
                output_template => 'total : %s', output_error_template => "total : %s",
                perfdatas => [
                    { label => 'sessions_total', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'sessions-email-current', set => {
                key_values => [ { name => 'crasEmailNumSessions' } ],
                output_template => 'current email proxy : %s', output_error_template => "current email proxy : %s",
                perfdatas => [
                    { label => 'sessions_email_current', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'sessions-email-psec', set => {
                key_values => [ { name => 'crasEmailCumulateSessions', per_second => 1 } ],
                output_template => 'email proxy : %.2f/s', output_error_template => "email proxy : %s",
                perfdatas => [
                    { label => 'sessions_email_psec', template => '%.2f', min => 0 },
                ],
            }
        },
        { label => 'sessions-ipsec-current', set => {
                key_values => [ { name => 'crasIPSecNumSessions' } ],
                output_template => 'current ipsec : %s', output_error_template => "current ipsec : %s",
                perfdatas => [
                    { label => 'sessions_ipsec_current', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'sessions-ipsec-psec', set => {
                key_values => [ { name => 'crasIPSecCumulateSessions', per_second => 1 } ],
                output_template => 'ipsec : %.2f/s', output_error_template => "ipsec : %s",
                perfdatas => [
                    { label => 'sessions_ipsec_psec', template => '%.2f', min => 0 },
                ],
            }
        },
        { label => 'sessions-l2l-current', set => {
                key_values => [ { name => 'crasL2LNumSessions' } ],
                output_template => 'current LAN to LAN : %s', output_error_template => "current LAN to LAN : %s",
                perfdatas => [
                    { label => 'sessions_l2l_current', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'sessions-l2l-psec', set => {
                key_values => [ { name => 'crasL2LCumulateSessions', per_second => 1 } ],
                output_template => 'LAN to LAN : %.2f/s', output_error_template => "LAN to LAN : %s",
                perfdatas => [
                    { label => 'sessions_l2l_psec', template => '%.2f', min => 0 },
                ],
            }
        },
        { label => 'sessions-lb-current', set => {
                key_values => [ { name => 'crasLBNumSessions' } ],
                output_template => 'current load balancing : %s', output_error_template => "current load balancing : %s",
                perfdatas => [
                    { label => 'sessions_lb_current', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'sessions-lb-psec', set => {
                key_values => [ { name => 'crasLBCumulateSessions', per_second => 1 } ],
                output_template => 'load balancing : %.2f/s', output_error_template => "load balancing : %s",
                perfdatas => [
                    { label => 'sessions_lb_psec', template => '%.2f', min => 0 },
                ],
            }
        },
        { label => 'sessions-svc-current', set => {
                key_values => [ { name => 'crasSVCNumSessions' } ],
                output_template => 'current SVC : %s', output_error_template => "current SVC : %s",
                perfdatas => [
                    { label => 'sessions_svc_current', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'sessions-svc-psec', set => {
                key_values => [ { name => 'crasSVCCumulateSessions', per_second => 1 } ],
                output_template => 'SVC : %.2f/s', output_error_template => "SVC : %s",
                perfdatas => [
                    { label => 'sessions_svc_psec', template => '%.2f', min => 0 },
                ],
            }
        },
        { label => 'sessions-webvpn-current', set => {
                key_values => [ { name => 'crasWebvpnNumSessions' } ],
                output_template => 'current webvpn : %s', output_error_template => "current webvpn : %s",
                perfdatas => [
                    { label => 'sessions_webvpn_current', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'sessions-webvpn-psec', set => {
                key_values => [ { name => 'crasWebvpnCumulateSessions', per_second => 1 } ],
                output_template => 'webvpn : %.2f/s', output_error_template => "webvpn : %s",
                perfdatas => [
                    { label => 'sessions_webvpn_psec',template => '%.2f', min => 0 },
                ],
            }
        },
    ];
}

sub prefix_connections_output {
    my ($self, %options) = @_;
    
    return "Connections ";
}

sub prefix_sessions_output {
    my ($self, %options) = @_;
    
    return "Sessions ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {                               
    });

    return $self;
}

my %oids_connections = (
    cufwConnGlobalNumActive         => '.1.3.6.1.4.1.9.9.491.1.1.1.6.0',
    cufwConnGlobalConnSetupRate1    => '.1.3.6.1.4.1.9.9.491.1.1.1.10.0',
    cufwConnGlobalConnSetupRate5    => '.1.3.6.1.4.1.9.9.491.1.1.1.11.0',
);
my %oids_sessions = (    
    crasNumSessions             => '.1.3.6.1.4.1.9.9.392.1.3.1.0',
    crasEmailNumSessions        => '.1.3.6.1.4.1.9.9.392.1.3.23.0',
    crasEmailCumulateSessions   => '.1.3.6.1.4.1.9.9.392.1.3.24.0',
    crasIPSecNumSessions        => '.1.3.6.1.4.1.9.9.392.1.3.26.0',
    crasIPSecCumulateSessions   => '.1.3.6.1.4.1.9.9.392.1.3.27.0',
    crasL2LNumSessions          => '.1.3.6.1.4.1.9.9.392.1.3.29.0',
    crasL2LCumulateSessions     => '.1.3.6.1.4.1.9.9.392.1.3.30.0',
    crasLBNumSessions           => '.1.3.6.1.4.1.9.9.392.1.3.32.0',
    crasLBCumulateSessions      => '.1.3.6.1.4.1.9.9.392.1.3.33.0',
    crasSVCNumSessions          => '.1.3.6.1.4.1.9.9.392.1.3.35.0',
    crasSVCCumulateSessions     => '.1.3.6.1.4.1.9.9.392.1.3.36.0',
    crasWebvpnNumSessions       => '.1.3.6.1.4.1.9.9.392.1.3.38.0',
    crasWebvpnCumulateSessions  => '.1.3.6.1.4.1.9.9.392.1.3.39.0',
);

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{cache_name} = "cisco_standard_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    
    $self->{connections} = {};
    $self->{sessions} = {};
    
    $self->{results} = $options{snmp}->get_leef(oids => [values %oids_connections, values %oids_sessions],
                                                nothing_quit => 1);
    foreach my $name (keys %oids_connections) {
        next if (!defined($self->{results}->{$oids_connections{$name}}) || $self->{results}->{$oids_connections{$name}} == 0);
        $self->{connections}->{$name} = $self->{results}->{$oids_connections{$name}};
    }
    foreach my $name (keys %oids_sessions) {
        next if (!defined($self->{results}->{$oids_sessions{$name}}) || $self->{results}->{$oids_sessions{$name}} == 0);
        $self->{sessions}->{$name} = $self->{results}->{$oids_sessions{$name}};
    }
}

1;

__END__

=head1 MODE

Check sessions. 

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'connections-current', 'connections-1m', 'connections-5m',
'sessions-total', 'sessions-email-current', 'sessions-email-psec',
'sessions-ipsec-current', 'sessions-ipsec-psec', 'sessions-l2l-current', 'sessions-lb-psec'
'sessions-lb-current', 'sessions-lb-psec', 'sessions-svc-current', 'sessions-svc-psec',
'sessions-webvpn-current', 'sessions-webvpn-psec'.

=item B<--critical-*>

Threshold critical.
Can be: 'connections-current', 'connections-1m', 'connections-5m',
'sessions-total', 'sessions-email-current', 'sessions-email-psec',
'sessions-ipsec-current', 'sessions-ipsec-psec', 'sessions-l2l-current', 'sessions-lb-psec'
'sessions-lb-current', 'sessions-lb-psec', 'sessions-svc-current', 'sessions-svc-psec',
'sessions-webvpn-current', 'sessions-webvpn-psec'.

=back

=cut
