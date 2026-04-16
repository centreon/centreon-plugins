#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package storage::hp::alletra::restapi::mode::listvolumes;

use strict;
use warnings;

use base qw(centreon::plugins::mode);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-id:s'   => { name => 'filter_id' },
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my %map_state = (
    1  => 'normal',
    2  => 'degraded',
    3  => 'failed',
    99 => 'unknown'
);

sub run {
    my ($self, %options) = @_;

    my $response = $options{custom}->request_api(endpoint => '/api/v1/volumes');
    my $volumes = $response->{members};

    $self->{volumes} = [];

    for my $volume (@{$volumes}) {
        # skip if filtered by name
        if (defined($self->{option_results}->{filter_name})
            and $self->{option_results}->{filter_name} ne '' and $volume->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(
                long_msg => "Skipping $volume->{name} because the name does not match the name filter.",
                debug    => 1
            );
            next;
        }

        # skip if filtered by name
        if (defined($self->{option_results}->{filter_id})
            and $self->{option_results}->{filter_id} ne '' and $volume->{id} !~ /$self->{option_results}->{filter_id}/) {
            $self->{output}->output_add(
                long_msg => "Skipping $volume->{name} because the id does not match the id filter.",
                debug    => 1
            );
            next;
        }

        push @{$self->{volumes}}, {
            id    => $volume->{id},
            name  => $volume->{name},
            size  => $volume->{sizeMiB},
            state => defined($map_state{$volume->{state}}) ? $map_state{$volume->{state}} : 'NOT_DOCUMENTED'
        };

        $self->{output}->output_add(
            long_msg => sprintf(
                "[id: %s][name: %s][size: %s][state: %s]",
                $volume->{id},
                $volume->{name},
                $volume->{sizeMiB},
                $volume->{state}
            )
        );
    }

    if (!defined($options{disco_show})) {
        $self->{output}->output_add(severity => 'OK', short_msg => 'Volumes:');
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    }
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ 'id', 'name', 'size', 'state' ]);
}

sub disco_show {
    my ($self, %options) = @_;

    $options{disco_show} = 1;
    $self->run(%options);

    for my $disk (@{$self->{volumes}}) {
        $self->{output}->add_disco_entry(
            id    => $disk->{id},
            name  => $disk->{name},
            size  => $disk->{size},
            state => $disk->{state}
        );
    }
}

1;

__END__

=head1 MODE

List physical volumes using the HPE Alletra REST API.

=over 8

=item B<--filter-name>

Display volumes matching the name filter.

=item B<--filter-id>

Display volumes matching the id filter.

=back

=cut
