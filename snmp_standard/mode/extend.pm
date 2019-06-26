#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package snmp_standard::mode::extend;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use Switch;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '0.1';
    $options{options}->add_options(arguments => { 
        'alias:s'                   => { name => 'alias' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (!defined($self->{option_results}->{alias}) || $self->{option_results}->{alias} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify an alias with option --alias.');
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    
    my $OID_alias = $self->get_oid_from_alias(alias => $self->{option_results}->{alias});
    
    my $OID_ExtendedOutputFull = '.1.3.6.1.4.1.8072.1.3.2.3.1.2.4' . $OID_alias; # NET-SNMP-EXTEND-MIB::nsExtendOutputFull
    my $OID_ExtendedOutput1Line = '.1.3.6.1.4.1.8072.1.3.2.3.1.2.4' . $OID_alias; # NET-SNMP-EXTEND-MIB::nsExtendOutput1Line
    my $OID_Return_Code =     '.1.3.6.1.4.1.8072.1.3.2.3.1.4.4' . $OID_alias; # NET-SNMP-EXTEND-MIB::nsExtendResult
    
    my $result = $self->{snmp}->get_leef(oids => [$OID_ExtendedOutputFull, $OID_Return_Code, $OID_ExtendedOutput1Line], nothing_quit => 1);
    
    my $ExtendedOutputFull = $result->{$OID_ExtendedOutputFull};
    my $Return_Code = $result->{$OID_Return_Code};
    my $ExtendedOutput1Line = $result->{$OID_ExtendedOutput1Line};
    
    my $severity = 'UNKNOWN';
    
    switch($Return_Code) {
        case 0 { $severity = 'OK' }
        case 1 { $severity = 'WARNING' }
        case 2 { $severity = 'CRITICAL' }
    }
        
    $self->{output}->output_add(short_msg => $ExtendedOutput1Line,
                                long_msg => $ExtendedOutputFull);
                                
    $self->{output}->display(force_ignore_perfdata => 1);
    
    $self->{output}->exit(exit_litteral => $severity);
}

sub get_oid_from_alias {
    my ($self, %options) = @_;
    
    my $OID = '';
    my @array = unpack("C*", $options{alias});
    foreach $val (@array) {
        $OID = $OID . ".$val";
    }
    
    return $OID;
}

    
    

1;
__END__

=head1 MODE

Replicate NRPE behavior with NET-SNMP.
Must be use with "extend-sh" command in snmpd.conf on the remote host.

Ex. in the snmpd.conf

#extend-sh alias command
extend-sh myalias /bin/echo "it works !"

=over 8

=item B<--alias>

name of the alias to check on the remote host
