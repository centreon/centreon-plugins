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

package storage::netapp::ontap::oncommandapi::mode::listclusters;

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

    my $result = $options{custom}->get(path => '/clusters');

    foreach my $cluster (@{$result}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $cluster->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $cluster->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{clusters}->{$cluster->{key}} = {
            name => $cluster->{name},
            status => $cluster->{status},
            metro_cluster_mode => defined($cluster->{metro_cluster_mode}) ? $cluster->{metro_cluster_mode} : "-",
            metro_cluster_configuration_state => defined($cluster->{metro_cluster_configuration_state}) ? $cluster->{metro_cluster_configuration_state} : "-",
        }
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $cluster (sort keys %{$self->{clusters}}) { 
        $self->{output}->output_add(long_msg => sprintf("[name = %s] [status = %s] [metro_cluster_mode = %s] [metro_cluster_configuration_state = %s]",
                                                         $self->{clusters}->{$cluster}->{name},
                                                         $self->{clusters}->{$cluster}->{status},
                                                         $self->{clusters}->{$cluster}->{metro_cluster_mode},
                                                         $self->{clusters}->{$cluster}->{metro_cluster_configuration_state}));
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List clusters:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'status', 'metro_cluster_mode',
                                                   'metro_cluster_configuration_state']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $cluster (sort keys %{$self->{clusters}}) {             
        $self->{output}->add_disco_entry(
            name => $self->{clusters}->{$cluster}->{name},
            status => $self->{clusters}->{$cluster}->{status},
            metro_cluster_mode => $self->{clusters}->{$cluster}->{metro_cluster_mode},
            metro_cluster_configuration_state => $self->{clusters}->{$cluster}->{metro_cluster_configuration_state},
        );
    }
}

1;

__END__

=head1 MODE

List clusters.

=over 8

=item B<--filter-name>

Filter snapmirror name (can be a regexp).

=back

=cut
