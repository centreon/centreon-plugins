#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::paloalto::ssh::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use DateTime;
use centreon::plugins::misc;
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'system operational mode: ' . $self->{result_values}->{oper_mode};
}

sub custom_av_output {
    my ($self, %options) = @_;

    return sprintf(
        "antivirus version '%s', last update %s",
        $self->{result_values}->{av_version},
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{av_lastupdate_time})
    );
}

sub custom_threat_output {
    my ($self, %options) = @_;

    return sprintf(
        "threat version '%s', last update %s",
        $self->{result_values}->{threat_version},
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{threat_lastupdate_time})
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'system', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{system} = [
        { label => 'status', type => 2, critical_default => '%{oper_mode} !~ /normal/i', set => {
                key_values => [ { name => 'oper_mode' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'av-update', nlabel => 'system.antivirus.lastupdate.time.seconds', set => {
                key_values => [ { name => 'av_lastupdate_time' }, { name => 'av_version' } ],
                closure_custom_output => $self->can('custom_av_output'),
                perfdatas => [
                    { template => '%d', min => 0, unit => 's' }
                ]
            }
        },
        { label => 'threat-update', nlabel => 'system.threat.lastupdate.time.seconds', set => {
                key_values => [ { name => 'threat_lastupdate_time' }, { name => 'threat_version' } ],
                closure_custom_output => $self->can('custom_threat_output'),
                perfdatas => [
                    { template => '%d', min => 0, unit => 's' }
                ]
            }
        },
        { label => 'sessions-traffic', nlabel => 'system.sessions.traffic.count', set => {
                key_values => [ { name => 'throughput', diff => 1 } ],
                output_template => 'session traffic: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', unit => 'b/s', min => 0 }
                ]
            }
        },
        { label => 'sessions-total-active', nlabel => 'system.sessions.total.active.count', display_ok => 0, set => {
                key_values => [ { name => 'active_sessions' } ],
                output_template => 'total active sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
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
        'timezone:s' => { name => 'timezone' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{option_results}->{timezone} = 'GMT' if (!defined($self->{option_results}->{timezone}) || $self->{option_results}->{timezone} eq '');
}

sub get_diff_time {
    my ($self, %options) = @_;

    # '2019/10/15 12:03:58 BST'
    return if ($options{time} !~ /^\s*(\d{4})\/(\d{2})\/(\d{2})\s+(\d+):(\d+):(\d+)\s+(\S+)/);

    my $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
    my $dt = DateTime->new(
        year       => $1,
        month      => $2,
        day        => $3,
        hour       => $4,
        minute     => $5,
        second     => $6,
        %$tz
    );
    return (time() - $dt->epoch);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->execute_command(command => 'show system info');

    $self->{system} = {
        av_lastupdate_time     => $self->get_diff_time(time => $result->{system}->{'av-release-date'}),
        threat_lastupdate_time => $self->get_diff_time(time => $result->{system}->{'threat-release-date'}),
        av_version     => $result->{system}->{'av-version'},
        threat_version => $result->{system}->{'threat-version'},
        oper_mode      => $result->{system}->{'operational-mode'},
    };

    #Device is up          : 40 days 5 hours 53 mins 12 sec
    #Packet rate           : 15872/s
    #Throughput            : 111588 Kbps
    #Total active sessions : 12769
    #Active TCP sessions   : 5217
    #Active UDP sessions   : 7531
    #Active ICMP sessions  : 19
    $result = $options{custom}->execute_command(command => 'show system statistics session', text_output => 1);
    if ($result =~ /^Throughput\s*:\s*(\d+)\s+(..)/mi) {
        $self->{system}->{throughput} = centreon::plugins::misc::convert_bytes(value => $1, unit => $2);
    }
    if ($result =~ /^Total\s+active\s+sessions\s*:\s*(\d+)/mi) {
        $self->{system}->{active_sessions} = $1;
    }

    $self->{cache_name} = "paloalto_" . $self->{mode} . '_' . $options{custom}->get_hostname()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check system.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--timezone>

Timezone options. Default is 'GMT'.

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{oper_mode}

=item B<--critical-status>

Set critical threshold for status (Default: '%{oper_mode} !~ /normal/i').
Can used special variables like: %{oper_mode}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'av-update' (s), 'threat-update' (s),
'sessions-traffic' (b/s), 'sessions-total-active'.

=back

=cut
