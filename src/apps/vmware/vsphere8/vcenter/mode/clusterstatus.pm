#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::vmware::vsphere8::vcenter::mode::clusterstatus;

use base qw(apps::vmware::vsphere8::vcenter::mode);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_ha_status_output {
    my ($self, %options) = @_;

    my $ha  = ($self->{result_values}->{ha_enabled} eq 'true') ? 'enabled' : 'disabled';
    return "'" . $self->{result_values}->{name} . "' has HA " . $ha;
}

sub custom_drs_status_output {
    my ($self, %options) = @_;

    my $drs = ($self->{result_values}->{drs_enabled} eq 'true') ? 'enabled' : 'disabled';
    return "'" . $self->{result_values}->{name} . "' has DRS " . $drs;
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cluster', type => 1, cb_prefix_output => 'prefix_cluster_output', message_multiple => 'All clusters are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{cluster} = [
        {
            label           => 'ha-status',
            type            => 2,
            warning_default => '%{ha_enabled} ne "true"',
            set             => {
                key_values                     => [ { name => 'name' }, { name => 'cluster' }, { name => 'ha_enabled' } ],
                closure_custom_output          => $self->can('custom_ha_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label           => 'drs-status',
            type            => 2,
            warning_default => '%{drs_enabled} ne "true"',
            set             => {
                key_values                     => [ { name => 'name' }, { name => 'drs_enabled' }, { name => 'cluster' } ],
                closure_custom_output          => $self->can('custom_drs_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self              = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);

    $options{options}->add_options(
        arguments => {
            'include-name:s' => { name => 'include_name', default => '' },
            'exclude-name:s' => { name => 'exclude_name', default => '' }
        }
    );
    $options{options}->add_help(package => __PACKAGE__, sections => 'MODE', once => 1);

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # get the list of clusters response from /api/vcenter/cluster endpoint
    my $response = $self->get_cluster(%options);

    for my $cluster (@{$response}) {

        # exclude cluster if not whitelisted
        if (centreon::plugins::misc::is_excluded($cluster->{name}, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name})) {
            $self->{output}->output_add(long_msg => "skipping excluded cluster '" . $cluster->{name} . "'", debug => 1);
            next;
        }

        # and now we store the information
        $self->{cluster}->{$cluster->{cluster}} = {
            name          => $cluster->{name},
            cluster       => $cluster->{cluster},
            drs_enabled   => $cluster->{drs_enabled},
            ha_enabled    => $cluster->{ha_enabled}
        };
    }
    if (!defined($self->{cluster}) || keys(%{$self->{cluster}}) == 0) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'No clusters found.'
        );
    }
}

1;

__END__

=head1 MODE

Monitor the status of a vSphere cluster through vSphere 8 REST API.

=over 8

=item B<--include-name>

Filter by including only the clusters whose name matches the regular expression provided after this parameter.

Example : C<--include-name='^Prod.*'>

=item B<--exclude-name>

Filter by excluding the clusters whose name matches the regular expression provided after this parameter.

Example : C<--exclude-name='^Sandbox.*'>

=item B<--warning-ha-status>

Define the conditions to match for the status to be WARNING. You can use the following variables: C<%{name}>, C<%{ha_enabled}>,
C<%{cluster}>.
Default: C<%{ha_enabled} ne "true">

=item B<--critical-ha-status>

Define the conditions to match for the status to be CRITICAL. You can use the following variables: C<%{name}>, C<%{ha_enabled}>,
C<%{cluster}>.

=item B<--warning-drs-status>

Define the conditions to match for the status to be WARNING. You can use the following variables: C<%{name}>, C<%{drs_enabled}>,
C<%{cluster}>.
Default: C<%{drs_enabled} ne "true">

=item B<--critical-drs-status>

Define the conditions to match for the status to be CRITICAL. You can use the following variables: C<%{name}>, C<%{drs_enabled}>,
C<%{cluster}>.


=back

=cut
