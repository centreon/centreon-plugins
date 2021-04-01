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

package network::oracle::infiniband::snmp::mode::listinfinibands;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-ib-name:s"    => { name => 'filter_ib_name' },
                                  "filter-ibgw-:s"      => { name => 'filter_ibgw_name' },
                                });
    $self->{shares} = {};

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my %map_link_state = (1 => 'down', 2 => 'init', 3 => 'armed', 4 => 'active', 5 => 'other');
my %map_gw_link_state = (0 => 'down', 1 => 'up');
my $mapping = {
    ibSmaPortLinkState          => { oid => '.1.3.6.1.4.1.42.2.135.2.2.5.1.1.6', map => \%map_link_state },
};
my $mapping2 = {
    gwPortLongName              => { oid => '.1.3.6.1.4.1.42.2.135.2.8.1.1.1.3' },
    gwPortLinkState             => { oid => '.1.3.6.1.4.1.42.2.135.2.8.1.1.1.5', map => \%map_gw_link_state },
};
my $oid_ibPmaExtPortConnector = '.1.3.6.1.4.1.42.2.135.2.6.1.2.1.11';
my $oid_gwPortStateEntry = '.1.3.6.1.4.1.42.2.135.2.8.1.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(oids => [ { oid => $mapping->{ibSmaPortLinkState}->{oid} },
                                                                   { oid => $oid_ibPmaExtPortConnector },
                                                                   { oid => $oid_gwPortStateEntry, end => $mapping2->{gwPortLinkState}->{oid} },
                                                                 ],
                                                         nothing_quit => 1);
    foreach my $oid (keys %{$snmp_result->{ $oid_ibPmaExtPortConnector }}) {
        next if ($oid !~ /^$oid_ibPmaExtPortConnector\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{ $mapping->{ibSmaPortLinkState}->{oid} }, instance => $instance);
        
        $snmp_result->{ $oid_ibPmaExtPortConnector }->{$oid} =~ s/\x00//g;
        if (defined($self->{option_results}->{filter_ib_name}) && $self->{option_results}->{filter_ib_name} ne '' &&
            $snmp_result->{ $oid_ibPmaExtPortConnector }->{$oid} !~ /$self->{option_results}->{filter_ib_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $snmp_result->{ $oid_ibPmaExtPortConnector }->{$oid} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{infinibands}->{'ib_' . $instance} = { 
            name => $snmp_result->{ $oid_ibPmaExtPortConnector }->{$oid}, type => 'ib', status => $result->{ibSmaPortLinkState} };
    }
    
    foreach my $oid (keys %{$snmp_result->{ $oid_gwPortStateEntry }}) {
        next if ($oid !~ /^$mapping2->{gwPortLongName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{ $oid_gwPortStateEntry }, instance => $instance);
        
        $result->{gwPortLongName} =~ s/\x00//g;
        if (defined($self->{option_results}->{filter_ibgw_name}) && $self->{option_results}->{filter_ibgw_name} ne '' &&
            $result->{gwPortLongName} !~ /$self->{option_results}->{filter_ibgw_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{gwPortLongName} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{infinibands}->{'ibgw_' . $instance} = {
            name => $result->{gwPortLongName}, type => 'ibgw', status => $result->{gwPortLinkState} };
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{infinibands}}) { 
        $self->{output}->output_add(long_msg => '[name = ' . $self->{infinibands}->{$instance}->{name} . 
            "] [status = " . $self->{infinibands}->{$instance}->{status} . '] [type = ' . $self->{infinibands}->{$instance}->{type} . ']'
        );
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List infinibands:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'type', 'status']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{infinibands}}) {             
        $self->{output}->add_disco_entry(name => $self->{infinibands}->{$instance}->{name}, 
            status => $self->{infinibands}->{$instance}->{status}, type => $self->{infinibands}->{$instance}->{type});
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
    