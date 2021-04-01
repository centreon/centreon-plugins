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

package storage::netapp::ontap::oncommandapi::mode::listnodes;

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

    my $result = $options{custom}->get(path => '/nodes');

    foreach my $node (@{$result}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $node->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $node->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{nodes}->{$node->{key}} = {
            name => $node->{name},
            is_node_healthy => $node->{is_node_healthy},
            current_mode => $node->{current_mode},
            failover_state  => $node->{failover_state},
            is_failover_enabled  => $node->{is_failover_enabled},
        }
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $node (sort keys %{$self->{nodes}}) { 
        $self->{output}->output_add(long_msg => sprintf("[name = %s] [status = %s] [current_mode = %s] [failover_state = %s] [failover = %s]",
                                                         $self->{nodes}->{$node}->{name}, ($self->{nodes}->{$node}->{is_node_healthy}) ? "healthy" : "not healthy",
                                                         $self->{nodes}->{$node}->{current_mode}, $self->{nodes}->{$node}->{failover_state},
                                                         ($self->{nodes}->{$node}->{is_failover_enabled}) ? "enabled" : "disabled"));
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List nodes:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;  
    
    $self->{output}->add_disco_format(elements => ['name', 'status', 'current_mode', 'failover_state', 'failover']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $node (sort keys %{$self->{nodes}}) {             
        $self->{output}->add_disco_entry(
            name => $self->{nodes}->{$node}->{name},
            status => ($self->{nodes}->{$node}->{is_node_healthy}) ? "healthy" : "not healthy",
            current_mode => $self->{nodes}->{$node}->{current_mode},
            failover_state => $self->{nodes}->{$node}->{failover_state},
            failover => ($self->{nodes}->{$node}->{is_failover_enabled}) ? "enabled" : "disabled",
        );
    }
}

1;

__END__

=head1 MODE

List nodes.

=over 8

=item B<--filter-name>

Filter node name (can be a regexp).

=back

=cut
