#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package database::postgres::mode::timesync;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes;

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
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();

    $self->{sql}->query(query => q{
SELECT extract(epoch FROM now()) AS epok
});

    my ($result) = $self->{sql}->fetchrow_array();
    my $ltime = Time::HiRes::time();
    if (!defined($result)) {
        $self->{output}->add_option_msg(short_msg => "Cannot get server time.");
        $self->{output}->option_exit();
    }
    
    my $diff = $result - $ltime;
    my $exit_code = $self->{perfdata}->threshold_check(value => $diff, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    
    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("%.3fs time diff between servers", $diff));
    $self->{output}->perfdata_add(label => 'timediff', unit => 's',
                                  value => sprintf("%.3f", $diff),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Compares the local system time with the time reported by Postgres

=over 8

=item B<--warning>

Threshold warning in seconds. (use a range. it can be -0.3s or +0.3s.)

=item B<--critical>

Threshold critical in seconds. (use a range. it can be -0.3s or +0.3s.)

=back

=cut
