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

package network::nokia::timos::snmp::mode::listldp;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"       => { name => 'filter_name' },
                                });
    $self->{ldp} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my %map_oper_state = (1 => 'unknown', 2 => 'inService', 3 => 'outOfService', 4 => 'transition');
my %map_admin_state = (1 => 'noop', 2 => 'inService', 3 => 'outOfService');
my $mapping = {
    vRtrName                    => { oid => '.1.3.6.1.4.1.6527.3.1.2.3.1.1.4' },
    vRtrLdpNgGenAdminState      => { oid => '.1.3.6.1.4.1.6527.3.1.2.91.47.1.5', map => \%map_admin_state },
    vRtrLdpNgGenIPv4OperState   => { oid => '.1.3.6.1.4.1.6527.3.1.2.91.47.1.6', map => \%map_oper_state },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(oids => [ 
            { oid => $mapping->{vRtrName}->{oid} },
            { oid => $mapping->{vRtrLdpNgGenAdminState}->{oid} },
            { oid => $mapping->{vRtrLdpNgGenIPv4OperState}->{oid} },
        ],
        return_type => 1, nothing_quit => 1);

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{vRtrLdpNgGenAdminState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{vRtrName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{vRtrName} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{ldp}->{$instance} = { name => $result->{vRtrName}, 
            admin_state => $result->{vRtrLdpNgGenAdminState}, ipv4_oper_state => $result->{vRtrLdpNgGenIPv4OperState} };
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{ldp}}) { 
        $self->{output}->output_add(long_msg => '[name = ' . $self->{ldp}->{$instance}->{name} . 
            "] [admin = '" . $self->{ldp}->{$instance}->{admin_state} . 
            "'] [ipv4_oper = '" . $self->{ldp}->{$instance}->{ipv4_oper_state} . '"]');
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List LDPs:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'admin', 'ipv4_oper']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{ldp}}) {             
        $self->{output}->add_disco_entry(name => $self->{ldp}->{$instance}->{name},
            admin => $self->{ldp}->{$instance}->{admin_state},
            ipv4_oper => $self->{ldp}->{$instance}->{ipv4_oper_state},
        );
    }
}

1;

__END__

=head1 MODE

List LDPs.

=over 8

=item B<--filter-name>

Filter by ldp instance (can be a regexp).

=back

=cut
    
