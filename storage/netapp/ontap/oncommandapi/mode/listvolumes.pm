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

package storage::netapp::ontap::oncommandapi::mode::listvolumes;

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

    my $result = $options{custom}->get(path => '/volumes');

    foreach my $volume (@{$result}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $volume->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $volume->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{volumes}->{$volume->{key}} = {
            name => $volume->{name},
            state => $volume->{state},
            vol_type => $volume->{vol_type},
            style  => $volume->{style},
            is_replica_volume  => $volume->{is_replica_volume},
            size_total => $volume->{size_total},
        }
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $volume (sort keys %{$self->{volumes}}) { 
        $self->{output}->output_add(long_msg => sprintf("[name = %s] [state = %s] [vol_type = %s] [style = %s] [is_replica_volume = %s] [size_total = %s]",
                                                         $self->{volumes}->{$volume}->{name}, $self->{volumes}->{$volume}->{state},
                                                         $self->{volumes}->{$volume}->{vol_type}, $self->{volumes}->{$volume}->{style},
                                                         $self->{volumes}->{$volume}->{is_replica_volume}, $self->{volumes}->{$volume}->{size_total}));
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List volumes:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;  
    
    $self->{output}->add_disco_format(elements => ['name', 'state', 'vol_type', 'style',
                                                   'is_replica_volume', 'size_total']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $volume (sort keys %{$self->{volumes}}) {             
        $self->{output}->add_disco_entry(
            name => $self->{volumes}->{$volume}->{name},
            state => $self->{volumes}->{$volume}->{state},
            vol_type => $self->{volumes}->{$volume}->{vol_type},
            style => $self->{volumes}->{$volume}->{style},
            is_replica_volume => $self->{volumes}->{$volume}->{is_replica_volume},
            size_total => $self->{volumes}->{$volume}->{size_total},
        );
    }
}

1;

__END__

=head1 MODE

List volumes.

=over 8

=item B<--filter-name>

Filter volume name (can be a regexp).

=back

=cut
