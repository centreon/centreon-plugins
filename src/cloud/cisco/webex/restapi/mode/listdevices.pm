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

package cloud::cisco::webex::restapi::mode::listdevices;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'workspace-id:s'      => { name => 'workspace_id' },
        'person-id:s'         => { name => 'person_id' },
        'resource-type:s'     => { name => 'resource_type', default => 'workspace' },
        'use-id-empty-serial' => { name => 'use_id_empty_serial' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if ($self->{option_results}->{resource_type} !~ /^workspace|person/) {
        $self->{output}->add_option_msg(short_msg => 'Unknown resource type. Must be "workspace" or "person"');
        $self->{output}->option_exit();
    }

    if ($self->{option_results}->{resource_type} eq 'workspace'
        && (!defined($self->{option_results}->{workspace_id}) || $self->{option_results}->{workspace_id} eq '')) {
        $self->{output}->add_option_msg(short_msg =>
            'Need to specify --workspace-id option when using --resource-type "workspace"');
        $self->{output}->option_exit();
    }

    if ($self->{option_results}->{resource_type} eq 'person'
        && (!defined($self->{option_results}->{person_id}) || $self->{option_results}->{person_id} eq '')) {
        $self->{output}->add_option_msg(short_msg =>
            'Need to specify --person-id option when using --resource-type "person"');
        $self->{output}->option_exit();
    }
}

my @labels = (
    'id',
    'display_name',
    'product',
    'ip',
    'type',
    'serial',
    'lifecycle',
    'planned_maintenance',
    'connection_status'
);

sub manage_selection {
    my ($self, %options) = @_;

    return $options{custom}->get_devices_from_api();
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $entry (@$results) {
        $self->{output}->output_add(long_msg =>
            join('', map("[$_: " . $entry->{$_} . ']', @labels))
        );
    }

    $self->{output}->output_add(severity => 'OK', short_msg => 'List devices:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ @labels ]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach my $entry (@$results) {
        $self->{output}->add_disco_entry(%$entry);
    }
}

1;

__END__

=head1 MODE

List devices.

=over 8

=item B<--workspace-id>

Filter devices by workspace id. Used together with --resource-type "workspace".

=item B<--person-id>

Filter devices by person id. Used together with --resource-type "person".

=item B<--resource-type>

Choose the type of resources to discover (can be: C<workspace>, C<person>). Default: C<workspace>.

=item B<--use-id-empty-serial>

use the last 10 characters of the id as the serial number if serial number is empty.

=back


=cut

