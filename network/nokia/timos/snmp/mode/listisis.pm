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

package network::nokia::timos::snmp::mode::listisis;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my %map_status = (1 => 'unknown', 2 => 'inService', 3 => 'outOfService', 4 => 'transition');
my $oid_vRtrName = '.1.3.6.1.4.1.6527.3.1.2.3.1.1.4';
my $mapping = {
    tmnxIsisOperState   => { oid => '.1.3.6.1.4.1.6527.3.1.2.88.1.1.1.12', map => \%map_status },
};

sub manage_selection {
    my ($self, %options) = @_;

     my $snmp_result = $options{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_vRtrName },
                                                            { oid => $mapping->{tmnxIsisOperState}->{oid} },
                                                         ], return_type => 1, nothing_quit => 1);
    $self->{isis} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{tmnxIsisOperState}->{oid}\.(\d+)\.(\d+)$/);
        my ($vrtr_id, $isis_id) = ($1, $2);
        
        my $vrtr_name = $snmp_result->{$oid_vRtrName . '.' . $vrtr_id};
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $vrtr_id . '.' . $isis_id);
        
        $self->{isis}->{$vrtr_id . '.' . $isis_id} = {
            name =>  $vrtr_name . '.' . $isis_id,
            status => $result->{tmnxIsisOperState}
        };
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{isis}}) { 
        $self->{output}->output_add(long_msg => "[name = '" . $self->{isis}->{$instance}->{name} . 
            "'] [status = '" . $self->{isis}->{$instance}->{status} .
            '"]');
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List IS-IS:');
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
    foreach my $instance (sort keys %{$self->{isis}}) {             
        $self->{output}->add_disco_entry(name => $self->{isis}->{$instance}->{name},
            status => $self->{isis}->{$instance}->{status},
        );
    }
}

1;

__END__

=head1 MODE

List IS-IS instances.

=over 8

=back

=cut
    
