#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package cloud::azure::network::virtualnetwork::mode::listvirtualnetworks;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                    "resource-group:s"      => { name => 'resource_group' },
                                    "location:s"            => { name => 'location' },
                                    "filter-name:s"         => { name => 'filter_name' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{networks} = $options{custom}->azure_list_virtualnetworks(
        resource_group => $self->{option_results}->{resource_group}
    );
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $network (@{$self->{networks}}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $network->{name} !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{location}) && $self->{option_results}->{location} ne ''
            && $network->{location} !~ /$self->{option_results}->{location}/);
        my $resource_group = '-';
        $resource_group = $network->{resourceGroup} if (defined($network->{resourceGroup}));
        $resource_group = $1 if ($resource_group eq '-' && defined($network->{id}) && $network->{id} =~ /resourceGroups\/(.*)\/providers/);
        
        my @tags;
        foreach my $tag (keys %{$network->{tags}}) {
            push @tags, $tag . ':' . $network->{tags}->{$tag};
        }
        
        $self->{output}->output_add(long_msg => sprintf("[name = %s][resourcegroup = %s][location = %s][id = %s][address_space = %s][tags = %s]",
            $network->{name},
            $resource_group,
            $network->{location},
            $network->{id},
            ($network->{addressSpace}->{addressPrefixes}) ? join(',', @{$network->{addressSpace}->{addressPrefixes}}) : join(',', @{$network->{properties}->{addressSpace}->{addressPrefixes}}),
            join(',', @tags),
        ));
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List virtual networks:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'resourcegroup', 'location', 'id', 'address_space', 'tags']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $network (@{$self->{networks}}) {
        my $resource_group = '-';
        $resource_group = $network->{resourceGroup} if (defined($network->{resourceGroup}));
        $resource_group = $1 if ($resource_group eq '-' && defined($network->{id}) && $network->{id} =~ /resourceGroups\/(.*)\/providers/);
        
        my @tags;
        foreach my $tag (keys %{$network->{tags}}) {
            push @tags, $tag . ':' . $network->{tags}->{$tag};
        }

        $self->{output}->add_disco_entry(
            name => $network->{name},
            resourcegroup => $resource_group,
            location => $network->{location},
            id => $network->{id},
            address_space => ($network->{addressSpace}->{addressPrefixes}) ? join(',', @{$network->{addressSpace}->{addressPrefixes}}) : join(',', @{$network->{properties}->{addressSpace}->{addressPrefixes}}),
            tags => join(',', @tags),
        );
    }
}

1;

__END__

=head1 MODE

List virtual networks.

=over 8

=item B<--resource-group>

Set resource group.

=item B<--location>

Set resource location.

=item B<--filter-name>

Filter resource name (Can be a regexp).

=back

=cut
