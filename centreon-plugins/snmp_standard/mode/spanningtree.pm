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

package snmp_standard::mode::spanningtree;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %states = (
    1 => ['disabled', 'OK'], 
    2 => ['blocking', 'CRITICAL'], 
    3 => ['listening', 'OK'], 
    4 => ['learning', 'OK'],
    5 => ['forwarding', 'OK'],
    6 => ['broken', 'CRITICAL'],
    
    10 => ['not defined', 'UNKNOWN'], # mine status
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
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

    my $oid_dot1dStpPortEnable = '.1.3.6.1.2.1.17.2.15.1.4';
    my $oid_dot1dStpPortState = '.1.3.6.1.2.1.17.2.15.1.3';
    my $oid_dot1dBasePortIfIndex = '.1.3.6.1.2.1.17.1.4.1.2';
    my $oid_ifDesc = '.1.3.6.1.2.1.2.2.1.2';
    my $results = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_dot1dStpPortEnable },
                                                            { oid => $oid_dot1dStpPortState },
                                                           ], nothing_quit => 1);
    my @instances = ();
    foreach my $oid (keys %{$results->{$oid_dot1dStpPortEnable}}) {
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;

        # '2' => disabled, we skip
        if ($results->{$oid_dot1dStpPortEnable}->{$oid} == 2) {
            $self->{output}->output_add(long_msg => sprintf("Skipping interface '%d': Stp port disabled", $instance));
            next;
        }
        
        push @instances, $instance;
       
    }
    
    $self->{snmp}->load(oids => [$oid_dot1dBasePortIfIndex],
                            instances => [@instances]);
    my $result = $self->{snmp}->get_leef(nothing_quit => 1);
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'Spanning Tree is ok on all interfaces');
    # Get description
    foreach my $oid (keys %$result) {
        next if ($oid !~ /^$oid_dot1dBasePortIfIndex\./ || !defined($result->{$oid}));
        
        $self->{snmp}->load(oids => [$oid_ifDesc . "." . $result->{$oid}]);
    }
    my $result_desc = $self->{snmp}->get_leef();
    
    foreach my $instance (@instances) {
        my $stp_state = defined($results->{$oid_dot1dStpPortState}->{$oid_dot1dStpPortState . '.' . $instance}) ? 
                          $results->{$oid_dot1dStpPortState}->{$oid_dot1dStpPortState . '.' . $instance} : 10;
        my $descr = (defined($result->{$oid_dot1dBasePortIfIndex . '.' . $instance}) && defined($result_desc->{$oid_ifDesc . '.' . $result->{$oid_dot1dBasePortIfIndex . '.' . $instance}})) ? 
                        $result_desc->{$oid_ifDesc . '.' . $result->{$oid_dot1dBasePortIfIndex . '.' . $instance}} : 'unknown';
        
        $self->{output}->output_add(long_msg => sprintf("Spanning Tree interface '%s' state is %s", $descr,
                                            ${$states{$stp_state}}[0]));
        if (${$states{$stp_state}}[1] ne 'OK') {
             $self->{output}->output_add(severity => ${$states{$stp_state}}[1],
                                        short_msg => sprintf("Spanning Tree interface '%s' state is %s", $descr,
                                                             ${$states{$stp_state}}[0]));
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Spanning-Tree current state of ports (BRIDGE-MIB).

=over 8

=back

=cut
    