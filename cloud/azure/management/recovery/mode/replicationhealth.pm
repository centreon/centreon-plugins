#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package cloud::azure::management::recovery::mode::replicationhealth;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_replication_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Replication status '%s'", $self->{result_values}->{replication_status});
    return $msg;
}

sub custom_failover_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Failover status '%s'", $self->{result_values}->{failover_status});
    return $msg;
}

sub prefix_replication_item_output {
    my ($self, %options) = @_;
    
    return "Replication item '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'items', type => 1, cb_prefix_output => 'prefix_replication_item_output', message_multiple => 'All replication items are OK' }
    ];

    $self->{maps_counters}->{items} = [
        { label => 'replication-status', critical_default => '%{replication_status} eq "Critical"', type => 2, set => {
                key_values => [ { name => 'replication_status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_replication_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'failover-status', critical_default => '%{failover_status} eq "Critical"', type => 2, set => {
                key_values => [ { name => 'failover_status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_failover_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                    "api-version:s"         => { name => 'api_version', default => '2021-08-01'},
                                    "vault-name:s"          => { name => 'vault_name' },
                                    "resource-group:s"      => { name => 'resource_group' },
                                    "filter-name:s"         => { name => 'filter_name' },
                                    "filter-counters:s"     => { name => 'filter_counters' }
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{resource_group}) || $self->{option_results}->{resource_group} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --resource-group option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{vault_name}) || $self->{option_results}->{vault_name} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --vault-name option");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};
    my $replicated_items = $options{custom}->azure_list_replication_protected_items(
        vault_name => $self->{option_results}->{vault_name},
        resource_group => $self->{option_results}->{resource_group}
    );
    
    # use Data::Dumper;
    # print Dumper $replicated_items;

    foreach my $replicated_item (@{$replicated_items->{value}}) {

        $self->{items}->{$replicated_item->{properties}->{friendlyName}} = {
            display => $replicated_item->{properties}->{friendlyName},
            replication_status => $replicated_item->{properties}->{replicationHealth},
            failover_status => $replicated_item->{properties}->{failoverHealth}
        };
    }
    
    # if (scalar(keys %{$self->{items}}) <= 0) {
    #     $self->{output}->add_option_msg(short_msg => "No replication site found.");
    #     $self->{output}->option_exit();
    # }
}

1;

__END__

=head1 MODE

Check replication site health status. 

=over 8

=item B<--vault-name>

Set vault name (Required).

=item B<--resource-group>

Set resource group (Required).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} eq "Failed"').
Can used special variables like: %{status}

=back

=cut
