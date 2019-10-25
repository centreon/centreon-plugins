#
# Copyright 2019 Centreon (http://www.centreon.com/)
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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);
use DateTime;
use centreon::plugins::misc;

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'system operational mode: ' . $self->{result_values}->{oper_mode};
    return $msg;
}

sub custom_av_output {
    my ($self, %options) = @_;

    return sprintf(
        "antivirus version '%s', last update %s",
        $self->{result_values}->{av_version_absolute},
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{av_lastupdate_time_absolute})
    );
}

sub custom_threat_output {
    my ($self, %options) = @_;

    return sprintf(
        "threat version '%s', last update %s",
        $self->{result_values}->{threat_version_absolute},
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{threat_lastupdate_time_absolute})
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'system', type => 0, message_separator => ' - ' }
    ];

    $self->{maps_counters}->{system} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'oper_mode' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'av-update', nlabel => 'system.antivirus.lastupdate.time.seconds', set => {
                key_values => [ { name => 'av_lastupdate_time' }, { name => 'av_version' } ],
                closure_custom_output => $self->can('custom_av_output'),
                perfdatas => [
                    { value => 'av_lastupdate_time_absolute', template => '%d', min => 0, unit => 's' }
                ],
            }
        },
        { label => 'threat-update', nlabel => 'system.threat.lastupdate.time.seconds', set => {
                key_values => [ { name => 'threat_lastupdate_time' }, { name => 'threat_version' } ],
                closure_custom_output => $self->can('custom_threat_output'),
                perfdatas => [
                    { value => 'threat_lastupdate_time_absolute', template => '%d', min => 0, unit => 's' }
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{oper_mode} !~ /normal/i' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub get_diff_time {
    my ($self, %options) = @_;

    # '2019/10/15 12:03:58 BST'
    return if ($options{time} !~ /^\s*(\d{4})\/(\d{2})\/(\d{2})\s+(\d+):(\d+):(\d+)\s+(\S+)/);

    my $tz = $7;
    $tz = 'GMT' if ($tz eq 'BST');
    $tz = 'Europe/Paris' if ($tz eq 'CEST');
    $tz = 'America/New_York' if ($tz eq 'EST');
    my $dt = DateTime->new(
        year       => $1,
        month      => $2,
        day        => $3,
        hour       => $4,
        minute     => $5,
        second     => $6,
        time_zone  => $tz
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
}

1;

__END__

=head1 MODE

Check system.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{oper_mode}

=item B<--critical-status>

Set critical threshold for status (Default: '%{oper_mode} !~ /normal/i').
Can used special variables like: %{oper_mode}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'av-update' (s), 'threat-update' (s).

=back

=cut
