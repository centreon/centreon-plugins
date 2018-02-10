#
# Copyright 2018 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure      application monitoring for
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
# See the License for the specific language governing permissions     
# limitations under the License.
#
# Author : CHEN JUN , aladdin.china@gmail.com

package apps::kingdee::eas::mode::oraclesession;

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
            "urlpath:s"         => { name => 'url_path', default => "/easportal/tools/nagios/checkoraclesession.jsp" },
            "datasource:s"      => { name => 'datasource' },
            "warning:s"         => { name => 'warning', default => "," },
            "critical:s"        => { name => 'critical', default => "," },
            });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{datasource}) || $self->{option_results}->{datasource} eq "") {
        $self->{output}->add_option_msg(short_msg => "Missing datasource name.");
        $self->{output}->option_exit();
    }
    $self->{option_results}->{url_path} .= "?ds=" . $self->{option_results}->{datasource};

    ($self->{warn_activecount}, $self->{warn_totalcount}) = split /,/, $self->{option_results}->{"warning"};
    ($self->{crit_activecount}, $self->{crit_totalcount}) = split /,/, $self->{option_results}->{"critical"};

    # warning
    if (($self->{perfdata}->threshold_validate(label => 'warn_activecount', value => $self->{warn_activecount})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning activecount threshold '" . $self->{warn_activecount} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn_totalcount', value => $self->{warn_totalcount})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning totalcount threshold '" . $self->{warn_totalcount} . "'.");
       $self->{output}->option_exit();
    }
    # critical
    if (($self->{perfdata}->threshold_validate(label => 'crit_activecount', value => $self->{crit_activecount})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical activecount threshold '" . $self->{crit_activecount} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit_totalcount', value => $self->{crit_totalcount})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical totalcount threshold '" . $self->{crit_totalcount} . "'.");
       $self->{output}->option_exit();
    } 
}

