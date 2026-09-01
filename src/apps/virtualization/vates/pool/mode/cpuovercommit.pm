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

package apps::virtualization::vates::pool::mode::cpuovercommit;
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

    return "pool '" . $self->{result_values}->{display} . "' master is '" . $self->{result_values}->{master_name} .
       "', power_state: " . $self->{result_values}->{master_power_state}  .
       ", enabled: " . $self->{result_values}->{master_enabled} ;
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
            warning_default  => '90',
            critical_default => '100',
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
    my $pool = $options{custom}->get_name_and_uuid(type => "pool", "api_endpoint"=> "pools");

    my $dashboard = $options{custom}->request_api_get(
        endpoint  => "pools/" . $pool->{uuid} . "/dashboard"
    );
    if (!defined($dashboard) or !defined($dashboard->{cpuProvisioning}) or ref($dashboard->{cpuProvisioning}) ne "HASH") {
        $self->{output}->option_exit(short_msg => "unable to retrieve the performance data of pool '" . $pool->{name_label} . "'.");
    }

    $self->{pool} = {
        display             => $pool->{name_label},
        cpu_overcommit_prct => $dashboard->{cpuProvisioning}->{percent},
        cpu_assigned        => $dashboard->{cpuProvisioning}->{assigned},
        cpu_total           => $dashboard->{cpuProvisioning}->{total},
    };
}

1;

__END__

=head1 MODE

Check the CPU over commit ratio of a Xen Orchestra pool (vCPUs assigned vs. physical CPUs).

=over 8

=item B<--pool-uuid>

Identify the pool by its exact uuid.

=item B<--pool-name>

Identify the pool by its name (only one pool is expected).

=item B<--warning-cpu-overcommit-prct>

Threshold warning for the CPU over commit ratio, in percentage.
Note that this metric can go over 100%.
100% mean the sum of CPU assigned to virtual machines is equal to the physical number of CPU in the pool
Default: 90

=item B<--critical-cpu-overcommit-prct>

Threshold critical for the CPU over commit ratio, in percentage.
Note that this metric can go over 100%.
100% mean the sum of CPU assigned to virtual machines is equal to the physical number of CPU in the pool
Default: 100

=back

=cut
