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
# Authors : Thomas Gourdin thomas.gourdin@gmail.com

package hardware::devices::timelinkmicro::tms6001::snmp::mode::antenna;

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

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();

    my $oid_qualityfrequency = '.1.3.6.1.4.1.22641.100.4.1.4.0';

    my $result = $self->{snmp}->get_leef(oids => [ $oid_qualityfrequency ], nothing_quit => 1);

    my $value = $result->{$oid_qualityfrequency};

    if ($value eq 'C') {
	$self->{output}->output_add(severity => 'OK',
  	   	         	    short_msg => sprintf("Antenna is connected"));
	} elsif ($value eq 'S') {
        $self->{output}->output_add(severity => 'WARNING',
                                    short_msg => sprintf("Antenna is shorted or powered off"));
	} elsif ($value eq 'N') {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("Antenna is not connected"));
	}
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check antenna status

=over 8

=back

=cut
