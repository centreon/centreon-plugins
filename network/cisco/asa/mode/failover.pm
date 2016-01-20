#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package network::cisco::asa::mode::failover;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_failover = (
    1 => 'other',
    2 => 'up', # for '.4' index
    3 => 'down', # can be
    4 => 'error', # maybe
    5 => 'overTemp',
    6 => 'busy',
    7 => 'noMedia',
    8 => 'backup',
    9 => 'active', # can be
    10 => 'standby' # can be
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "dont-warn-notstandby"       => { name => 'dont_warn_notstandby' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $active_units = 0;
    my $exit = 'ok';
    # primary is '.6' index and secondary is '.7' index (it's like that. '.4' is the global interface)
    my $oid_cfwHardwareStatusValue_primary = '.1.3.6.1.4.1.9.9.147.1.2.1.1.1.3.6';
    my $oid_cfwHardwareStatusValue_secondary = '.1.3.6.1.4.1.9.9.147.1.2.1.1.1.3.7';
    my $oid_cfwHardwareStatusDetail_primary = '.1.3.6.1.4.1.9.9.147.1.2.1.1.1.4.6';
    my $oid_cfwHardwareStatusDetail_secondary = '.1.3.6.1.4.1.9.9.147.1.2.1.1.1.4.7';
    my $result = $self->{snmp}->get_leef(oids => [$oid_cfwHardwareStatusValue_primary, $oid_cfwHardwareStatusValue_secondary, 
                                                  $oid_cfwHardwareStatusDetail_primary, $oid_cfwHardwareStatusDetail_secondary], nothing_quit => 1);
    
    if ($result->{$oid_cfwHardwareStatusValue_primary} == 9 || $result->{$oid_cfwHardwareStatusValue_primary} == 10 ) {
        $active_units++;
    }
    if ($result->{$oid_cfwHardwareStatusValue_secondary} == 9 || $result->{$oid_cfwHardwareStatusValue_secondary} == 10 ) {
        $active_units++;
    }
    if ($active_units == 0) {
        $exit = 'critical';
    } elsif ($active_units == 1 && !defined($self->{option_results}->{dont_warn_notstandby})) {
        # No redundant interface
        $exit = 'warning';
    }
    
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Primary unit is '%s' [details: '%s'], Secondary unit is '%s' [details : '%s']",
                                                     $map_failover{$result->{$oid_cfwHardwareStatusValue_primary}}, $result->{$oid_cfwHardwareStatusDetail_primary},
                                                     $map_failover{$result->{$oid_cfwHardwareStatusValue_secondary}}, $result->{$oid_cfwHardwareStatusDetail_secondary}));                                 
                                                     
    $self->{output}->perfdata_add(label => "active_units",
                                  value => $active_units,
                                  min => 0, max => 2);
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check failover status on Cisco ASA (CISCO-UNIFIED-FIREWALL-MIB).

=over 8

=item B<--dont-warn-notstandby>

Don't return warning if a unit is active and the other unit is not in standby status.

=back

=cut
    