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

package hardware::server::dell::idrac::snmp::mode::globalstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %states = (
    1 => ['other', 'WARNING'], 
    2 => ['unknown', 'UNKNOWN'], 
    3 => ['ok', 'OK'], 
    4 => ['non critical', 'WARNING'],
    5 => ['critical', 'CRITICAL'],
    6 => ['nonRecoverable', 'WARNING'],
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
    $self->{snmp} = $options{snmp};

    my $oid_drsGlobalSystemStatus = '.1.3.6.1.4.1.674.10892.2.2.1.0';
    my $oid_globalSystemStatus = '.1.3.6.1.4.1.674.10892.5.2.1.0';
    my $oid_globalStorageStatus = '.1.3.6.1.4.1.674.10892.5.2.3.0';
    my $result = $self->{snmp}->get_leef(oids => [$oid_drsGlobalSystemStatus, $oid_globalSystemStatus, $oid_globalStorageStatus], nothing_quit => 1);
    
    if (defined($result->{$oid_globalSystemStatus})) {
        $self->{output}->output_add(severity =>  ${$states{$result->{$oid_globalSystemStatus}}}[1],
                                    short_msg => sprintf("Overall global status is '%s'", 
                                                         ${$states{$result->{$oid_globalSystemStatus}}}[0]));
        $self->{output}->output_add(severity =>  ${$states{$result->{$oid_globalStorageStatus}}}[1],
                                    short_msg => sprintf("Overall storage status is '%s'", 
                                                         ${$states{$result->{$oid_globalStorageStatus}}}[0]));
    } else {
        $self->{output}->output_add(severity =>  ${$states{$result->{$oid_drsGlobalSystemStatus}}}[1],
                                    short_msg => sprintf("Overall global status is '%s'", 
                                                         ${$states{$result->{$oid_drsGlobalSystemStatus}}}[0]));
    }                           
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check the overall status of iDrac card.

=over 8

=back

=cut
    
