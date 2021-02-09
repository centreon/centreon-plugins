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

package cloud::azure::network::publicip::mode::status;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

use strict;
use warnings;


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'resource:s'       => { name => 'resource' },
        'resource-group:s' => { name => 'resource_group' }
    });

    $options{options}->add_help(package => __PACKAGE__, sections => 'CUSTOM MODE OPTIONS', once => 1);

    return $self;
}


sub prefix_status_output {
    my ($self, %options) = @_;

    return sprintf("Public IP instance '%s', IP: %s (%s) ", $options{instance_value}->{display}, $options{instance_value}->{ipaddress}, $options{instance_value}->{ipversion});
}

sub custom_ddos_status_output {
    my ($self, %options) = @_;

    return sprintf('current DDOS status: "%s"',  $self->{result_values}->{status});
}

sub custom_provisioning_state_output {
    my ($self, %options) = @_;

    return sprintf('current provisioning state: "%s"',  $self->{result_values}->{state});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_status_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'ddos-status', type => 2, critical_default => '%{status} =~ /DDOS Attack ongoing/i', set => {
                key_values => [ { name => 'status' } ],
                closure_custom_output => $self->can('custom_ddos_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        },
        { label => 'provisioning-state', type => 2, critical_default => '%{state} =~ /Failed/i', set => {
                key_values => [ { name => 'state' } ],
                closure_custom_output => $self->can('custom_provisioning_state_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        }
    ];
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{resource}) || $self->{option_results}->{resource} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify either --resource <name> with --resource-group option or --resource <id>.');
        $self->{output}->option_exit();
    }
    my $resource = $self->{option_results}->{resource};
    my $resource_group = defined($self->{option_results}->{resource_group}) ? $self->{option_results}->{resource_group} : '';
    if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.Network\/publicIPAddresses\/(.*)$/) {
        $resource_group = $1;
        $resource = $2;
    }

    $self->{az_resource} = $resource;
    $self->{az_resource_group} = $resource_group;
    $self->{az_resource_type} = 'publicIPAddresses';
    $self->{az_resource_namespace} = 'Microsoft.Network';
    $self->{az_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{az_interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : 'PT5M';
    $self->{az_aggregations} = ['Maximum'];

}

sub manage_selection {
    my ($self, %options) = @_;

    my %metric_results;
    my $raw_results;

    my $publicip_properties = $options{custom}->azure_get_publicip(resource => $self->{az_resource}, resource_group => $self->{az_resource_group});
    $self->{global} = {
        ipaddress => $publicip_properties->{properties}->{ipAddress},
        ipversion => $publicip_properties->{properties}->{publicIPAddressVersion},
        state => $publicip_properties->{properties}->{provisioningState}
    };

    ($metric_results{$self->{az_resource}}, $raw_results) = $options{custom}->azure_get_metrics(
        aggregations       => $self->{az_aggregations},
        interval           => $self->{az_interval},
        metrics            => ['IfUnderDDoSAttack'],
        resource           => $self->{az_resource},
        resource_group     => $self->{az_resource_group},
        resource_namespace => $self->{az_resource_namespace},
        resource_type      => $self->{az_resource_type},
        timeframe          => $self->{az_timeframe}
    );

    $self->{global}->{display} = $self->{az_resource};
    $self->{global}->{numeric_status} =
        defined($metric_results{$self->{az_resource}}->{IfUnderDDoSAttack}->{maximum}) ?
        $metric_results{$self->{az_resource}}->{IfUnderDDoSAttack}->{maximum} : 0;


    $self->{global}->{status} = $self->{global}->{numeric_status} > 0 ? 'DDOS Attack ongoing' : 'OK';

}

1;

__END__

=head1 MODE

Check Azure Public IP status.

Example:

Using resource name :

perl centreon_plugins.pl --plugin=cloud::azure::network::publicip::plugin --mode=status --custommode=api
--resource=<publicip_id> --resource-group=<resourcegroup_id>
--critical-provisioning-state='%{state} =~ /Failed/i'

Using resource id :

perl centreon_plugins.pl --plugin=cloud::azure::network::publicip::plugin --mode=status --custommode=api
--resource='/subscriptions/<subscription_id>/resourceGroups/<resourcegroup_id>/providers/Microsoft.Network/publicIPAddresses/<publicip_id>'
--critical-provisioning-state='%{state} =~ /Failed/i'

Default aggregation: 'maximum' / 'average', 'total', 'minimum' and 'maximum' are valid.

=head1 CUSTOM MODE OPTIONS

=over 8

=item B<--resource>

Set resource name or id (Required).

=item B<--resource-group>

Set resource group (Required if resource's name is used).

=item B<--warning-ddos-status>

Warning threshold for DDOS attack status (Default: '').

=item B<--critical-ddos-status>

Critical threshold for DDOS attack status (Default: '%{status} =~ /DDOS Attack ongoing/i').

=item B<--warning-provisioning-state>

Warning threshold for provisioning state (Default: '').

=item B<--critical-provisioning-state>

Critical threshold for provisioning state (Default: '%{state} =~ /Failed/i').

=back

=cut
