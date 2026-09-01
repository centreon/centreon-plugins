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

package apps::virtualization::vates::pool::mode::status;
use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::misc qw/is_empty/;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);

sub custom_ha_status_output {
    my ($self, %options) = @_;

    my $ha = ($self->{result_values}->{ha_enabled} eq 'true') ? 'enabled' : 'disabled';
    return "pool has HA " . $ha;
}

sub custom_master_status_output {
    my ($self, %options) = @_;

    return sprintf("pool '%s' master '%s' is %s",
         $self->{result_values}->{display},
        $self->{result_values}->{master_name},
        $self->{result_values}->{master_power_state},
    );
}

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, force_new_perfdata => 1, %options);

    $options{options}->add_options(
        arguments => {
            'pool-uuid:s' => { name => 'pool_uuid', default => '' },
            'pool-name:s' => { name => 'pool_name', default => '' },
            'is-ha:s' => { name => 'is_ha', default => '' }

        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    if (is_empty($options{option_results}->{pool_uuid}) and is_empty($options{option_results}->{pool_name})) {
        $self->{output}->option_exit(short_msg => "you must fill either --pool-uuid or --pool-name.");
    }
    if (!is_empty($options{option_results}->{is_ha})) {
        if ($options{option_results}->{is_ha} eq "true" or $options{option_results}->{is_ha} eq '1')  {
            $options{option_results}->{'critical-ha-status'} = '%{ha_enabled} !~ /^true/i'
        } else {
            $options{option_results}->{'critical-ha-status'} = ''
        }
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
            label            => 'master-status',
            type             => COUNTER_TYPE_GROUP,
            critical_default => '%{master_power_state} !~ /^Running/i',
            set              => {
                key_values                     => [
                    { name => 'display' }, { name => 'master_name' },
                    { name => 'master_power_state' }
                ],
                closure_custom_output          => $self->can('custom_master_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label            => 'ha-status',
            type             => COUNTER_TYPE_GROUP,
            critical_default => '%{ha_enabled} !~ /^true/i',

            set              => {
                key_values                     => [ { name => 'ha_enabled' } ],
                closure_custom_output          => $self->can('custom_ha_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
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
        get_param => [ "fields=name_label,uuid,master,HA_enabled", "filter=" . $filter ]
    );
    if (!defined($response) or ref($response) ne "ARRAY" or scalar @$response != 1) {
        $self->{output}->option_exit(short_msg => "no pool found, api did not return an array with one element. Please check --pool-uuid and --pool-name parameter or --debug.");
    }
    my $pool = $response->[0];

    my $master = $options{custom}->request_api_get(
        endpoint  => "hosts/",
                get_param => [ "fields=name_label,uuid,power_state", "filter=uuid" .  $pool->{master} ]

    );
    if (!defined($master) or ref($master) ne "ARRAY" or scalar @$response != 1) {
        $self->{output}->option_exit(short_msg => "no host found, api did not return an array with one element. Please check --pool-uuid and --pool-name parameter or --debug.");
    }
    $master = $master->[0];
    if (!defined($master) or !defined($master->{name_label})) {
        $self->{output}->option_exit(short_msg => "unable to retrieve the master host '" . $pool->{master} . "' of pool '" . $pool->{name_label} . "'.");
    }



    $self->{pool} = {
        display             => $pool->{name_label},
        ha_enabled          => $pool->{HA_enabled},
        master_name         => $master->{name_label},
        master_power_state  => $master->{power_state},
    };
}

1;

__END__

=head1 MODE

Check the status of a Vates Xen Orchestra pool: master host availability, power state and High Availability if configured

=over 8

=item B<--pool-uuid>

Identify the pool by its exact uuid.

=item B<--pool-name>

Identify the pool by its name (only one pool is expected).

=item B<--warning-master-status>

Define the conditions to match for the master host status to be WARNING. You can use the following
variables: C<%{display}>, C<%{master_name}>, C<%{master_power_state}>.

=item B<--critical-master-status>

Define the conditions to match for the master host status to be CRITICAL. You can use the following
variables: C<%{display}>, C<%{master_name}>, C<%{master_power_state}>.
Default: C<%{master_enabled} ne "true" or %{master_power_state} !~ /^Running/i>

=back

=cut
