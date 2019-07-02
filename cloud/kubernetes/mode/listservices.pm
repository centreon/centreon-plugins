#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package cloud::kubernetes::mode::listservices;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s"         => { name => 'filter_name' },
        "filter-namespace:s"    => { name => 'filter_namespace' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->kubernetes_list_services();
    
    foreach my $service (@{$results->{items}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $service->{metadata}->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $service->{metadata}->{name} . "': no matching filter name.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_namespace}) && $self->{option_results}->{filter_namespace} ne '' &&
            $service->{metadata}->{namespace} !~ /$self->{option_results}->{filter_namespace}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $service->{metadata}->{namespace} . "': no matching filter namespace.", debug => 1);
            next;
        }

        $self->{services}->{$service->{metadata}->{uid}} = {
            uid => $service->{metadata}->{uid},
            name => $service->{metadata}->{name},
            namespace => $service->{metadata}->{namespace},
        }            
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $service (sort keys %{$self->{services}}) { 
        $self->{output}->output_add(long_msg => sprintf("[uid = %s] [name = %s] [namespace = %s]",
                                                         $self->{services}->{$service}->{uid},
                                                         $self->{services}->{$service}->{name},
                                                         $self->{services}->{$service}->{namespace}));
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List services:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;  
    
    $self->{output}->add_disco_format(elements => ['uid', 'name', 'namespace']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $service (sort keys %{$self->{services}}) {             
        $self->{output}->add_disco_entry(
            uid => $self->{services}->{$service}->{uid},
            name => $self->{services}->{$service}->{name},
            namespace => $self->{services}->{$service}->{namespace},
        );
    }
}

1;

__END__

=head1 MODE

List services.

=over 8

=item B<--filter-name>

Filter service name (can be a regexp).

=item B<--filter-namespace>

Filter service namespace (can be a regexp).

=back

=cut
