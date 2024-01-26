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

package cloud::azure::management::insightsmetrics::mode::listlogicaldisks;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'name'           => { name => 'name' },
        'resource:s'     => { name => 'resource' },
        'workspace-id:s' => { name => 'workspace_id' }
    });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{resource}) || $self->{option_results}->{resource} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --resource option.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

   my $query = 'InsightsMetrics | where Namespace == "LogicalDisk" | distinct Tags, _ResourceId, Computer';
   if (defined($self->{option_results}->{name})) {
       $query .= '| where Computer == "' . $self->{option_results}->{resource} . '"';
   } else {
       $query .= '| where _ResourceId == "' . $self->{option_results}->{resource} . '"';
   }

    my $results = $options{custom}->azure_get_insights_analytics(
        workspace_id => $self->{option_results}->{workspace_id},
        query        => $query,
        timespan     => $self->{option_results}->{timespan},
        disco        => 1
    );


    foreach my $entry (keys %{$results->{data}}) {
        my $decoded_tag = $options{custom}->json_decode(content => $results->{data}->{$entry}->{tags});

        $self->{logicaldisk}->{$decoded_tag->{"vm.azm.ms/mountId"}}->{name} = $decoded_tag->{"vm.azm.ms/mountId"};
    }

    if (scalar(keys %{$self->{logicaldisk}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No logical disks found. Can be: filters, cache file.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $mount (sort keys %{$self->{logicaldisk}}) {
        $self->{output}->output_add(long_msg => '[name = ' . $mount . ']' );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List logical disks:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ 'name' ]);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $mount (sort keys %{$self->{logicaldisk}}) {
        $self->{output}->add_disco_entry(name => $self->{logicaldisk}->{$mount}->{name});
    }
}

1;

__END__

=head1 MODE

List Azure Computer logical disks.

Example:

perl centreon_plugins.pl --plugin=cloud::azure::management::insightsmetrics::plugin --custommode=api --mode=list-logical-disks
--subscription=1111 --tenant=2222 --client-id=3333 --client-secret=4444 --workspace-id=5555 --verbose --resource='azure-vm1'
--name

=over 8

=item B<--workspace-id>
(mandatory)
Specify the Azure Log Analytics Workspace ID.

=item B<--resource>

(mandatory)
Specify the Azure VM Resource ID or name. Short name can be used if the option --name is defined.
Example: --resource='/subscriptions/1234abcd-5678-defg-9012-3456789abcde/resourcegroups/my_resourcegroup/providers/microsoft.compute/virtualmachines/azure-vm1'

=item B<--name>

(optional)
Use only the name of the VM resource rather than the full ID.
Example: --resource='azure-vm1' --name

=back

=cut
