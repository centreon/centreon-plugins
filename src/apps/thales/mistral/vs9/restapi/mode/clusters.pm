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

package apps::thales::mistral::vs9::restapi::mode::clusters;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use POSIX;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_information_output {
    my ($self, %options) = @_;

    return sprintf(
        'virtual ip: %s, timeToSwitch: %s s',
        $self->{result_values}->{virtualIp},
        $self->{result_values}->{timeToSwitch}
    );
}

sub custom_cluster_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s, available for switching: %s',
        $self->{result_values}->{gatewaysClusterStatus},
        $self->{result_values}->{availableForSwitching}
    );
}

sub custom_member_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'connected status: %s [role: %s]',
        $self->{result_values}->{connectedStatus},
        $self->{result_values}->{role}
    );
}

sub custom_contact_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{time_contact_unit} },
        unit => $self->{instance_mode}->{option_results}->{time_contact_unit},
        instances => [$self->{result_values}->{clusterName}, $self->{result_values}->{memberName}],
        value => floor($self->{result_values}->{contact_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{time_contact_unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_contact_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{contact_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{time_contact_unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub cluster_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking cluster '%s'",
        $options{instance_value}->{clusterName}
    );
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return sprintf(
        "cluster '%s' ",
        $options{instance_value}->{clusterName}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of clusters ';
}

sub prefix_member_output {
    my ($self, %options) = @_;

    return sprintf(
        "member '%s' ",
        $options{instance_value}->{memberName}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'clusters', type => 3, cb_prefix_output => 'prefix_cluster_output', cb_long_output => 'cluster_long_output', indent_long_output => '    ', message_multiple => 'All clusters are ok',
            group => [
                { name => 'information', type => 0, skipped_code => { -10 => 1 } },
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'members', type => 1, cb_prefix_output => 'prefix_member_output', message_multiple => 'members are ok', display_long => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'clusters-detected', display_ok => 0, nlabel => 'clusters.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{information} = [
        {
            label => 'cluster-information',
            type => 2,
            set => {
                key_values => [ { name => 'virtualIp' }, { name => 'timeToSwitch' } ],
                closure_custom_output => $self->can('custom_information_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'cluster-status',
            type => 2,
            warning_default => '%{gatewaysClusterStatus} =~ /HAC_FAILOVER/i',
            critical_default => '%{gatewaysClusterStatus} =~ /HAC_FAILURE|HAC_DOWN|HAC_BACKUP_FAILURE/i',
            set => {
                key_values => [ { name => 'gatewaysClusterStatus' }, { name => 'availableForSwitching' }, { name => 'clusterName' } ],
                closure_custom_output => $self->can('custom_cluster_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{members} = [
        {
            label => 'member-status',
            type => 2,
            set => {
                key_values => [ { name => 'role' }, { name => 'connectedStatus' }, { name => 'clusterName' }, { name => 'memberName' } ],
                closure_custom_output => $self->can('custom_member_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'member-contact-last-time', nlabel => 'member.contact.last.time', set => {
                key_values      => [ { name => 'contact_seconds' }, { name => 'contact_human' }, { name => 'clusterName' }, { name => 'memberName' } ],
                output_template => 'last contact: %s',
                output_use => 'contact_human',
                closure_custom_perfdata => $self->can('custom_contact_perfdata'),
                closure_custom_threshold_check => $self->can('custom_contact_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-cluster-name:s' => { name => 'filter_cluster_name' },
        'time-contact-unit:s'   => { name => 'time_contact_unit', default => 's' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{time_contact_unit} eq '' || !defined($unitdiv->{$self->{option_results}->{time_contact_unit}})) {
        $self->{option_results}->{time_contact_unit} = 's';
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $clusters = $options{custom}->get_clusters();

    $self->{global} = { detected => 0 };
    $self->{clusters} = {};
    foreach my $cluster (@$clusters) {
        next if (defined($self->{option_results}->{filter_cluster_name}) && $self->{option_results}->{filter_cluster_name} ne '' &&
            $cluster->{name} !~ /$self->{option_results}->{filter_cluster_name}/);

        $self->{global}->{detected}++;
        $self->{clusters}->{ $cluster->{name} } = {
            clusterName => $cluster->{name},
            information => {
                virtualIp => $cluster->{virtualIp} . '/' . $cluster->{virtualNetmask},
                timeToSwitch => $cluster->{timeToSwitch}
            },
            status => {
                clusterName => $cluster->{name},
                gatewaysClusterStatus => $cluster->{gatewaysClusterStatus},
                availableForSwitching => defined($cluster->{availableForSwitching}) && $cluster->{availableForSwitching} =~ /true|1/i ? 'yes' : 'no'
            },
            members => {}
        };

        foreach ('master', 'backup') {
            $self->{clusters}->{ $cluster->{name} }->{members}->{ $cluster->{$_ . 'Origin'}->{name} } = {
                clusterName => $cluster->{name},
                memberName => $cluster->{$_ . 'Origin'}->{name},
                connectedStatus => lc($cluster->{$_ . 'OriginStatus'}->{connectedStatus}),
                role => $_
            };

            if ($cluster->{$_ . 'OriginStatus'}->{lastCheck} =~ /^\s*(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})\.\d+([+-].*)$/) {
                my $dt = DateTime->new(
                    year       => $1,
                    month      => $2,
                    day        => $3,
                    hour       => $4,
                    minute     => $5,
                    second     => $6,
                    time_zone  => $7
                );
                $self->{clusters}->{ $cluster->{name} }->{members}->{ $cluster->{$_ . 'Origin'}->{name} }->{contact_seconds} = 
                    time() - $dt->epoch();
                $self->{clusters}->{ $cluster->{name} }->{members}->{ $cluster->{$_ . 'Origin'}->{name} }->{contact_human} = centreon::plugins::misc::change_seconds(
                    value => $self->{clusters}->{ $cluster->{name} }->{members}->{ $cluster->{$_ . 'Origin'}->{name} }->{contact_seconds}
                );
            }
        }
    }
}

1;

__END__

=head1 MODE

Check clusters.

=over 8

=item B<--filter-cluster-name>

Filter clusters by name.

=item B<--unknown-cluster-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{gatewaysClusterStatus}, %{availableForSwitching}, %{clusterName}

=item B<--warning-cluster-status>

Define the conditions to match for the status to be WARNING (default: '%{gatewaysClusterStatus} =~ /HAC_FAILOVER/i').
You can use the following variables: %{gatewaysClusterStatus}, %{availableForSwitching}, %{clusterName}

=item B<--critical-cluster-status>

Define the conditions to match for the status to be CRITICAL (default: '%{gatewaysClusterStatus} =~ /HAC_FAILURE|HAC_DOWN|HAC_BACKUP_FAILURE/i').
You can use the following variables: %{gatewaysClusterStatus}, %{availableForSwitching}, %{clusterName}

=item B<--unknown-member-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{connectedStatus}, %{role}, %{memberName}

=item B<--warning-member-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{connectedStatus}, %{role}, %{memberName}

=item B<--critical-member-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{connectedStatus}, %{role}, %{memberName}

=item B<--time-contact-unit>

Select the time unit for contact threshold. May be 's' for seconds, 'm' for minutes,
'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'clusters-detected', 'member-contact-last-time'.

=back

=cut
