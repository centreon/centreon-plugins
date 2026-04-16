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

package apps::ipfabric::mode::listpaths;

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

my $mapping = ['id', 'src', 'srcPorts', 'dst', 'dstPorts', 'protocol'];

sub manage_selection {
    my ($self, %options) = @_;

    my ($indice, $limit) = (0, 1000);

    my $path_raw_form_post = {
        columns => [
            "id",
            "src",
            "srcPorts",
            "dst",
            "dstPorts",
            "protocol"
        ],
        filters => {},
        pagination => {
            limit => $limit,
            start => $indice 
        },
        reports => "/technology/routing/path-verifications"
    };

    my $results = [];

    while (1) {
        my $paths = $options{custom}->request_api(
            method => 'POST',
            endpoint => '/networks/path-lookup-checks',
            query_form_post => $path_raw_form_post
        );

        foreach my $path (@{$paths->{data}}) {
            $path->{dstPorts} //= '-';
            $path->{srcPorts} //= '-';

            push @$results, $path;
        }

        last if scalar(@{$paths->{data}}) < $limit;

        $indice += $limit;
        $path_raw_form_post->{pagination}->{start} = $indice;
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $entry (@$results) {
        $self->{output}->output_add(long_msg => 
            join('', map("[$_: " . $entry->{$_} . ']', @$mapping))
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List paths:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => $mapping);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $entry (@$results) {      
        $self->{output}->add_disco_entry(%$entry);
    }
}
1;

__END__

=head1 MODE

List GRE tunnels.

=over 8

=back

=cut
