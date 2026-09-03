#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package cloud::zscaler::ztb::restapi::mode::clusteripsec;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use POSIX;
use DateTime;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_last_refresh_perfdata {
    my ($self, %options) = @_;

    my $instances = [];
    foreach (@{$self->{instance_mode}->{custom_perfdata_instances}}) {
        push @$instances, $self->{result_values}->{$_};
    }

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        unit => $self->{instance_mode}->{option_results}->{unit},
        instances => $instances,
        value => $self->{result_values}->{lastRefreshTime} >= 0 ? floor($self->{result_values}->{lastRefreshTime} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }) : $self->{result_values}->{lastRefreshTime},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_last_refresh_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{lastRefreshTime} >= 0 ? floor($self->{result_values}->{lastRefreshTime} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }) : $self->{result_values}->{lastRefreshTime},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of IPsec tunnels ';
}

sub prefix_tunnel_output {
    my ($self, %options) = @_;

    return sprintf(
        "tunnel '%s' [cluster: %s] ",
        $options{instance_value}->{tunnelName},
        $options{instance_value}->{clusterName}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        { name => 'tunnels', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_tunnel_output', message_multiple => 'All IPsec tunnels are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        {   label => 'tunnels-ipsec-detected', display_ok => 0, nlabel => 'tunnels.ipsec.detected.count',
            unknown_default => '@0',
            set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{tunnels} = [
        {
            label => 'ike-status',
            type => COUNTER_KIND_TEXT,
            critical_default => '%{ikeStatus} !~ /established/',
            set => {
                key_values => [
                    { name => 'ikeStatus' },
                    { name => 'clusterName' }, { name => 'tunnelName' }
                ],
                output_template => 'IKE status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'sa-status',
            type => COUNTER_KIND_TEXT,
            critical_default => '%{saStatus} !~ /established/',
            set => {
                key_values => [
                    { name => 'saStatus' },
                    { name => 'clusterName' }, { name => 'tunnelName' }
                ],
                output_template => 'SA status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'last-refresh-time', nlabel => 'tunnel.ipsec.refresh.time.last', set => {
                key_values  => [
                    { name => 'lastRefreshTime' }, { name => 'lastRefreshTimeHuman' }, 
                    { name => 'clusterName' }, { name => 'tunnelName' }
                ],
                output_template => 'last refresh: %s',
                output_use => 'lastRefreshTimeHuman',
                closure_custom_perfdata => $self->can('custom_last_refresh_perfdata'),
                closure_custom_threshold_check => $self->can('custom_last_refresh_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-cluster-name:s'      => { name => 'include_cluster_name',  default => '' },
        'exclude-cluster-name:s'      => { name => 'exclude_cluster_name',  default => '' },
        'include-tunnel-name:s'       => { name => 'include_tunnel_name',  default => '' },
        'exclude-tunnel-name:s'       => { name => 'exclude_tunnel_name',  default => '' },
        'include-cluster-id:s'        => { name => 'include_cluster_id',  default => '' },
        'exclude-cluster-id:s'        => { name => 'exclude_cluster_id',  default => '' },
        'custom-perfdata-instances:s' => { name => 'custom_perfdata_instances' },
        'unit:s'                      => { name => 'unit', default => 's' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{custom_perfdata_instances}) || $self->{option_results}->{custom_perfdata_instances} eq '') {
        $self->{option_results}->{custom_perfdata_instances} = '%(clusterName) %(tunnelName)';
    }

    $self->{custom_perfdata_instances} = $self->custom_perfdata_instances(
        option_name => '--custom-perfdata-instances',
        instances => $self->{option_results}->{custom_perfdata_instances},
        labels => { clusterName => 1, tunnelName => 1 }
    );

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 's';
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $gateways = $options{custom}->get_gateways();
    my $cluster = {};

    $self->{global} = { detected => 0 };
    $self->{tunnels} = {};
    foreach my $gw (@$gateways) {
        next if (defined($cluster->{ $gw->{cluster_id} }));
        $cluster->{ $gw->{cluster_id} } = 1;

        next if is_excluded($gw->{cluster_name}, $self->{option_results}->{include_cluster_name}, $self->{option_results}->{exclude_cluster_name});
        next if is_excluded($gw->{cluster_id}, $self->{option_results}->{include_cluster_id}, $self->{option_results}->{exclude_cluster_id});

        my $ctime = time();
        my $tunnels = $options{custom}->get_cluster_ipsec_status(cluster_id => $gw->{cluster_id});
        foreach my $tun (@$tunnels) {
            next if ($tun->{status} !~ /^(.*?):/);
            my $name = $1;

            next if is_excluded($name, $self->{option_results}->{include_tunnel_name}, $self->{option_results}->{exclude_tunnel_name});

            my $ikeStatus = 'unknown';
            $ikeStatus = $1 if ($tun->{status} =~ /^.*?:.*?,\s*(.*?)\s*,\s*IKEv2/);

            my ($lastRefreshTime, $lastRefreshTimeHuman);
            if ($tun->{time_stamp} =~ /(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)/) {
                 my $dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6, time_zone  => 'UTC');
                 $lastRefreshTime = $ctime - $dt->epoch();
                 $lastRefreshTimeHuman =  centreon::plugins::misc::change_seconds(value => $lastRefreshTime);
            }

            $self->{tunnels}->{ $gw->{cluster_id} . $name } = {
                clusterName          => $gw->{cluster_name},
                tunnelName           => $name,
                saStatus             => lc($tun->{child_sa_status}),
                ikeStatus            => lc($ikeStatus),
                lastRefreshTime      => $lastRefreshTime,
                lastRefreshTimeHuman => $lastRefreshTimeHuman
            };

            $self->{global}->{detected}++;
        }
    }
}

1;

__END__

=head1 MODE

Check clusters IPsec tunnel.

=over 8

=item B<--include-cluster-name>

Include cluster names (regexp).

=item B<--exclude-cluster-name>

Exclude cluster names (regexp).

=item B<--include-tunnel-name>

Include tunnel names (regexp).

=item B<--exclude-tunnel-name>

Exclude tunnel names (regexp).

=item B<--include-cluster-id>

Include cluster IDs (regexp).

=item B<--exclude-cluster-id>

Exclude cluster IDs (regexp).

=item B<--custom-perfdata-instances>

Define perfdatas instance (default: '%(clusterName) %(tunnelName)')

=item B<--unit>

Select the time unit for refresh thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks (default: 's').

=item B<--unknown-sa-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{clusterName}, %{tunnelName}, %{saStatus}

=item B<--warning-sa-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{clusterName}, %{tunnelName}, %{saStatus}

=item B<--critical-sa-status>

Define the conditions to match for the status to be CRITICAL (default: '%{saStatus} !~ /established/').
You can use the following variables: %{clusterName}, %{tunnelName}, %{saStatus}

=item B<--unknown-ike-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{clusterName}, %{tunnelName}, %{ikeStatus}

=item B<--warning-ike-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{clusterName}, %{tunnelName}, %{ikeStatus}

=item B<--critical-ike-status>

Define the conditions to match for the status to be CRITICAL (default: '%{ikeStatus} !~ /established/').
You can use the following variables: %{clusterName}, %{tunnelName}, %{ikeStatus}

=item B<--warning-tunnels-ipsec-detected>

Threshold.

=item B<--critical-tunnels-ipsec-detected>

Threshold.

=item B<--warning-last-refresh-time>

Threshold.

=item B<--critical-last-refresh-time>

Threshold.

=back

=cut
