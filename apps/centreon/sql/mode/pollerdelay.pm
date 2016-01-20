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

package apps::centreon::sql::mode::pollerdelay;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"       => { name => 'warning', default => 300 },
                                  "critical:s"      => { name => 'critical', default => 600 },
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
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical}. "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
    $self->{sql}->query(query => q{
        SELECT instance_id,name,last_alive,running FROM centreon_storage.instances WHERE deleted = '0';
    });
    my $result = $self->{sql}->fetchall_arrayref();
    
    my $timestamp = time();
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All poller delay for last update are ok"));
    foreach my $row (@{$result}) {
    	if ($$row[3] == 0) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("%s is not running", $$row[1]));
            next;
        }
        my $delay = $timestamp - $$row[2];
        my $exit_code = $self->{perfdata}->threshold_check(value => abs($delay), threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        $self->{output}->output_add(long_msg => sprintf("Delay for last update of %s is %d seconds", $$row[1], $delay));
        if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit_code,
                                        short_msg => sprintf("Delay for last update of %s is %d seconds", $$row[1], $delay));
        }
        $self->{output}->perfdata_add(label => sprintf("delay_%s", $$row[1]), unit => 's',
                                      value => $delay,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check the delay of the last update from a poller to the Central server.
The mode should be used with mysql plugin and dyn-mode option.

=over 8

=item B<--warning>

Threshold warning in seconds.

=item B<--critical>

Threshold critical in seconds.

=back

=cut
