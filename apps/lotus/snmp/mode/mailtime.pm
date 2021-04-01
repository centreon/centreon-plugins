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

package apps::lotus::snmp::mode::mailtime;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
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
    
    my $oid_lnAverageMailDeliverTime = '.1.3.6.1.4.1.334.72.1.1.4.9.0';
    my $oid_lnMaximumMailDeliverTime = '.1.3.6.1.4.1.334.72.1.1.4.12.0';
    my $oid_lnMinimumMailDeliverTime = '.1.3.6.1.4.1.334.72.1.1.4.15.0';

    my $results = $self->{snmp}->get_leef(oids => [$oid_lnMinimumMailDeliverTime, $oid_lnMaximumMailDeliverTime, $oid_lnAverageMailDeliverTime], nothing_quit => 1);
    
    my $exit_code = $self->{perfdata}->threshold_check(value => $results->{$oid_lnAverageMailDeliverTime}, 
                               threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("Average seconds to deliver mail: %.2f (Min : %.2f) (Max : %.2f)", 
                                                     $results->{$oid_lnAverageMailDeliverTime}, $results->{$oid_lnMinimumMailDeliverTime}, $results->{$oid_lnMaximumMailDeliverTime}));
    $self->{output}->perfdata_add(label => 'avgTime', unit => 's',
                                  value => $results->{$oid_lnAverageMailDeliverTime},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));
    $self->{output}->perfdata_add(label => 'minTime', unit => 's',
                                  value => $results->{$oid_lnMinimumMailDeliverTime});
    $self->{output}->perfdata_add(label => 'maxTime', unit => 's',
                                  value => $results->{$oid_lnMaximumMailDeliverTime});

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check the mail average delivery time (print min and max for info)(NOTES-MIB.mib)

=over 8

=item B<--warning>

Threshold warning in seconds.

=item B<--critical>

Threshold critical in seconds.

=back

=cut
