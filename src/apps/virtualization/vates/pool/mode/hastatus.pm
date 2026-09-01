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

package apps::virtualization::vates::pool::mode::hastatus;
use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::misc qw/is_empty/;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);

sub custom_ha_status_output {
    my ($self, %options) = @_;

    my $ha = ($self->{result_values}->{ha_enabled} eq 'true') ? 'enabled' : 'disabled';
    return "'" . $self->{result_values}->{display} . "' pool has HA " . $ha;
}

sub custom_master_status_output {
    my ($self, %options) = @_;

    return "'" . $self->{result_values}->{display} . "' pool master is '" . $self->{result_values}->{master_name} .
        "' (enabled: " . $self->{result_values}->{master_enabled} . ', power_state: ' . $self->{result_values}->{master_power_state} . ')';
}

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, force_new_perfdata => 1, %options);

    $options{options}->add_options(
        arguments => {
            'pool-uuid:s' => { name => 'pool_uuid', default => '' },
            'pool-name:s' => { name => 'pool_name', default => '' },

        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    if (is_empty($options{option_results}->{pool_uuid}) and is_empty($options{option_results}->{pool_name})) {
        $self->{output}->option_exit(short_msg => "you must fill either --pool-uuid or --pool-name.");
    }

    $self->SUPER::check_options(%options);
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'pool', type => COUNTER_TYPE_GLOBAL, message_separator => ' - ' }
    ];

    $self->{maps_counters}->{pool} = [
        {
            label            => 'cpu-overcommit-prct',
            type             => COUNTER_TYPE_INSTANCE,
            nlabel           => 'pool.cpu.overcommit.percentage',
            warning_default  => '400',
            critical_default => '800',
            set              => {
                key_values      => [ { name => 'cpu_overcommit_prct' }, { name => 'cpu_assigned' }, { name => 'cpu_total' } ],
                output_template => 'CPU overcommit ratio is %.2f %%',
                perfdatas       => [
                    { value => 'cpu_overcommit_prct', template => '%.2f', min => 0, unit => '%' }
                ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    # default filter use uuid, or name if not present.
    my $filter = "uuid:" . $self->{option_results}->{pool_uuid};
    if (is_empty($self->{option_results}->{pool_uuid})) {
        $filter = "name_label:" . $self->{option_results}->{pool_name};
    }
    my $response = $options{custom}->request_api_get(
        endpoint  => "pools",
        get_param => [ "fields=name_label,uuid", "filter=" . $filter ]
    );

    if (!defined($response) or ref($response) ne "ARRAY" or scalar @$response != 1) {
        $self->{output}->option_exit(short_msg => "no pool found, api did not return an array with one element. Please check --pool-uuid and --pool-name parameter or --debug.");
    }
    my $pool = $response->[0];

    my $dashboard = $options{custom}->request_api_get(endpoint => "pools/" . $pool->{uuid} . "/dashboard");
    if (!defined($dashboard->{cpuProvisioning}) or !defined($dashboard->{cpuProvisioning}->{percent})) {
        $self->{output}->option_exit(short_msg => "Field cpuProvisioning not found in API response for pool '" . $pool->{name_label} . "'. Please check --debug or the Swagger documentation.");
    }

    $self->{pool} = {
        display             => $pool->{name_label},
        ha_enabled          => $pool->{HA_enabled},
        cpu_overcommit_prct => $dashboard->{cpuProvisioning}->{percent},
        cpu_assigned        => $dashboard->{cpuProvisioning}->{assigned},
        cpu_total           => $dashboard->{cpuProvisioning}->{total}
    };
}

1;

__END__

=head1 MODE

Check the aggregated status of a Xen Orchestra pool: master host availability, high availability
status and CPU over commit ratio.

Memory over commit and license consistency between hosts are not exposed by the Xen Orchestra REST
API dashboard endpoint at the time of writing, and are therefore not checked by this mode.

=over 8

=item B<--pool-uuid>

Identify the pool by its exact uuid.

=item B<--pool-name>

Identify the pool by its name (only one pool is expected).

=item B<--warning-ha-status>

Define the conditions to match for the HA status to be WARNING. You can use the following variables:
C<%{display}>, C<%{ha_enabled}>.

=item B<--critical-ha-status>

Define the conditions to match for the HA status to be CRITICAL. You can use the following variables:
C<%{display}>, C<%{ha_enabled}>.

=back

=cut
