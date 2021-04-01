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

package centreon::common::ingrian::snmp::mode::disk;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'disk', type => 1, cb_prefix_output => 'prefix_disk_output', message_multiple => 'All disk usages are ok' }
    ];
    
    $self->{maps_counters}->{disk} = [
        { label => 'usage', set => {
                key_values => [ { name => 'used' }, { name => 'display' } ],
                output_template => 'Used : %.2f %%',
                perfdatas => [
                    { label => 'used', value => 'used', template => '%.2f', min => 0, max => 100, unit => '%',
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_disk_output {
    my ($self, %options) = @_;
    
    return "Disk '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                });
    
    return $self;
}

my $mapping = {
    naeSystemDiskDescr          => { oid => '.1.3.6.1.4.1.5595.3.2.7.1.2' },
    naeSystemDiskUtilization    => { oid => '.1.3.6.1.4.1.5595.3.2.7.1.3' },
};
my $oid_naeSystemStatDiskEntry = '.1.3.6.1.4.1.5595.3.2.7.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{disk} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_naeSystemStatDiskEntry,
                                                nothing_quit => 1);
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{naeSystemDiskUtilization}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        $self->{disk}->{$instance} = { display => $result->{naeSystemDiskDescr}, 
                                       used => $result->{naeSystemDiskUtilization}};
    }
}

1;

__END__

=head1 MODE

Check disk usages.

=over 8

=item B<--warning-usage>

Threshold warning (in percent).

=item B<--critical-usage>

Threshold critical (in percent).

=back

=cut
