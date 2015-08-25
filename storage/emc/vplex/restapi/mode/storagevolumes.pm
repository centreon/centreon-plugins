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

package storage::emc::vplex::restapi::mode::storagevolumes;

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
                   "cluster:s"       => { name => 'cluster', default => 'cluster-1' },
                   "filter-name:s"   => { name => 'filter_name' },
               });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

}

sub run {
    my ($self, %options) = @_;
    my $vplex = $options{custom};
    
    my $urlbase = '/vplex/clusters/'.$self->{option_results}->{cluster}.'/storage-elements/storage-volumes/';
    
    $vplex->connect();

    my @items = $vplex->get_items(url => $urlbase);

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All storage volumes are OK');

    foreach my $item (@items) {

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $item !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => sprintf("Skipping storage '%s'.", $item));
            next;
        }

        my $details = $vplex->get_param(url => $urlbase,
                                        item => $item,
                                        param => 'health-state');

        $self->{output}->output_add(long_msg => sprintf("Device '%s' health state is '%s'", 
                                                        $item, 
                                                        $details->{context}->[0]->{attributes}->[0]->{value}
                                                        ));

        if ($details->{context}->[0]->{attributes}->[0]->{value} ne 'ok') {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("Storage '%s' service is '%s'", 
                                                             $item,
                                                             $details->{context}->[0]->{attributes}->[0]->{value}
                                                             ));
        }

    }
     
    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check Cluster devices health for VPlex

=over 8

=item B<--cluster>

Set cluster name to check (cluster-1 and cluster-2) 

=item B<--filter-name>

Filter some elements by name (can be a regexp)

=back

=cut
