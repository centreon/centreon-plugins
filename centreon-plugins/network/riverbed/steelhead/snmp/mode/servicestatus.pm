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

package network::riverbed::steelhead::snmp::mode::servicestatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %states = (
    0 => ['none', 'CRITICAL'],
    1 => ['unmanaged', 'CRITICAL'],
    2 => ['running', 'OK'],
    3 => ['sentCom1', 'CRITICAL'],
    4 => ['sentTerm1', 'CRITICAL'],
    5 => ['sentTerm2', 'CRITICAL'],
    6 => ['sentTerm3', 'CRITICAL'],
    7 => ['pending', 'CRITICAL'],
    8 => ['stopped', 'CRITICAL'],
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';

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

    my $oid_optServiceStatus = '.1.3.6.1.4.1.17163.1.1.2.8.0';

    my $result = $self->{snmp}->get_leef(oids => [ $oid_optServiceStatus ], nothing_quit => 1);

    $self->{output}->output_add(severity =>  ${$states{$result->{$oid_optServiceStatus}}}[1],
                                short_msg => sprintf("Optimization service status is '%s'",
                                                ${$states{$result->{$oid_optServiceStatus}}}[0]));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check the current status of the optimization service (STEELHEAD-MIB).

=over 8

=back

=cut
