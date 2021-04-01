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

package apps::pfsense::snmp::mode::runtime;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use POSIX;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'warning:s'  => { name => 'warning' },
        'critical:s' => { name => 'critical' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
   
    my $oid_pfsenseStatus = '.1.3.6.1.4.1.12325.1.200.1.1.1.0'; 
    my $oid_pfsenseRuntime = '.1.3.6.1.4.1.12325.1.200.1.1.2.0';
    my ($result, $valueStatus, $valueRuntime);
    
    $result = $self->{snmp}->get_leef(oids => [ $oid_pfsenseStatus, $oid_pfsenseRuntime ], nothing_quit => 1);
    $valueStatus = $result->{$oid_pfsenseStatus};
    $valueRuntime = $result->{$oid_pfsenseRuntime};
    
    if ($valueStatus == 1) {
        my $exit_code = $self->{perfdata}->threshold_check(value => $valueRuntime, 
                                                           threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);    
        $self->{output}->perfdata_add(label => 'runtime', unit => 's',
                                      value => floor($valueRuntime / 100),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
        $self->{output}->output_add(severity => $exit_code,
                                    short_msg => sprintf("PfSense running since : %s",
                                                         centreon::plugins::misc::change_seconds(value => floor($valueRuntime / 100))));

    } else {
        $self->{output}->perfdata_add(label => 'runtime', unit => 's',
                                      value => 0,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
        $self->{output}->output_add(severity => 'critical',
                                    short_msg => 'PfSense not running');
        
    }
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check pfSense runtime.

=over 8

=item B<--warning>

Threshold warning in seconds.

=item B<--critical>

Threshold critical in seconds.

=back

=cut
