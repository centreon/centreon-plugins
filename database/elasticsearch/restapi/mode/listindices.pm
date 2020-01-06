#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package database::elasticsearch::restapi::mode::listindices;

use base qw(centreon::plugins::templates::counter);

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
    
    $self->{results} = $options{custom}->get(path => '/_cluster/health?level=indices');
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    
    foreach my $indice (keys %{$self->{results}->{indices}}) {
        $self->{output}->output_add(long_msg => sprintf("[name = %s][status = %s]",
            $indice,
            $self->{results}->{indices}->{$indice}->{status})
        );
    }
    $self->{output}->output_add(severity => 'OK',
                                short_msg => "List indices:");

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'status']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $indice (keys %{$self->{results}->{indices}}) {
        $self->{output}->add_disco_entry(
            name => $indice,
            status => $self->{results}->{indices}->{$indice}->{status}
        );
    }
}

1;

__END__

=head1 MODE

List indices

=over 8

=back

=cut
