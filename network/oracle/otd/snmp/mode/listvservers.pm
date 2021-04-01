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

package network::oracle::otd::snmp::mode::listvservers;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"    => { name => 'filter_name' },
                                });
    $self->{vs} = {};

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $oid_vsId = '.1.3.6.1.4.1.111.19.190.1.30.1.2';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_vsId,
                                                nothing_quit => 1);
    foreach my $oid (keys %{$snmp_result}) {
        my $name = $snmp_result->{$oid};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{vs}->{$name} = { name => $name };
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{vs}}) { 
        $self->{output}->output_add(long_msg => '[name = ' . $self->{vs}->{$instance}->{name} . "]");
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List virtual servers:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{vs}}) {             
        $self->{output}->add_disco_entry(name => $self->{vs}->{$instance}->{name});
    }
}

1;

__END__

=head1 MODE

List infiniband interfaces.

=over 8

=item B<--filter-ib-name>

Filter by infiniband name (can be a regexp).

=item B<--filter-ibgw-name>

Filter by infiniband gateway name (can be a regexp).

=back

=cut
    