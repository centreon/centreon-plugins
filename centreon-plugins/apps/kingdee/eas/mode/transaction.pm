#
# Copyright 2018 Centreon (http://www.centreon.com/)
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
# Author : CHEN JUN , aladdin.china@gmail.com

package apps::kingdee::eas::mode::transaction;

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
            "urlpath:s"         => { name => 'url_path', default => "/easportal/tools/nagios/checktransaction.jsp" },
            "datasource:s"      => { name => 'datasource' },
            "warning:s"         => { name => 'warning', default => "," },
            "critical:s"        => { name => 'critical', default => "," },
            });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    ($self->{warn_activecount}, $self->{warn_timeoutcount}) 
        = split /,/, $self->{option_results}->{"warning"};
    ($self->{crit_activecount}, $self->{crit_timeoutcount}) 
        = split /,/, $self->{option_results}->{"critical"};

    # warning
    if (($self->{perfdata}->threshold_validate(label => 'warn_activecount', value => $self->{warn_activecount})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning activecount threshold '" . $self->{warn_activecount} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn_timeoutcount', value => $self->{warn_timeoutcount})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning timeoutcount threshold '" . $self->{warn_timeoutcount} . "'.");
        $self->{output}->option_exit();
    }
    # critical
    if (($self->{perfdata}->threshold_validate(label => 'crit_activecount', value => $self->{crit_activecount})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical activecount threshold '" . $self->{crit_activecount} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit_timeoutcount', value => $self->{crit_timeoutcount})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical timeoutcount threshold '" . $self->{crit_timeoutcount} . "'.");
        $self->{output}->option_exit();
    }    
}

sub run {
    my ($self, %options) = @_;
    
    my $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path});
    if ($webcontent !~ /TransactionCount=\d+/i) {
        $self->{output}->output_add(
            severity  => 'UNKNOWN',
            short_msg => "Cannot find transaction status."
        );
    }

    my ($transactioncount, $totaltransactiontime, $committedcount, $rolledbackcount, $activecount, $maxtransactiontime, $defaulttimeout, $timeoutcount) = (0, 0, 0, 0, 0, 0, 0, 0);

    $transactioncount = $1 if $webcontent =~ /TransactionCount=(\d+)\s/i;
    $totaltransactiontime = $1 if $webcontent =~ /TotalTransactionTime=(\d+)\s/i;
    $committedcount = $1 if $webcontent =~ /CommittedCount=(\d+)\s/i;
    $rolledbackcount = $1 if $webcontent =~ /RolledbackCount=(\d+)\s/i;
    $activecount = $1 if $webcontent =~ /ActiveCount=(\d+)\s/i;
    $maxtransactiontime = $1 if $webcontent =~ /MaxTransactionTime=(\d+)\s/i;
    $defaulttimeout = $1 if $webcontent =~ /DefaultTimeout=(\d+)\s/i;
    $timeoutcount = $1 if $webcontent =~ /TimedOutCount=(\d+)\s/i;

    my $exit = $self->{perfdata}->threshold_check(value => $activecount, threshold => [ { label => 'crit_activecount', exit_litteral => 'critical' }, 
                                                                                        { label => 'warn_activecount', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit, short_msg => sprintf("ActiveCount: %d", $activecount));

    $exit = $self->{perfdata}->threshold_check(value => $timeoutcount, threshold => [ { label => 'crit_timeoutcount', exit_litteral => 'critical' }, 
                                                                                      { label => 'warn_timeoutcount', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit, short_msg => sprintf("TimedOutCount: %d", $timeoutcount));

    $self->{output}->output_add(severity => "ok", short_msg => sprintf("CommittedCount: %d", $committedcount));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("RolledbackCount: %d", $rolledbackcount));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("TransactionCount: %d", $transactioncount));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("TotalTransactionTime: %dms", $totaltransactiontime));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("MaxTransactionTime: %dms", $maxtransactiontime));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("DefaultTimeout: %ds", $defaulttimeout));
 
    
    $self->{output}->perfdata_add(label => "ActiveCount", unit => '',
                                  value => sprintf("%d", $activecount),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_activecount'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_activecount'),
                                  );
    $self->{output}->perfdata_add(label => "TimedOutCount", unit => '',
                                  value => sprintf("%d", $timeoutcount),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_timeoutcount'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_timeoutcount'),
                                  );
    $self->{output}->perfdata_add(label => "c[CommittedCount]", unit => '',
                                  value => sprintf("%d", $committedcount),
                                  );
    $self->{output}->perfdata_add(label => "c[RolledbackCount]", unit => '',
                                  value => sprintf("%d", $rolledbackcount),
                                  );
    $self->{output}->perfdata_add(label => "c[TransactionCount]", unit => '',
                                  value => sprintf("%d", $transactioncount),
                                  );
    $self->{output}->perfdata_add(label => "c[TotalTransactionTime]", unit => 'ms',
                                  value => sprintf("%d", $totaltransactiontime),
                                  );
    $self->{output}->perfdata_add(label => "MaxTransactionTime", unit => 'ms',
                                  value => sprintf("%d", $maxtransactiontime),
                                  );
    $self->{output}->perfdata_add(label => "DefaultTimeout", unit => 's',
                                  value => sprintf("%d", $defaulttimeout),
                                  );
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check EAS application EJB transaction status.

=over 8

=item B<--urlpath>

Set path to get status page. (Default: '/easportal/tools/nagios/checktransaction.jsp')

=item B<--warning>

Warning Threshold for (activecount,timeoutcount).  for example : --warning=100,1

=item B<--critical>

Critical Threshold for (activecount,timeoutcount). for example : --critical=100,1

=back

=cut
