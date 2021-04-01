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

package storage::netapp::ontap::oncommandapi::mode::listfcports;

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

    my $result = $options{custom}->get(path => '/fc-ports');

    foreach my $fcport (@{$result}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $fcport->{wwpn} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $fcport->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{fcports}->{$fcport->{key}} = {
            wwpn => $fcport->{wwpn},
            adapter => $fcport->{adapter},
            status => $fcport->{status},
            state => $fcport->{state},
            switch_port => $fcport->{switch_port},
        }
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $fcport (sort keys %{$self->{fcports}}) { 
        $self->{output}->output_add(long_msg => sprintf("[wwpn = %s] [adapter = %s] [status = %s] [state = %s] [switch_port = %s]",
                                                         $self->{fcports}->{$fcport}->{wwpn},
                                                         $self->{fcports}->{$fcport}->{adapter},
                                                         $self->{fcports}->{$fcport}->{status},
                                                         $self->{fcports}->{$fcport}->{state},
                                                         $self->{fcports}->{$fcport}->{switch_port}));
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List FC ports:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['wwpn', 'adapter', 'status', 'state', 'switch_port']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $fcport (sort keys %{$self->{fcports}}) {             
        $self->{output}->add_disco_entry(
            wwpn => $self->{fcports}->{$fcport}->{wwpn},
            adapter => $self->{fcports}->{$fcport}->{adapter},
            status => $self->{fcports}->{$fcport}->{status},
            state => $self->{fcports}->{$fcport}->{state},
            switch_port => $self->{fcports}->{$fcport}->{switch_port},
        );
    }
}

1;

__END__

=head1 MODE

List FC ports.

=over 8

=item B<--filter-name>

Filter FC ports name (can be a regexp).

=back

=cut