sub run {
    my ($self, %options) = @_;
 
    my $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path} . '&groupby=status');
	if ($webcontent !~ /^STATUS=ACTIVE/mi) {
		$self->{output}->output_add(
			severity  => 'UNKNOWN',
			short_msg => "Cannot find oracle session info."
		);
		$self->{output}->option_exit();
	}
		
    my ($activecount, $inactivecount, $totalcount) = (0, 0, 0);
    $activecount = $1 if $webcontent =~ /^STATUS=ACTIVE\sCOUNT=(\d+)/mi ;
    $inactivecount = $1 if $webcontent =~ /^STATUS=INACTIVE\sCOUNT=(\d+)/mi ;
    $totalcount = $activecount + $inactivecount;

    $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path} . '&groupby=wait_class&status=ACTIVE');
	if ($webcontent !~ /^WAIT_CLASS=.*?COUNT=\d+/i) {
		$self->{output}->output_add(
			severity  => 'UNKNOWN',
			short_msg => "Cannot find oracle session info."
		);
		$self->{output}->option_exit();
	} 
	
	my ($other, $queueing, $network, $administrative, $configuation, $commit) = (0, 0, 0, 0, 0, 0);
	my ($application, $concurrency, $systemio, $userio, $scheduler, $idle) = (0, 0, 0, 0, 0, 0);

    $other = $1 if $webcontent =~ /^WAIT_CLASS=Other\sCOUNT=(\d+)/mi;
    $queueing = $1 if $webcontent =~ /^WAIT_CLASS=Queueing\sCOUNT=(\d+)/mi;
    $network = $1 if $webcontent =~ /^WAIT_CLASS=Network\sCOUNT=(\d+)/mi;
    $administrative = $1 if $webcontent =~ /^WAIT_CLASS=Administrative\sCOUNT=(\d+)/mi;
    $configuation = $1 if $webcontent =~ /^WAIT_CLASS=Configuration\sCOUNT=(\d+)/mi;
    $commit = $1 if $webcontent =~ /^WAIT_CLASS=Commit\sCOUNT=(\d+)/mi;
    $application = $1 if $webcontent =~ /^WAIT_CLASS=Application\sCOUNT=(\d+)/mi;
    $concurrency = $1 if $webcontent =~ /^WAIT_CLASS=Concurrency\sCOUNT=(\d+)/mi;
    $systemio = $1 if $webcontent =~ /^WAIT_CLASS=\'System\sI\/O\'\sCOUNT=(\d+)/mi;
    $userio = $1 if $webcontent =~ /^WAIT_CLASS='User\sI\/O\'\sCOUNT=(\d+)/mi;
    $scheduler = $1 if $webcontent =~ /^WAIT_CLASS=Scheduler\sCOUNT=(\d+)/mi;
    $idle = $1 if $webcontent =~ /^WAIT_CLASS=Idle\sCOUNT=(\d+)/mi;
    
    my $cpuandwait = $idle + $network;
    
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("Other: %d", $other));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("Queueing: %d", $queueing));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("Administrative: %d", $administrative));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("Configuration: %d", $configuation));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("Commit: %d", $commit));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("Application: %d", $application));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("Concurrency: %d", $concurrency));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("System I/O: %d", $systemio));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("User I/O: %d", $userio));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("Scheduler: %d", $scheduler));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("CPU + CPU Wait: %d", $cpuandwait));
 
    my $exit = $self->{perfdata}->threshold_check(value => $activecount, threshold => [ { label => 'crit_activecount', exit_litteral => 'critical' }, 
                                                                                        { label => 'warn_activecount', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit, short_msg => sprintf("ActiveCount: %d", $activecount));

    $exit = $self->{perfdata}->threshold_check(value => $totalcount, threshold => [ { label => 'crit_totalcount', exit_litteral => 'critical' }, 
                                                                                      { label => 'warn_totalcount', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit, short_msg => sprintf("TotalCount: %d", $totalcount));
 
    $self->{output}->perfdata_add(label => "Other", unit => '', value => sprintf("%d", $other));
    $self->{output}->perfdata_add(label => "Queueing", unit => '', value => sprintf("%d", $queueing));
    $self->{output}->perfdata_add(label => "Administrative", unit => '', value => sprintf("%d", $administrative));
    $self->{output}->perfdata_add(label => "Configuration", unit => '', value => sprintf("%d", $configuation));
    $self->{output}->perfdata_add(label => "Commit", unit => '', value => sprintf("%d", $commit));
    $self->{output}->perfdata_add(label => "Application", unit => '', value => sprintf("%d", $application));
    $self->{output}->perfdata_add(label => "Concurrency", unit => '', value => sprintf("%d", $concurrency));
    $self->{output}->perfdata_add(label => "System I/O", unit => '', value => sprintf("%d", $systemio));
    $self->{output}->perfdata_add(label => "User I/O", unit => '', value => sprintf("%d", $userio));
    $self->{output}->perfdata_add(label => "Scheduler", unit => '', value => sprintf("%d", $scheduler));
    $self->{output}->perfdata_add(label => "CPU + CPU Wait", unit => '', value => sprintf("%d", $cpuandwait));

 	$self->{output}->perfdata_add(label => "ActiveCount", unit => '',
                                  value => sprintf("%d", $activecount),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_activecount'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_activecount'),
                                  );
    $self->{output}->perfdata_add(label => "TotalCount", unit => '',
                                  value => sprintf("%d", $totalcount),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_totalcount'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_totalcount'),
                                  );
 
    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check oracle database session status.

=over 8

=item B<--urlpath>

Set path to get status page. (Default: '/easportal/tools/nagios/checkoraclesession.jsp')

=item B<--datasource>

Specify the datasource name.

=item B<--warning>

Warning Threshold.  (activecount,totalcount)  for example: --warning=50,200

=item B<--critical>

Critical Threshold.  (activecount,totalcount)  for example: --critical=100,300

=back

=cut
