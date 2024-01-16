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

package cloud::azure::management::costs::mode::tagscompliance;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_vm_output {
    my ($self, %options) = @_;

    return "Virtual Machines";
}

sub custom_compliance_output {
    my ($self, %options) = @_;

    my $msg = sprintf(" not having specified tags %s (out of %s)", $self->{result_values}->{count}, $self->{result_values}->{total});
    
    return $msg;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'skip_vm'        => { name => 'skip_vm' },
        'tags:s@'        => { name => 'tags' },
        'exclude-name:s' => { name => 'exclude_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{tags}) || $self->{option_results}->{tags} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --tags option");
        $self->{output}->option_exit();
    }

    foreach my $tag_pair (@{$self->{option_results}->{tags}}) {
        my ($key, $value) = split / => /, $tag_pair;
        centreon::plugins::misc::trim($value) if defined($value);
        if (!exists($self->{tags}->{ centreon::plugins::misc::trim($key) })) {
            $self->{tags}->{ centreon::plugins::misc::trim($key) } = $value;
        } else {
            $self->{output}->add_option_msg(short_msg => "Using multiple --tags option with the same key is forbiden. Please use regexp on the value instead");
            $self->{output}->option_exit();            
        }
        
    }
}

sub set_counters { 
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'uncompliant_resource', type => 0 },
        { name => 'uncompliant_vms', type => 0 },
    ];

    $self->{maps_counters}->{uncompliant_resource} = [
        { label => 'uncompliant-resource', nlabel => 'azure.tags.resource.notcompliant.count', set => {
                key_values => [ { name => 'count' }, { name => 'total' } ],
                output_template => 'Uncompliant resources: %s',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{uncompliant_vms} = [
        { label => 'uncompliant-vms', display_ok => 0, nlabel => 'azure.tags.vm.notcompliant.count', set => {
                key_values => [ { name => 'count' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_compliance_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my @item_list;
    $self->{uncompliant_resource}->{count} = 0;
    $self->{uncompliant_resource}->{total} = 0;
    
    if (!defined($self->{option_results}->{skip_vm})) {
        $self->{uncompliant_vms}->{count} = 0;
        $self->{uncompliant_vms}->{total} = 0;
        my $items = $options{custom}->azure_list_vms(
            resource_group => $self->{option_results}->{resource_group},
            force_api_version => "2022-08-01"
        );

        foreach my $item (@{$items}) {
            next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
                 && $item->{name} =~ /$self->{option_results}->{exclude_name}/);
            $self->{uncompliant_vms}->{total}++;
            $self->{uncompliant_resource}->{total}++;

            my $matched = "0";            
            foreach my $lookup_key (keys %{ $self->{tags} }) {
                foreach my $vm_key (keys %{ $item->{tags} }) {
                    if (defined($self->{tags}->{$lookup_key}) && defined($item->{tags}->{$vm_key})) {
                        $matched++ if ($item->{tags}->{$vm_key} =~ /$self->{tags}->{$lookup_key}/);
                    }
                    if (!defined($self->{tags}->{$lookup_key})) {
                        $matched++ if ($vm_key eq $lookup_key);
                    }                  
                }
            }
            if (scalar keys %{ $self->{tags} } != $matched) {
                $self->{uncompliant_vms}->{count}++;
                $self->{uncompliant_resource}->{count}++;
                push @item_list, $item->{name};
            }
        }

        if (scalar @item_list != 0) {
            $self->{output}->output_add(long_msg => "Virtual Machines with uncompliant tags:" . "[" . join(", ", @item_list) . "]");
        }
        @item_list = ();
    }

}

1;

__END__

=head1 MODE

Check if a specified tag is present on your Azure resources. 

At the moment, only VMs are supported, but support will extend to other resource type in the future.

Example: 
perl centreon_plugins.pl --plugin=cloud::azure::management::costs::plugin --custommode=api --mode=tag-on-resources
{--resource-group='MYRESOURCEGROUP'] --exclude-name='MyVM1|MyVM2.*'  --tag-name='atagname' --tag-name='atagname => atagvalue' --api-version='2022-08-01'

Adding --verbose will display the item names.

=over 8

=item B<--resource-group>

Set resource group (optional).

=item B<--exclude-name>

Exclude resource from check (can be a regexp).

=item B<--skip-vm>

Skip virtual machines (don't use it until other resource type are supported)

=item B<--tags>

Can be multiple. Allow you to specify tags that should be present. All tags must match a resource's configuration
to make it a compliant one.

What you cannot do: 

- specifying the same key in different options: --tags='Environment => Prod' --tags='Environment => Dev'

What you can do: 
- check for multiple value for a single key: --tags='Environment => Dev|Prod'
- check for a key, without minding about its value: --tags='Version'
- combine the two: --tags='Environment => Dev|Prod' --tags='Version'

=item B<--warning-*>

Warning threshold. '*' replacement values accepted: 
- uncompliant-vms 
- uncompliant-resource

=item B<--critical-*>

Critical threshold. '*' replacement values accepted: 
- uncompliant-vms 
- uncompliant-resource

=back

=cut
