#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package cloud::azure::netapp::pool::mode::listvolumes;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc qw/is_excluded/;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(
        arguments =>
            {
                "resource-group:s" => { name => 'resource_group' },
                "account-name:s"   => { name => 'account_name' },
                "pool-name:s"      => { name => 'pool_name' },
                "include-volume:s" => { name => 'include_name' },
                "exclude-volume:s" => { name => 'exclude_name' },
            }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{resource_group}) || $self->{option_results}->{resource_group} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --resource-group option");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{account_name}) || $self->{option_results}->{account_name} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --filter-account-name option");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{pool_name}) || $self->{option_results}->{pool_name} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --filter-pool-name option");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{volumes} = $options{custom}->azure_list_netapp_volumes(
        resource_group => $self->{option_results}->{resource_group},
        account_name   => $self->{option_results}->{account_name},
        pool_name      => $self->{option_results}->{pool_name},
    );
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (sort {$a->{name} cmp $b->{name}} @{$self->{volumes}}) {
        my $volume = $_;
        next if is_excluded($volume->{name} // '',
            $self->{option_results}->{include_name},
            $self->{option_results}->{exclude_name},
            output =>
                $self->{output});

        my $resource_group = '-';
        $resource_group = $volume->{resourceGroup} if (defined($volume->{resourceGroup}));
        $resource_group = $1 if ($resource_group eq '-' && defined($volume->{id}) && $volume->{id} =~ /resourceGroups\/(.*)\/providers/);

        $self->{output}->output_add(
            long_msg =>
                sprintf("[name = %s][resourcegroup = %s][location = %s][id = %s][type = %s] [storage_to_network_proximity = %s] [service_level = %s]",
                    $volume->{name},
                    $resource_group,
                    $volume->{location},
                    $volume->{id},
                    $volume->{type},
                    $volume->{storage_to_network_proximity},
                    $volume->{service_level},
                    $volume->{through_put_mibps}
                )
        );
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => 'List NetApp volume:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(
        elements => [
            'name',
            'resourcegroup',
            'location',
            'id',
            'type',
            'storage_to_network_proximity',
            'service_level'
        ]
    );
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (sort {$a->{name} cmp $b->{name}} @{$self->{volumes}}) {
        my $volume = $_;
        my $resource_group = '-';
        $resource_group = $volume->{resourceGroup} if (defined($volume->{resourceGroup}));
        $resource_group = $1 if ($resource_group eq '-' && defined($volume->{id}) && $volume->{id} =~ /resourceGroups\/(.*)\/providers/);

        $self->{output}->add_disco_entry(
            name                         => $volume->{name},
            resourcegroup                => $resource_group,
            location                     => $volume->{location},
            id                           => $volume->{id},
            type                         => $volume->{type},
            storage_to_network_proximity => $volume->{properties}->{storageToNetworkProximity},
            service_level                => $volume->{properties}->{serviceLevel},
        );
    }
}

1;

__END__

=head1 MODE

List NetApp pool volumes.
(https://learn.microsoft.com/en-us/rest/api/netapp/volumes/list?view=rest-netapp-2025-12-01&tabs=HTTP)

=over 8

=item B<--resource-group>

Set resource group.

=item B<--location>

Set resource location.

=item B<--account-name>

Filter resource by NetApp account name.

=item B<--pool-name>

Filter resource by NetApp account pool name.

=item B<--include-volume>

Filter resource by NetApp account name (can be a regexp).

=item B<--exclude-volume>

Exclude resource by NetApp account name (can be a regexp).

=back

=cut
