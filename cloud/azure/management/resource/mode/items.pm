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

package cloud::azure::management::resource::mode::items;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_group_output {
    my ($self, %options) = @_;
    
    return "Resource group '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'groups', type => 1, cb_prefix_output => 'prefix_group_output', message_multiple => 'All groups are ok' },
    ];
    
    $self->{maps_counters}->{groups} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' } , { name => 'display' }  ],
                output_template => "Total number of items : %s",
                perfdatas => [
                    { label => 'total', value => 'total', template => '%d',
                      label_extra_instance => 1, instance_use => 'display', min => 0 },
                ],
            }
        },
        { label => 'compute', set => {
                key_values => [ { name => 'compute' } , { name => 'display' }  ],
                output_template => "Compute: %s",
                perfdatas => [
                    { label => 'compute', value => 'compute', template => '%d',
                      label_extra_instance => 1, instance_use => 'display', min => 0 },
                ],
            }
        },
        { label => 'storage', set => {
                key_values => [ { name => 'storage' } , { name => 'display' }  ],
                output_template => "Storage: %s",
                perfdatas => [
                    { label => 'storage', value => 'storage', template => '%d',
                      label_extra_instance => 1, instance_use => 'display', min => 0 },
                ],
            }
        },
        { label => 'network', set => {
                key_values => [ { name => 'network' } , { name => 'display' }  ],
                output_template => "Network: %s",
                perfdatas => [
                    { label => 'network', value => 'network', template => '%d',
                      label_extra_instance => 1, instance_use => 'display', min => 0 },
                ],
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
                                    "filter-name:s"         => { name => 'filter_name' },
                                    "hidden"                => { name => 'hidden' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $resources = $options{custom}->azure_list_resources(
        namespace => '',
        resource_type => '',
        location => $self->{option_results}->{location},
        resource_group => $self->{option_results}->{resource_group}
    );

    my $groups;
    if (defined($self->{option_results}->{resource_group}) && $self->{option_results}->{resource_group} ne '') {
        push @{$groups}, { name => $self->{option_results}->{resource_group} };
    } else {
        $groups = $options{custom}->azure_list_groups();
    }

    foreach my $group (@{$groups}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $group->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $group->{name} . "': no matching filter.", debug => 1);
            next;
        }
            
        $self->{groups}->{$group->{name}} = {
            display => $group->{name},
            total => 0,
            compute => 0,
            storage => 0,
            network => 0,
        };

        foreach my $item (@{$resources}) {
            my $resource_group = '';
            $resource_group = $item->{resourceGroup} if (defined($item->{resourceGroup}));
            $resource_group = $1 if (defined($item->{id}) && $item->{id} =~ /resourceGroups\/(.*)\/providers/);
            next if (defined($resource_group) && $resource_group !~ /$group->{name}/);
            next if (!defined($self->{option_results}->{hidden}) && $item->{type} =~ /^Microsoft\..*\/.*\/.*/);
            $self->{groups}->{$group->{name}}->{total}++;
            $self->{groups}->{$group->{name}}->{compute}++ if ($item->{type} =~ /^Microsoft\.Compute\//);
            $self->{groups}->{$group->{name}}->{storage}++ if ($item->{type} =~ /^Microsoft\.Storage\//);
            $self->{groups}->{$group->{name}}->{network}++ if ($item->{type} =~ /^Microsoft\.Network\//);
        }
    }
    
    if (scalar(keys %{$self->{groups}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No groups found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check number of items in resource groups.

Example: 
perl centreon_plugins.pl --plugin=cloud::azure::management::resource::plugin --custommode=azcli --mode=items
--filter-name='.*' --critical-items='10' --verbose

=over 8

=item B<--resource-group>

Set resource group (Optional).

=item B<--filter-name>

Filter resource name (Can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'total', 'compute', 'storage', 'network'.

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'compute', 'storage', 'network'.

=back

=cut
