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

package network::alcatel::isam::snmp::mode::listhubsap;

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

my %map_admin = (1 => 'up', 2 => 'down');
my %map_oper = (1 => 'up', 2 => 'down', 3 => 'ingressQosMismatch',
    4 => 'egressQosMismatch', 5 => 'portMtuTooSmall', 6 => 'svcAdminDown',
    7 => 'iesIfAdminDown'
);
my $mapping = {
    sapAdminStatus              => { oid => '.1.3.6.1.4.1.6527.3.1.2.4.3.2.1.6', map => \%map_admin },
    sapOperStatus               => { oid => '.1.3.6.1.4.1.6527.3.1.2.4.3.2.1.7', map => \%map_oper },
};
my $oid_sapDescription = '.1.3.6.1.4.1.6527.3.1.2.4.3.2.1.5';
my $oid_svcDescription = '.1.3.6.1.4.1.6527.3.1.2.4.2.2.1.6';
my $oid_sapBaseInfoEntry = '.1.3.6.1.4.1.6527.3.1.2.4.3.2.1';
my $oid_ifName  = '.1.3.6.1.2.1.31.1.1.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{sap} = {};
    my $snmp_result = $self->{snmp}->get_multiple_table(oids => [ 
            { oid => $oid_sapDescription }, 
            { oid => $oid_svcDescription },
            { oid => $oid_ifName },
            { oid => $oid_sapBaseInfoEntry, start => $mapping->{sapAdminStatus}->{oid}, end => $mapping->{sapOperStatus}->{oid} },
        ], nothing_quit => 1);
    foreach my $oid (keys %{$snmp_result->{$oid_sapDescription}}) {
        next if ($oid !~ /^$oid_sapDescription\.(.*?)\.(.*?)\.(.*?)$/);
        my ($SvcId, $SapPortId, $SapEncapValue) = ($1, $2, $3);
        
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{ $oid_sapBaseInfoEntry }, instance => $SvcId . '.' . $SapPortId . '.' . $SapEncapValue);
        $self->{sap}->{$SvcId . '.' . $SapPortId . '.' . $SapEncapValue} = {
            SvcId => $SvcId,
            SapPortId => $SapPortId,
            SapEncapValue => $SapEncapValue,
            IfName => defined($snmp_result->{$oid_ifName}->{$oid_ifName . '.' . $SapPortId}) && $snmp_result->{$oid_ifName}->{$oid_ifName . '.' . $SapPortId} ne '' ?
                $snmp_result->{$oid_ifName}->{$oid_ifName . '.' . $SapPortId} :  $SapPortId,
            SapDescription => $snmp_result->{$oid_sapDescription}->{$oid} ne '' ? $snmp_result->{$oid_sapDescription}->{$oid} : 'unknown',
            SvcDescription => defined($snmp_result->{$oid_svcDescription}->{$oid_svcDescription . '.' . $SvcId}) && $snmp_result->{$oid_svcDescription}->{$oid_svcDescription . '.' . $SvcId} ne '' ?
                $snmp_result->{$oid_svcDescription}->{$oid_svcDescription . '.' . $SvcId} : $SvcId,
            SapEncapName => defined($snmp_result->{$oid_svcDescription}->{$oid_svcDescription . '.' . $SapEncapValue}) && $snmp_result->{$oid_svcDescription}->{$oid_svcDescription . '.' . $SapEncapValue} ne '' ?
                $snmp_result->{$oid_svcDescription}->{$oid_svcDescription . '.' . $SapEncapValue} : $SapEncapValue,
            SapAdminStatus => $result->{sapAdminStatus},
            SapOperStatus => $result->{sapOperStatus},
        };        
    }
}

sub run {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->manage_selection();
    foreach my $instance (sort keys %{$self->{sap}}) { 
        my $msg = '';
        $self->{output}->output_add(long_msg => 
            "[SvcId = " . $self->{sap}->{$instance}->{SvcId} . "]" .
            "[SapPortId = " . $self->{sap}->{$instance}->{SapPortId} . "]" .
            "[SapEncapValue = " . $self->{sap}->{$instance}->{SapEncapValue} . "]" .
            "[SapDescription = " . $self->{sap}->{$instance}->{SapDescription} . "]" .
            "[SvcDescription = " . $self->{sap}->{$instance}->{SvcDescription} . "]" .
            "[SapEncapName = " . $self->{sap}->{$instance}->{SapEncapName} . "]" .
            "[SapAdminStatus = " . $self->{sap}->{$instance}->{SapAdminStatus} . "]" .
            "[SapOperStatus = " . $self->{sap}->{$instance}->{SapOperStatus} . "]" .
            "[IfName = " . $self->{sap}->{$instance}->{IfName}
        );
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List SAP:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['SvcId', 'SapPortId', 'SapEncapValue', 'SapDescription', 
        'SvcDescription', 'SapEncapName', 'SapAdminStatus', 'SapOperStatus', 'IfName']);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection(disco => 1);
    foreach my $instance (sort keys %{$self->{sap}}) {   
       $self->{output}->add_disco_entry(%{$self->{sap}->{$instance}});
    }
}

1;

__END__

=head1 MODE

List SAP.

=over 8

=back

=cut
    
