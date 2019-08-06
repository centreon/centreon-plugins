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

package apps::centreon::map4::jmx::mode::eventqueue;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"      => { name => 'warning', },
                                  "critical:s"     => { name => 'critical', },
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
    $self->{connector} = $options{custom};

    $self->{request} = [
         { mbean => "com.centreon.studio:name=statistics,type=session" }
    ];

    my $result = $self->{connector}->get_attributes(request => $self->{request}, nothing_quit => 0);
  
    my $exit = $self->{perfdata}->threshold_check(value => $result->{"com.centreon.studio:name=statistics,type=session"}->{AverageEventQueueSize},
                                                  threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning'} ]);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Average event queue size : %d",
                                                      $result->{"com.centreon.studio:name=statistics,type=session"}->{AverageEventQueueSize}));

    $self->{output}->perfdata_add(label => 'events',
                                  value => $result->{"com.centreon.studio:name=statistics,type=session"}->{AverageEventQueueSize},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check Centreon Map Session event queue size

Example:

perl centreon_plugins.pl --plugin=apps::centreon::map::jmx::plugin --custommode=jolokia --url=http://10.30.2.22:8080/jolokia-war --mode=event-queue

=over 8

=item B<--warning>

Set this threshold if you want a warning if global sessions event queue size match threshold 

=item B<--critical>

Set this threshold if you want a warning if global sessions event queue size match threshold

=back

=cut

