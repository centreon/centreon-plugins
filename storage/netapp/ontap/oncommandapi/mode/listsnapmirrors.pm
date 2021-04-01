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

package storage::netapp::ontap::oncommandapi::mode::listsnapmirrors;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get(path => '/snap-mirrors');

    foreach my $snapmirror (@{$result}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snapmirror->{source_location} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $snapmirror->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{snapmirrors}->{$snapmirror->{key}} = {
            source_location => $snapmirror->{source_location},
            destination_location => $snapmirror->{destination_location},
            mirror_state => $snapmirror->{mirror_state},
            is_healthy => $snapmirror->{is_healthy},
        }
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $snapmirror (sort keys %{$self->{snapmirrors}}) { 
        $self->{output}->output_add(long_msg => sprintf("[source_location = %s] [destination_location = %s] [mirror_state = %s] [is_healthy = %s]",
                                                         $self->{snapmirrors}->{$snapmirror}->{source_location},
                                                         $self->{snapmirrors}->{$snapmirror}->{destination_location},
                                                         $self->{snapmirrors}->{$snapmirror}->{mirror_state},
                                                         $self->{snapmirrors}->{$snapmirror}->{is_healthy}));
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List snap mirrors:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['source_location', 'destination_location', 'mirror_state',
                                                   'is_healthy']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $snapmirror (sort keys %{$self->{snapmirrors}}) {             
        $self->{output}->add_disco_entry(
            source_location => $self->{snapmirrors}->{$snapmirror}->{source_location},
            destination_location => $self->{snapmirrors}->{$snapmirror}->{destination_location},
            mirror_state => $self->{snapmirrors}->{$snapmirror}->{mirror_state},
            is_healthy => $self->{snapmirrors}->{$snapmirror}->{is_healthy},
        );
    }
}

1;

__END__

=head1 MODE

List snap mirrors.

=over 8

=item B<--filter-name>

Filter snapmirror name (can be a regexp).

=back

=cut
