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

package cloud::cisco::webex::restapi::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'type:s'   => { name => 'type' },
        'prettify' => { name => 'prettify' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{type}) && $self->{option_results}->{type} !~ /^focus|huddle|meetingRoom|open|desk|other|notSet/) {
        $self->{output}->add_option_msg(short_msg => 'unknown workspace type');
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    my $disco_stats;
    $disco_stats->{start_time} = time();

    my $ws_locations = $options{custom}->get_workspace_locations_from_api();
    foreach my $ws_location (@{$ws_locations}) {
        $self->{workspace_locations}->{$ws_location->{id}} = $ws_location;
    }

    my $workspaces = $options{custom}->get_workspaces_from_api();

    foreach my $workspace (@{$workspaces}) {
        $workspace->{location_name} = $self->{workspace_locations}->{$workspace->{workspace_location_id}}->{display_name};
        $workspace->{longitude} = $self->{workspace_locations}->{$workspace->{workspace_location_id}}->{longitude};
        $workspace->{latitude} = $self->{workspace_locations}->{$workspace->{workspace_location_id}}->{latitude};
        $workspace->{address} = $self->{workspace_locations}->{$workspace->{workspace_location_id}}->{address};
        $workspace->{city} = $self->{workspace_locations}->{$workspace->{workspace_location_id}}->{city};
    }

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = scalar(@$workspaces);
    $disco_stats->{results} = $workspaces;

    my $encoded_data;
    eval {
        if (defined($self->{option_results}->{prettify})) {
            $encoded_data = JSON::XS->new->utf8->pretty->encode($disco_stats);
        } else {
            $encoded_data = JSON::XS->new->utf8->encode($disco_stats);
        }
    };
    if ($@) {
        $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}';
    }

    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

workspace discovery.

=over 8

=item B<--type>

Choose the type of workspace to discover (can be: C<focus>, C<huddle>, C<meetingRoom>, C<open>, C<desk>, C<other>, C<notSet>).

=back

=cut