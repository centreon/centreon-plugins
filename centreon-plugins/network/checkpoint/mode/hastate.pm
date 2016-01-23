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

package network::checkpoint::mode::hastate;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_status = (
    0 => 'Member is UP and working',
    1 => 'Problem preventing role switching',
    2 => 'HA is down',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
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
    
    my $oid_haInstalled = '.1.3.6.1.4.1.2620.1.5.2.0';
    my $oid_haState = '.1.3.6.1.4.1.2620.1.5.6.0';
    my $oid_haStatCode = '.1.3.6.1.4.1.2620.1.5.101.0';
    my $oid_haStarted = '.1.3.6.1.4.1.2620.1.5.5.0';
    
    my $result = $self->{snmp}->get_leef(oids => [$oid_haInstalled, $oid_haState, $oid_haStatCode, $oid_haStarted], nothing_quit => 1);
    
    if ($result->{$oid_haInstalled} < 1 or $result->{$oid_haStarted} eq "no") {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => sprintf("Looks like HA is not started, or not installed .."),
                                    long_msg => sprintf("HA Installed : '%u' HA Started : '%s'", $result->{$oid_haInstalled},  $result->{$oid_haStarted}),
                                    );
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    my $status = $result->{$oid_haStatCode};

    if ($status < 1 ) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => sprintf("'%s'. State : '%s'", $map_status{$status}, $result->{$oid_haState}),
                                    );
    } elsif ($status == 1) {
        $self->{output}->output_add(severity => 'WARNING',
                                    short_msg => sprintf("'%s'. State : '%s'", $map_status{$status}, $result->{$oid_haState}),
                                    );

    } else {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("'%s'. State : '%s'", $map_status{$status}, $result->{$oid_haState}),
                                    );
    }
  
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check HA State of a Checkpoint node (chkpnt.mib).

=back

=cut
    
