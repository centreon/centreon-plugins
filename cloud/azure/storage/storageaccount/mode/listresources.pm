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

package cloud::azure::storage::storageaccount::mode::listresources;

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

    $self->{resources} = $options{custom}->azure_list_resources(
        namespace => 'Microsoft.Storage',
        resource_type => 'storageAccounts',
        location => $self->{option_results}->{location},
        resource_group => $self->{option_results}->{resource_group}
    );
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $resource (@{$self->{resources}}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $resource->{name} !~ /$self->{option_results}->{filter_name}/);
        my $resource_group = '-';
        $resource_group = $resource->{resourceGroup} if (defined($resource->{resourceGroup}));
        $resource_group = $1 if (defined($resource->{id}) && $resource->{id} =~ /resourceGroups\/(.*)\/providers/);
        
        my @tags;
        foreach my $tag (keys %{$resource->{tags}}) {
            push @tags, $tag . ':' . $resource->{tags}->{$tag};
        }

        $self->{output}->output_add(long_msg => sprintf("[name = %s][resourcegroup = %s][location = %s][id = %s][tags = %s]",
            $resource->{name},
            $resource_group,
            $resource->{location},
            $resource->{id},
            join(',', @tags),
        ));
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List storage accounts:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'resourcegroup', 'location', 'id', 'tags']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $resource (@{$self->{resources}}) {
        my $resource_group = '-';
        $resource_group = $resource->{resourceGroup} if (defined($resource->{resourceGroup}));
        $resource_group = $1 if (defined($resource->{id}) && $resource->{id} =~ /resourceGroups\/(.*)\/providers/);
        
        my @tags;
        foreach my $tag (keys %{$resource->{tags}}) {
            push @tags, $tag . ':' . $resource->{tags}->{$tag};
        }

        $self->{output}->add_disco_entry(
            name => $resource->{name},
            resourcegroup => $resource_group,
            location => $resource->{location},
            id => $resource->{id},
            tags => join(',', @tags),
        );
    }
}

1;

__END__

=head1 MODE

List storage account resources.

=over 8

=item B<--resource-group>

Set resource group.

=item B<--location>

Set resource location.

=item B<--filter-name>

Filter resource name (Can be a regexp).

=back

=cut
