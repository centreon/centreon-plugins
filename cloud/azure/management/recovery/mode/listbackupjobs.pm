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

package cloud::azure::management::recovery::mode::listbackupjobs;

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

    $self->{jobs} = $options{custom}->azure_list_backup_jobs(
        vault_name => $self->{option_results}->{vault_name},
        resource_group => $self->{option_results}->{resource_group}
    );
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $job (@{$self->{jobs}}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $job->{properties}->{entityFriendlyName} !~ /$self->{option_results}->{filter_name}/);
        my $resource_group = '-';
        $resource_group = $job->{resourceGroup} if (defined($job->{resourceGroup}));
        $resource_group = $1 if ($resource_group eq '-' && defined($job->{id}) && $job->{id} =~ /resource[gG]roups\/(.*)\/providers/);
        
        my @tags;
        foreach my $tag (keys %{$job->{tags}}) {
            push @tags, $tag . ':' . $job->{tags}->{$tag};
        }

        $self->{output}->output_add(long_msg => sprintf("[name = %s][resourcegroup = %s][id = %s][activity_id = %s][type = %s][status = %s][tags = %s]",
            $job->{properties}->{entityFriendlyName},
            $resource_group,
            $job->{id},
            $job->{properties}->{activityId},
            $job->{properties}->{jobType},
            $job->{properties}->{status},
            join(',', @tags))
        );
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List backup jobs:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'resourcegroup', 'id', 'activity_id', 'type', 'status', 'tags']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $job (@{$self->{jobs}}) {
        my $resource_group = '-';
        $resource_group = $job->{resourceGroup} if (defined($job->{resourceGroup}));
        $resource_group = $1 if ($resource_group eq '-' && defined($job->{id}) && $job->{id} =~ /resourceGroups\/(.*)\/providers/);

        my @tags;
        foreach my $tag (keys %{$job->{tags}}) {
            push @tags, $tag . ':' . $job->{tags}->{$tag};
        }

        $self->{output}->add_disco_entry(
            name => $job->{properties}->{entityFriendlyName},
            resourcegroup => $resource_group,
            id => $job->{id},
            activity_id => $job->{properties}->{activityId},
            type => $job->{properties}->{jobType},
            status => $job->{properties}->{status},
            tags => join(',', @tags),
        );
    }
}

1;

__END__

=head1 MODE

List backup jobs.

=over 8

=item B<--vault-name>

Set vault name (Mandatory).

=item B<--resource-group>

Set resource group (Mandatory).

=item B<--filter-name>

Filter job name (Can be a regexp).

=back

=cut
