#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package storage::emc::vplex::restapi::mode::clustercommunication;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.1';
    $options{options}->add_options(arguments =>
               {
                   "cluster-nodes:s@"    => { name => 'cluster_nodes', },
                   "witness-name:s"      => { name => 'witness_name', },
               });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
 
    if ( !defined($self->{option_results}->{cluster_nodes}) || !defined($self->{option_results}->{witness_name}) ) {
        $self->{output}->add_option_msg(short_msg => "You need to cluster-nodes AND witness-name options.");
        $self->{output}->option_exit();
    }
   
}

sub run {
    my ($self, %options) = @_;
    my $vplex = $options{custom};
    
    my $urlbase = '/vplex/cluster-witness/components/';
    my @nodes = split /,/, $self->{option_results}->{cluster_nodes}->[0];

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'Cluster communication is OK');

    $vplex->connect();    

    foreach my $node (@nodes) {
        my $details = $vplex->get_param(url   => $urlbase,
                                        item  => $node,
                                        param => 'operational-state');

        $self->{output}->output_add(long_msg => sprintf("Node '%s' is '%s'", $node,
                                                        $details->{context}->[0]->{attributes}->[0]->{value}));

        if ($details->{context}->[0]->{attributes}->[0]->{value} ne 'in-contact') {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("Node '%s' is '%s'", 
                                                             $node, $details->{context}->[0]->{attributes}->[0]->{value}));
        }

    }
        
    my $details = $vplex->get_param(url   => $urlbase,
                                    item  => $self->{option_results}->{witness_name},
                                    param => 'operational-state');


    if ($details->{context}->[0]->{attributes}->[0]->{value} ne 'clusters-in-contact') {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("Witness '%s' see nodes as '%s'",
                                                         $self->{option_results}->{witness_name},
                                                         $details->{context}->[0]->{attributes}->[0]->{value}));
    }

    $self->{output}->output_add(long_msg => sprintf("Witness '%s' says '%s'", $self->{option_results}->{witness_name}, 
                                                    $details->{context}->[0]->{attributes}->[0]->{value})); 

     $self->{output}->display();
     $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Cluster communication state for VPlex

=over 8

=item B<--cluster-nodes>

Mandatory. Specify the name of your cluster nodes, as comma-separated list (EMC defaults are 'cluster-1', 'cluster-2', ..

=item B<--cluster-nodes>

Mandatory. Specify the name of your witness server (EMC default is 'server')

=back

=cut
