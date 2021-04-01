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

package cloud::azure::database::sqldatabase::mode::listdatabases;

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
                                    "server:s"              => { name => 'server' },
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

    if (!defined($self->{option_results}->{server}) || $self->{option_results}->{server} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --server option");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{databases} = $options{custom}->azure_list_sqldatabases(
        resource_group => $self->{option_results}->{resource_group},
        server => $self->{option_results}->{server}
    );
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $database (@{$self->{databases}}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $database->{name} !~ /$self->{option_results}->{filter_name}/);
        my $resource_group = '-';
        $resource_group = $database->{resourceGroup} if (defined($database->{resourceGroup}));
        $resource_group = $1 if ($resource_group eq '-' && defined($database->{id}) && $database->{id} =~ /resourceGroups\/(.*)\/providers/);
        
        my @tags;
        foreach my $tag (keys %{$database->{tags}}) {
            push @tags, $tag . ':' . $database->{tags}->{$tag};
        }

        $self->{output}->output_add(long_msg => sprintf("[name = %s][kind = %s][resourcegroup = %s][location = %s][id = %s][tags = %s]",
            $database->{name},
            ($database->{kind}) ? $database->{kind} : $database->{properties}->{kind},
            $resource_group,
            $database->{location},
            $database->{id},
            join(',', @tags),
        ));
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List SQL databases:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'kind', 'resourcegroup', 'location', 'id', 'tags']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $database (@{$self->{databases}}) {
        my $resource_group = '-';
        $resource_group = $database->{resourceGroup} if (defined($database->{resourceGroup}));
        $resource_group = $1 if ($resource_group eq '-' && defined($database->{id}) && $database->{id} =~ /resourceGroups\/(.*)\/providers/);
        
        my @tags;
        foreach my $tag (keys %{$database->{tags}}) {
            push @tags, $tag . ':' . $database->{tags}->{$tag};
        }

        $self->{output}->add_disco_entry(
            name => $database->{name},
            kind => ($database->{kind}) ? $database->{kind} : $database->{properties}->{kind},
            resourcegroup => $resource_group,
            location => $database->{location},
            id => $database->{id},
            tags => join(',', @tags),
        );
    }
}

1;

__END__

=head1 MODE

List SQL databases.

=over 8

=item B<--resource-group>

Set resource group (Required).

=item B<--resource-group>

Set SQL erver (Required).

=item B<--filter-name>

Filter resource name (Can be a regexp).

=back

=cut
