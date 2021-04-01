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

package network::mitel::3300icp::snmp::mode::listzaps;

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
    $self->{zap} = {};

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $mapping = {
    mitelBWMCurrentZAPLabel => { oid => '.1.3.6.1.4.1.1027.4.1.1.2.5.1.1.1.1.4' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(oids => [ { oid => $mapping->{mitelBWMCurrentZAPLabel}->{oid} },
                                                                 ],
                                                         return_type => 1, nothing_quit => 1);
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{mitelBWMCurrentZAPLabel}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{mitelBWMCurrentZAPLabel} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{mitelBWMCurrentZAPLabel} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{zap}->{$instance} = { 
            name => $result->{mitelBWMCurrentZAPLabel},
        };
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{zap}}) { 
        $self->{output}->output_add(long_msg => '[name = ' . $self->{zap}->{$instance}->{name} . "]"
        );
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List zone access points:');
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
    foreach my $instance (sort keys %{$self->{zap}}) {
        $self->{output}->add_disco_entry(
            name => $self->{zap}->{$instance}->{name}
        );
    }
}

1;

__END__

=head1 MODE

List zone access points.

=over 8

=item B<--filter-name>

Filter by zone access points name (can be a regexp).

=back

=cut
    
