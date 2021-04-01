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

package database::informix::sql::mode::logfilesusage;

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
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();

    my $query = q{
SELECT uniqid, size, used FROM syslogs WHERE uniqid >=
          (SELECT min(tx_loguniq)
           FROM systrans
           WHERE tx_loguniq > 0)
};
    
    $self->{sql}->query(query => $query);

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All logfiles usage are ok');    
    my $count = 0;
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        my $id = $row->{uniqid};

        my $prct_used = $row->{used} * 100 / $row->{size};
        
        $count++;
        $self->{output}->output_add(long_msg => sprintf("Logfile '%s': Used: %.2f%% Free: %.2f%%",
                                                         $id, $prct_used, 100 - $prct_used));
        my $exit_code = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        
        if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit_code,
                                        short_msg => sprintf("Logfile '%s': Used: %.2f%% Free: %.2f%%",
                                                             $id, $prct_used, 100 - $prct_used));
        }
        
        $self->{output}->perfdata_add(label => 'used_' . $id, unit => '%',
                                      value => sprintf("%.2f", $prct_used),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0, max => 100);
    }

    if ($count == 0) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => "Cannot find a logfile.");
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check usage for log files.

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
