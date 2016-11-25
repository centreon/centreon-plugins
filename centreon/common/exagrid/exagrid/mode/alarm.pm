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

package centreon::common::exagrid::exagrid::mode::alarm;

use base qw(centreon::plugins::mode);

use strict;
use warnings;


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
    $self->{snmp} = $options{snmp};


    my $oid = '.1.3.6.1.4.1.14941.4.6.1.0';


    my $result = $self->{snmp}->get_leef(oids => [$oid] ,
                                                   nothing_quit => 1);

    my $value = $result->{$oid};



    if ($value == 1) {
        $self->{output}->output_add(severity => "ok", 
                                    short_msg => 'Server has no alarms');
    }
    elsif ($value == 2) {
        $self->{output}->output_add(severity => "warning",
                                    short_msg => 'Server is in a Warning Alarm State.');
    }
   elsif ($value == 3) {
        $self->{output}->output_add(severity => "critical",
                                    short_msg => 'Server is in Error Alarm State.');
    }
   else {
        $self->{output}->output_add(severity => "unknown",
                                    short_msg => 'Unknown');
    }


    $self->{output}->perfdata_add(label => 'value', unit => undef, value => $value);


    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check alarm state (EXAGRID-MIB).

=over 8


=back

=cut
