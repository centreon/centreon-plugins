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

package cloud::azure::database::sqlserver::mode::serverstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("State '%s' [FQDN: %s]",
        $self->{result_values}->{state},
        $self->{result_values}->{fqdn});
    return $msg;
}

sub prefix_server_output {
    my ($self, %options) = @_;
    
    return "Server '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'servers', type => 1, cb_prefix_output => 'prefix_server_output', message_multiple => 'All servers are ok' },
    ];

    $self->{maps_counters}->{servers} = [
        { label => 'status', type => 2, critical_default => '%{state} ne "Ready"', set => {
                key_values => [ { name => 'state' }, { name => 'fqdn' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
        {
            "resource-group:s"      => { name => 'resource_group' },
            "location:s"            => { name => 'location' },
            "filter-name:s"         => { name => 'filter_name' }
        });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{servers} = {};
    my $servers = $options{custom}->azure_list_sqlservers(resource_group => $self->{option_results}->{resource_group});
    foreach my $server (@{$servers}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $server->{name} !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{location}) && $self->{option_results}->{location} ne ''
            && $server->{location} !~ /$self->{option_results}->{location}/);
        
        $self->{servers}->{$server->{id}} = {
            display => $server->{name},
            state => ($server->{state}) ? $server->{state} : $server->{properties}->{state},
            fqdn => ($server->{fullyQualifiedDomainName}) ? $server->{fullyQualifiedDomainName} : $server->{properties}->{fullyQualifiedDomainName},
        };
    }
    
    if (scalar(keys %{$self->{servers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No SQL servers found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check SQL servers status.

Example: 
perl centreon_plugins.pl --plugin=cloud::azure::database::sqlserver::plugin --custommode=azcli --mode=server-status
--resource-group='MYRESOURCEGROUP' --verbose

=over 8

=item B<--resource-group>

Set resource group.

=item B<--location>

Set resource location.

=item B<--filter-name>

Filter server name (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '').
You can use the following variables: %{state}, %{fqdn}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{state} ne "Ready"').
You can use the following variables: %{state}, %{fqdn}, %{display}

=back

=cut