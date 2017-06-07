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

package centreon::common::sophos::xg::mode::service_ips;

use base qw(centreon::plugins::mode);

use strict;
use warnings;


my %maps_state = (
    1 => 'untouched',
    2 => 'stopped',
    3 => 'initializing',
    4 => 'running',
    5 => 'exiting',
    6 => 'dead',
);


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
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

    my $oid_service = '.1.3.6.1.4.1.21067.2.1.2.10.10';


    my $results = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_service },
                                                            ],
                                                   nothing_quit => 1);



    my $service_state = $results->{$oid_service}->{$oid_service . '.0'}; 
    my $service_output = defined($maps_state{$service_state}) ? $maps_state{$service_state} : 'unknown';


    if ($service_state == 4) {
        $self->{output}->output_add(severity => 'ok',
                                    short_msg => 'Service state is ' . $service_output . '.');
    }
    else {
        $self->{output}->output_add(severity => 'critical',
                                    short_msg => 'Service state is ' . $service_output . '.');
    }


    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check system service state (CYBEROAM-MIB).

=over 8


=back

=cut
