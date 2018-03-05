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

package apps::kingdee::eas::mode::httphandler;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new( package => __PACKAGE__, %options );
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(
        arguments => {
            "urlpath:s"          => { name => 'url_path', default => "/easportal/tools/nagios/checkhttphandler.jsp" },
            "warning:s"          => { name => 'warning' },
            "critical:s"         => { name => 'critical' },
        }
    );

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

    my $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path});

    if ($webcontent !~ /MaxThreads=\d+/i) {
        $self->{output}->output_add(
            severity  => 'UNKNOWN',
            short_msg => "Cannot find httphandler status in response: '" . $webcontent . "'"
        );
        $self->{output}->option_exit();
    }

    my ($maxthreads, $minsparethreads, $maxsparethreads, $maxqueuesize, $idletimeout, $processedcount) = (0, 0, 0, 0, 0, 0);
    my ($currentthreadcount, $availablethreadcount, $busythreadcount, $maxavailablethreadcount, $maxbusythreadcount) = (0, 0, 0, 0, 0);
    my ($maxprocessedtime, $createcount, $destroycount) = (0, 0, 0);

    $maxthreads = $1 if $webcontent =~ /MaxThreads=(\d+)/mi ;
    $minsparethreads = $1 if $webcontent =~ /MinSpareThreads=(\d+)/mi ;
    $maxsparethreads = $1 if $webcontent =~ /MaxSpareThreads=(\d+)/mi ;
    $maxqueuesize = $1 if $webcontent =~ /MaxQueueSize=(\d+)/mi ;
    $idletimeout = $1 if $webcontent =~ /IdleTimeout=(\d+)/mi ;
    $processedcount = $1 if $webcontent =~ /ProcessedCount=(\d+)/mi ;
    $currentthreadcount = $1 if $webcontent =~ /CurrentThreadCount=(\d+)/mi ;
    $availablethreadcount = $1 if $webcontent =~ /AvailableThreadCount=(\d+)/mi ;
    $busythreadcount = $1 if $webcontent =~ /BusyThreadCount=(\d+)/mi ;
    $maxavailablethreadcount = $1 if $webcontent =~ /MaxAvailableThreadCount=(\d+)/mi ;
    $maxbusythreadcount = $1 if $webcontent =~ /MaxBusyThreadCount=(\d+)/mi ;
    $maxprocessedtime = $1 if $webcontent =~ /MaxProcessedTime=(\d+)/mi ;
    $createcount = $1 if $webcontent =~ /CreateCount=(\d+)/mi ;
    $destroycount = $1 if $webcontent =~ /DestroyCount=(\d+)/mi ;
        
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("MaxThreads: %d", $maxthreads));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("MinSpareThreads: %d", $minsparethreads));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("MaxSpareThreads: %d", $maxsparethreads));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("MaxQueueSize: %d", $maxqueuesize));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("IdleTimeout: %ds", $idletimeout));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("ProcessedCount: %d", $processedcount));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("CurrentThreadCount: %d", $currentthreadcount));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("AvailableThreadCount: %d", $availablethreadcount));
    
    my $exit = $self->{perfdata}->threshold_check(value => $busythreadcount, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit, short_msg => sprintf("BusyThreadCount: %d", $busythreadcount));

    $self->{output}->output_add(severity => "ok", short_msg => sprintf("MaxAvailableThreadCount: %d", $maxavailablethreadcount));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("MaxBusyThreadCount: %d", $maxbusythreadcount));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("MaxProcessedTime: %dms", $maxprocessedtime));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("CreateCount: %d", $createcount));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("DestroyCount: %d", $destroycount));

    $self->{output}->perfdata_add(label => "MaxThreads", unit => '',
                                  value => sprintf("%d", $maxthreads),
                                  );
    $self->{output}->perfdata_add(label => "MinSpareThreads", unit => '',
                                  value => sprintf("%d", $minsparethreads),
                                  );
    $self->{output}->perfdata_add(label => "MaxSpareThreads", unit => '',
                                  value => sprintf("%d", $maxsparethreads),
                                  );
    $self->{output}->perfdata_add(label => "MaxQueueSize", unit => '',
                                  value => sprintf("%d", $maxqueuesize),
                                  );
    $self->{output}->perfdata_add(label => "IdleTimeout", unit => 's',
                                  value => sprintf("%d", $idletimeout),
                                  );
    $self->{output}->perfdata_add(label => "c[ProcessedCount]", unit => '',
                                  value => sprintf("%d", $processedcount),
                                  );
    $self->{output}->perfdata_add(label => "CurrentThreadCount", unit => '',
                                  value => sprintf("%d", $currentthreadcount),
                                  );
    $self->{output}->perfdata_add(label => "AvailableThreadCount", unit => '',
                                  value => sprintf("%d", $availablethreadcount),
                                  );

    $self->{output}->perfdata_add(label => "BusyThreadCount", unit => '',
                                  value => sprintf("%d", $busythreadcount),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  );
                                  
    $self->{output}->perfdata_add(label => "MaxAvailableThreadCount", unit => '',
                                  value => sprintf("%d", $maxavailablethreadcount),
                                  );
    $self->{output}->perfdata_add(label => "MaxBusyThreadCount", unit => '',
                                  value => sprintf("%d", $maxbusythreadcount),
                                  );
    $self->{output}->perfdata_add(label => "MaxProcessedTime", unit => 'ms',
                                  value => sprintf("%d", $maxprocessedtime),
                                  );
    $self->{output}->perfdata_add(label => "c[CreateCount]", unit => '',
                                  value => sprintf("%d", $createcount),
                                  );
    $self->{output}->perfdata_add(label => "c[DestroyCount]", unit => '',
                                  value => sprintf("%d", $destroycount),
                                  );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check EAS instance httphandler(Apusic) threads pool status.

=over 8

=item B<--urlpath>

Set path to get status page. (Default: '/easportal/tools/nagios/checkhttphandler.jsp')

=item B<--warning>

Warning Threshold for busy thread count.

=item B<--critical>

Critical Threshold for busy thread count.

=back

=cut
