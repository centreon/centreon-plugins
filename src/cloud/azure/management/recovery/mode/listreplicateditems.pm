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

package cloud::azure::management::recovery::mode::listreplicateditems;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                    "vault-name:s"          => { name => 'vault_name' },
                                    "resource-group:s"      => { name => 'resource_group' },
                                    "filter-name:s"         => { name => 'filter_name' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

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

    $self->{replicated_items} = $options{custom}->azure_list_replication_protected_items(
        vault_name => $self->{option_results}->{vault_name},
        resource_group => $self->{option_results}->{resource_group}
    );
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $replicated_item (@{$self->{replicated_items}->{value}}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $replicated_item->{properties}->{friendlyName} !~ /$self->{option_results}->{filter_name}/);
        my $resource_group = '-';
        $resource_group = $replicated_item->{resourceGroup} if (defined($replicated_item->{resourceGroup}));
        $resource_group = $1 if ($resource_group eq '-' && defined($replicated_item->{id}) && $replicated_item->{id} =~ /resource[gG]roups\/(.*)\/providers/);
        
        my @tags;
        foreach my $tag (keys %{$replicated_item->{tags}}) {
            push @tags, $tag . ':' . $replicated_item->{tags}->{$tag};
        }

        $self->{output}->output_add(long_msg => sprintf("[name = %s][resourcegroup = %s][id = %s][replication_health = %s][failover_health = %s]",
            $replicated_item->{properties}->{friendlyName},
            $resource_group,
            $replicated_item->{id},
            $replicated_item->{properties}->{replicationHealth},
            $replicated_item->{properties}->{failoverHealth},
            join(',', @tags))
        );
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List replicated items:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'resourcegroup', 'id', 'replication_health', 'failover_health']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $replicated_item (@{$self->{replicated_items}->{value}}) {
        my $resource_group = '-';
        $resource_group = $replicated_item->{resourceGroup} if (defined($replicated_item->{resourceGroup}));
        $resource_group = $1 if ($resource_group eq '-' && defined($replicated_item->{id}) && $replicated_item->{id} =~ /resourceGroups\/(.*)\/providers/);

        my @tags;
        foreach my $tag (keys %{$replicated_item->{tags}}) {
            push @tags, $tag . ':' . $replicated_item->{tags}->{$tag};
        }

        $self->{output}->add_disco_entry(
            name => $replicated_item->{properties}->{FriendlyName},
            resourcegroup => $resource_group,
            id => $replicated_item->{id},
            replication_health => $replicated_item->{properties}->{replicationHealth},
            failover_health => $replicated_item->{properties}->{failoverHealth},
            tags => join(',', @tags)
        );
    }
}

1;

__END__

=head1 MODE

List replicated items.

=over 8

=item B<--vault-name>

Set vault name (mandatory).

=item B<--resource-group>

Set resource group (mandatory).

=item B<--filter-name>

Filter on item name (can be a regexp).

=back

=cut
