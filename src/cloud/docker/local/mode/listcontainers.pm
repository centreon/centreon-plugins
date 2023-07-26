#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package cloud::docker::local::mode::listcontainers;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
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

        $self->{containers}->{$id} = {
            name => $name,
            status => $status
        };
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $id (sort keys %{$self->{containers}}) { 
        $self->{output}->output_add(
            long_msg => '[id: ' . $id . "] [name: " . $self->{containers}->{$id}->{name} . "]" .
                " [status: " . $self->{containers}->{$id}->{status} . "]"
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List containers:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['id', 'name', 'status']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $id (sort keys %{$self->{containers}}) {             
        $self->{output}->add_disco_entry(
            id => $id,
            name => $self->{containers}->{$id}->{name},
            status => $self->{containers}->{$id}->{status}
        );
    }
}

1;

__END__

=head1 MODE

List containers.

Command used: docker ps -a

=over 8

=back

=cut
