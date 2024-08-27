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

package cloud::docker::local::mode::containerstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_containers_output {
    my ($self, %options) = @_;

    return "Container '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'containers', type => 1, cb_prefix_output => 'prefix_containers_output', message_multiple => 'All containers are ok' }
    ];

    $self->{maps_counters}->{containers} = [
         { label => 'status', type => 2, critical_default => '%{status} !~ /up/i', set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                output_template => "status is '%s'",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
        'filter-id:s'   => { name => 'filter_id' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'docker ps',
        command_options => '-a'
    );

    $self->{containers} = {};
    my @lines = split(/\n/, $stdout);
    # Header not needed
    # CONTAINER ID   IMAGE                   COMMAND                  CREATED        STATUS       PORTS                                       NAMES
    # 543c8edfea2b   registry/mariadb:10.7   "docker-entrypoint.s…"   5 months ago   Up 12 days   0.0.0.0:3306->3306/tcp, :::3306->3306/tcp   db

    shift(@lines);
    foreach my $line (@lines) {
        next if ($line !~ /^(\S+)\s{3,}(\S+)\s{3,}(.*?)\s{3,}(.*?)\s{3,}(.*?)\s{3,}(.*?)\s{3,}(\S+)$/);

        my ($id, $image, $command, $created, $status, $ports, $name) = ($1, $2, $3, $4, $5, $6, $7);

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $id !~ /$self->{option_results}->{filter_id}/);

        $self->{containers}->{$id} = {
            name => $name,
            status => $status
        };
    }

    if (scalar(keys %{$self->{containers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No container found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check container status.

Command used: docker ps -a

=over 8

=item B<--filter-name>

Filter by container name (can be a regexp).

=item B<--filter-id>

Filter by container ID (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /up/i').
You can use the following variables: %{status}, %{name}

=back

=cut
