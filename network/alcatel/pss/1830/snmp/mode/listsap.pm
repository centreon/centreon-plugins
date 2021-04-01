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

package network::alcatel::pss::1830::snmp::mode::listsap;

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

my $oid_tnSapDescription = '.1.3.6.1.4.1.7483.6.1.2.4.3.2.1.5';
my $oid_tnSvcName = '.1.3.6.1.4.1.7483.6.1.2.4.2.2.1.28';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{sap} = {};
    my $snmp_result = $self->{snmp}->get_multiple_table(oids => [ { oid => $oid_tnSapDescription }, { oid => $oid_tnSvcName } ], 
                                                    nothing_quit => 1);
    foreach my $oid (keys %{$snmp_result->{$oid_tnSapDescription}}) {
        next if ($oid !~ /^$oid_tnSapDescription\.(.*?)\.(.*?)\.(.*?)\.(.*?)$/);
        my ($SysSwitchId, $SvcId, $SapPortId, $SapEncapValue) = ($1, $2, $3, $4);
        
        $self->{sap}->{$SysSwitchId . '.' . $SvcId . '.' . $SapPortId . '.' . $SapEncapValue} = {
            SysSwitchId => $SysSwitchId,
            SvcId => $SvcId,
            SapPortId => $SapPortId,
            SapEncapValue => $SapEncapValue,
            SapDescription => $snmp_result->{$oid_tnSapDescription}->{$oid},
            SvcName => defined($snmp_result->{$oid_tnSvcName}->{$oid_tnSvcName . '.' . $SysSwitchId . '.' . $SvcId}) ?
                $snmp_result->{$oid_tnSvcName}->{$oid_tnSvcName . '.' . $SysSwitchId . '.' . $SvcId} : ''
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
            "[SysSwitchId = " . $self->{sap}->{$instance}->{SysSwitchId} . "]" .
            "[SvcId = " . $self->{sap}->{$instance}->{SvcId} . "]" .
            "[SapPortId = " . $self->{sap}->{$instance}->{SapPortId} . "]" .
            "[SapEncapValue = " . $self->{sap}->{$instance}->{SapEncapValue} . "]" .
            "[SapDescription = " . $self->{sap}->{$instance}->{SapDescription} . "]" .
            "[SvcName = " . $self->{sap}->{$instance}->{SvcName} . "]"
        );
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List SAP:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['SysSwitchId', 'SvcId', 'SapPortId', 'SapEncapValue', 'SapDescription', 'SvcName']);
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
    