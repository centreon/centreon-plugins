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

package cloud::azure::management::costs::mode::tagonresources;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'vms'               => { name => 'vms' },
        'tag-name:s'        => { name => 'tag_name' },
	'exclude-name:s'    => { name => 'exclude_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{tag_name}) || $self->{option_results}->{tag_name} eq '') {
	$self->{output}->add_option_msg(short_msg => "Need to specify --tag-name option");
	$self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $output_error = "";
    my $output = "";
    my $items;

    # VMs
    if (defined($self->{option_results}->{vms})) {
	$items = $options{custom}->azure_list_vms(
	    resource_group => $self->{option_results}->{resource_group}
	    );
	$self->{vms} = {no_tag => 0, total => 0, name => ""};
	foreach my $item (@{$items}) {
	    $self->{vms}->{total}++;;
	    next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
		     && $item->{name} =~ /$self->{option_results}->{exclude_name}/);
	    next if (defined($item->{tags}->{finopsstartstop}));
	    $self->{vms}->{no_tag}++;
	    $self->{vms}->{name} .= $item->{name} . " ";	    
	}
	if ($self->{vms}->{no_tag}) {
	    $output_error .= "Found " . $self->{vms}->{no_tag} . " VM(s) with no " . $self->{option_results}->{tag_name}  . " tag ( " . $self->{vms}->{name} . ")\n";
	}
	else {
	    $output .= "All " . $self->{vms}->{total} . "VM(s) have a " . $self->{option_results}->{tag_name}  . " tag\n";
	}
    }
    
    if ($output_error) {
	$self->{output}->output_add(severity => "CRITICAL", short_msg => $output_error . $output);
    }
    else {
	$self->{output}->output_add(severity => "OK", short_msg => "Everything is OK\n" . $output);
    }
}

1;

__END__

=head1 MODE

Check if a specified tag is present on every resource of the specified resource type(s)
Can be useful for example if you use tags to start/stop VMs and need to identify VMs
that do NOT have such a tag 

Example: 
perl centreon_plugins.pl --plugin=cloud::azure::management::costs::plugin --custommode=api --mode=tag-on-resources
{--resource-group='MYRESOURCEGROUP'] --exclude-name='MyVM1|MyVM2.*' [--vms] --tag-name='startstoptag' --api-version='2022-08-01'


=over 8

=item B<--resource-group>

Set resource group (Optional).

=item B<--exclude-name>

Exclude resource from check (Can be a regexp).

=item B<--vms>

Check tag on Virtual machines

=item B<--tag-name>

Name of the tag to check (Required).

=back

=cut
