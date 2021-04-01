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

package cloud::vmware::velocloud::restapi::mode::listlinks;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-edge-name:s' => { name => 'filter_edge_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $edges = $options{custom}->list_edges();
    foreach my $edge (@{$edges}) {
        if (defined($self->{option_results}->{filter_edge_name}) && $self->{option_results}->{filter_edge_name} ne '' &&
            $edge->{name} !~ /$self->{option_results}->{filter_edge_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $edge->{name} . "'.", debug => 1);
            next;
        }
        my $links = $options{custom}->list_links(edge_id => $edge->{id});
        foreach my $link (@{$links}) {
            push @{$self->{links}}, { %{$link}, edgeName => $edge->{name} };
        }
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $link (@{$self->{links}}) {
        $self->{output}->output_add(
            long_msg => sprintf(
                "[id = %s][display_name = %s][name = %s][edge_id = %s]" .
                "[edge_name = %s][state = %s][vpn_state = %s]",
                $link->{linkId}, $link->{link}->{displayName}, $link->{name}, $link->{link}->{edgeId},
                $link->{edgeName}, $link->{link}->{state}, $link->{link}->{vpnState}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List links:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(
        elements => [
            'id', 'display_name', 'name', 'edge_id', 'edge_name', 'state', 'vpn_state'
        ]
    );
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $link (@{$self->{links}}) {    
        $self->{output}->add_disco_entry(
            id => $link->{linkId},
            display_name => $link->{link}->{displayName},
            name => $link->{name},
            edge_id => $link->{link}->{edgeId},
            edge_name => $link->{edgeName},
            state => $link->{link}->{state},
            vpn_state => $link->{link}->{vpnState}
        );
    }
}

1;

__END__

=head1 MODE

List links.

=over 8

=item B<--filter-edge-name>

Filter edge by name (Can be a regexp).

=back

=cut
