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

package network::adva::fsp3000::snmp::mode::listinterfaces;

use base qw(snmp_standard::mode::listinterfaces);

use strict;
use warnings;

my $mapping = {
    advaInventoryAidString  => { oid => '.1.3.6.1.4.1.2544.1.11.7.10.1.1.6' },
    advaInventoryUnitName   => { oid => '.1.3.6.1.4.1.2544.1.11.7.10.1.1.7' },
};

sub set_oids_label {
    my ($self, %options) = @_;

    $self->{oids_label} = {
        'ifdesc' => '.1.3.6.1.2.1.2.2.1.2',
        'ifalias' => '.1.3.6.1.2.1.31.1.1.1.18',
    };
}

sub default_oid_filter_name {
    my ($self, %options) = @_;
    
    return 'ifdesc';
}

sub default_oid_display_name {
    my ($self, %options) = @_;
    
    return 'ifdesc';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->SUPER::manage_selection(%options);
    
    my $oid_advaInventoryEntry = '.1.3.6.1.4.1.2544.1.11.7.10.1.1';
    my $snmp_result = $self->{snmp}->get_table(
        oid => $oid_advaInventoryEntry, 
        begin => $mapping->{advaInventoryAidString}->{oid}, 
        end => $mapping->{advaInventoryUnitName}->{oid}
    );
    
    $self->{extra_oids}->{type} = { oid => $mapping->{advaInventoryUnitName}->{oid}, matching => '%{instance}$' };
    $self->{results}->{ $self->{extra_oids}->{type} } = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{advaInventoryUnitName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        next if ($result->{advaInventoryUnitName} !~ /^(SFP|XFP)/i);

        # interface name example: CH-1-3-N1
        # inventory name example: PL-1-3-N1        
        next if ($result->{advaInventoryAidString} !~ /(\d+-\d+-[^\-]+)$/);
        my $lookup = $1;
        
        foreach (sort @{$self->{interface_id_selected}}) {
            my $display_value = $self->get_display_value(id => $_);
            
            if ($display_value =~ /CH-$lookup$/) {
                $self->{results}->{ $self->{extra_oids}->{type}->{oid} }->{ $self->{extra_oids}->{type}->{oid} . '.' . $_ } = $result->{advaInventoryUnitName};
            }
        }
    }
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{extra_oids}->{type} = { oid => $mapping->{advaInventoryUnitName}->{oid}, matching => '%{instance}$' };
    $self->SUPER::disco_format(%options);
}

1;

__END__

=head1 MODE

=over 8

=item B<--interface>

Set the interface (number expected) ex: 1,2,... (empty means 'check all interface').

=item B<--name>

Allows to use interface name with option --interface instead of interface oid index (Can be a regexp)

=item B<--speed>

Set interface speed (in Mb).

=item B<--skip-speed0>

Don't display interface with speed 0.

=item B<--filter-status>

Display interfaces matching the filter (example: 'up').

=item B<--use-adminstatus>

Display interfaces with AdminStatus 'up'.

=item B<--oid-filter>

Choose OID used to filter interface (default: ifDesc) (values: ifDesc, ifAlias).

=item B<--oid-display>

Choose OID used to display interface (default: ifDesc) (values: ifDesc, ifAlias).

=item B<--display-transform-src>

Regexp src to transform display value. (security risk!!!)

=item B<--display-transform-dst>

Regexp dst to transform display value. (security risk!!!)

=item B<--add-extra-oid>

Display an OID.
Example: --add-extra-oid='alias,.1.3.6.1.2.1.31.1.1.1.18'
or --add-extra-oid='vlan,.1.3.6.1.2.1.31.19,%{instance}\..*'

=back

=cut
