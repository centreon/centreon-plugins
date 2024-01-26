#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::fritzbox::upnp::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use POSIX;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_uptime_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        unit => $self->{instance_mode}->{option_results}->{unit},
        value => floor($self->{result_values}->{uptime} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_uptime_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{uptime} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'physical link status is %s and %s is %s',
        $self->{result_values}->{link_status},
        $self->{result_values}->{wan_access_type},
        $self->{result_values}->{connection_status}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'connection-status',
            type => 2,
            critical_default => '%{link_status} !~ /^up$/i and %{connection_status} !~ /^connected$/i',
            set => {
                key_values => [
                    { name => 'connection_status' }, { name => 'link_status' }, { name => 'wan_access_type' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'uptime', nlabel => 'system.uptime', set => {
                key_values      => [ { name => 'uptime' }, { name => 'uptime_human' } ],
                output_template => 'uptime: %s',
                output_use => 'uptime_human',
                closure_custom_perfdata => $self->can('custom_uptime_perfdata'),
                closure_custom_threshold_check => $self->can('custom_uptime_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'unit:s' => { name => 'unit', default => 's' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 's';
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};

    my $infos = $options{custom}->request(url => 'WANCommonIFC1', ns => 'WANCommonInterfaceConfig', verb => 'GetCommonLinkProperties');
    $self->{global}->{wan_access_type} = $infos->{'s:Body'}->{'u:GetCommonLinkPropertiesResponse'}->{NewWANAccessType};
    $self->{global}->{link_status} = $infos->{'s:Body'}->{'u:GetCommonLinkPropertiesResponse'}->{NewPhysicalLinkStatus};

    $infos = $options{custom}->request(url => 'WANIPConn1', ns => 'WANIPConnection', verb => 'GetStatusInfo');
    $self->{global}->{connection_status} = $infos->{'s:Body'}->{'u:GetStatusInfoResponse'}->{NewConnectionStatus};
    $self->{global}->{uptime} = $infos->{'s:Body'}->{'u:GetStatusInfoResponse'}->{NewUptime}; # seconds
    $self->{global}->{uptime_human} = centreon::plugins::misc::change_seconds(value => $self->{global}->{uptime});
}

1;

__END__

=head1 MODE

Check system.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='uptime'

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
Can use special variables like: %{connection_status}, %{link_status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{link_status} !~ /^up$/i and %{connection_status} !~ /^connected$/i').
Can use special variables like: %{connection_status}, %{link_status}

=item B<--unit>

Select the unit for uptime threshold. May be 's' for seconds, 'm' for minutes,
'h' for hours, 'd' for days, 'w' for weeks. Default is days.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'uptime'.

=back

=cut
