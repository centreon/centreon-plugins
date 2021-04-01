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
# Author : CHEN JUN , aladdin.china@gmail.com

package apps::kingdee::eas::mode::handlers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'handlers', type => 1, cb_prefix_output => 'prefix_handler_output', message_multiple => 'All handlers are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{handlers} = [
        { label => 'threads-max', nlabel => 'handler.threads.max.count', display_ok => 0, set => {
                key_values => [ { name => 'maxthreads' } ],
                output_template => 'threads max: %s',
                perfdatas => [
                    { value => 'maxthreads', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'threads-spare-min', nlabel => 'handler.threads.spare.min.count', display_ok => 0, set => {
                key_values => [ { name => 'minsparethreads' } ],
                output_template => 'threads spare min: %s',
                perfdatas => [
                    { value => 'minsparethreads', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'threads-spare-max', nlabel => 'handler.threads.spare.max.count', display_ok => 0, set => {
                key_values => [ { name => 'maxsparethreads' } ],
                output_template => 'threads spare max: %s',
                perfdatas => [
                    { value => 'maxsparethreads', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'queue-size-max', nlabel => 'handler.queue.size.max.count', display_ok => 0, set => {
                key_values => [ { name => 'maxqueuesize' } ],
                output_template => 'max queue size: %s',
                perfdatas => [
                    { value => 'maxqueuesize', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'idle-timeout', nlabel => 'handler.idle.timeout.count', display_ok => 0, set => {
                key_values => [ { name => 'idle_timeout' } ],
                output_template => 'idle timeout: %s',
                perfdatas => [
                    { value => 'idle_timeout', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'threads-processed', nlabel => 'handler.threads.processed.count', display_ok => 0, set => {
                key_values => [ { name => 'processedcount', diff => 1 } ],
                output_template => 'threads processed: %s',
                perfdatas => [
                    { value => 'processedcount', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'threads-current', nlabel => 'handler.threads.current.count', set => {
                key_values => [ { name => 'currentthreadcount' } ],
                output_template => 'threads current: %s',
                perfdatas => [
                    { value => 'currentthreadcount', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'threads-current', nlabel => 'handler.threads.current.count', set => {
                key_values => [ { name => 'currentthreadcount' } ],
                output_template => 'threads current: %s',
                perfdatas => [
                    { value => 'currentthreadcount', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'threads-available', nlabel => 'handler.threads.available.count', set => {
                key_values => [ { name => 'availablethreadcount' } ],
                output_template => 'threads available: %s',
                perfdatas => [
                    { value => 'availablethreadcount', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'threads-busy', nlabel => 'handler.threads.busy.count', set => {
                key_values => [ { name => 'busythreadcount' } ],
                output_template => 'threads busy: %s',
                perfdatas => [
                    { value => 'busythreadcount', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'threads-available-max', nlabel => 'handler.threads.available.max.count', display_ok => 0, set => {
                key_values => [ { name => 'maxavailablethreadcount' } ],
                output_template => 'threads available max: %s',
                perfdatas => [
                    { value => 'maxavailablethreadcount', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'threads-busy-max', nlabel => 'handler.threads.busy.max.count', display_ok => 0, set => {
                key_values => [ { name => 'maxbusythreadcount' } ],
                output_template => 'threads busy max: %s',
                perfdatas => [
                    { value => 'maxbusythreadcount', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'threads-processedtime-max', nlabel => 'handler.threads.processedtime.max.milliseconds', display_ok => 0, set => {
                key_values => [ { name => 'maxprocessedtime' } ],
                output_template => 'threads processed time max: %s ms',
                perfdatas => [
                    { value => 'maxprocessedtime', template => '%s', min => 0, unit => 'ms', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'threads-created', nlabel => 'handler.threads.created.count', display_ok => 0, set => {
                key_values => [ { name => 'createcount' } ],
                output_template => 'threads created: %s',
                perfdatas => [
                    { value => 'createcount', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'threads-destroyed', nlabel => 'handler.threads.destroyed.count', display_ok => 0, set => {
                key_values => [ { name => 'destroycount' } ],
                output_template => 'threads destroyed: %s',
                perfdatas => [
                    { value => 'destroycount', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub prefix_handler_output {
    my ($self, %options) = @_;

    return "Handler '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options( arguments => {
        'urlpath-httphandler:s' => { name => 'url_path_httphandler', default => "/easportal/tools/nagios/checkhttphandler.jsp" },
        'urlpath-muxhandler:s'  => { name => 'url_path_muxhandler', default => "/easportal/tools/nagios/checkmuxhandler.jsp" },
        'filter-handler:s'      => { name => 'filter_handler' },
    });

    return $self;
}

sub manager_handler {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{filter_handler}) && $self->{option_results}->{filter_handler} ne "" &&
        $options{name} !~ /$self->{option_results}->{filter_handler}/
    ) {
        return undef;
    }

    my $webcontent = $options{custom}->request(path => $self->{option_results}->{'url_path_' . $options{name} . 'handler'});
    if ($webcontent !~ /MaxThreads=\d+/i) {
        $self->{output}->add_option_msg(short_msg => 'Cannot find ' . $options{name} . 'handler status in response');
        $self->{output}->option_exit();
    }

    $self->{handlers}->{$options{name}} = { display => $options{name} };
    $self->{handlers}->{$options{name}}->{maxthreads} = $1 if ($webcontent =~ /MaxThreads=(\d+)/mi);
    $self->{handlers}->{$options{name}}->{minsparethreads} = $1 if $webcontent =~ /MinSpareThreads=(\d+)/mi ;
    $self->{handlers}->{$options{name}}->{maxsparethreads} = $1 if $webcontent =~ /MaxSpareThreads=(\d+)/mi ;
    $self->{handlers}->{$options{name}}->{maxqueuesize} = $1 if $webcontent =~ /MaxQueueSize=(\d+)/mi ;
    $self->{handlers}->{$options{name}}->{idle_timeout} = $1 if $webcontent =~ /IdleTimeout=(\d+)/mi ;
    $self->{handlers}->{$options{name}}->{processedcount} = $1 if $webcontent =~ /ProcessedCount=(\d+)/mi ;
    $self->{handlers}->{$options{name}}->{currentthreadcount} = $1 if $webcontent =~ /CurrentThreadCount=(\d+)/mi ;
    $self->{handlers}->{$options{name}}->{availablethreadcount} = $1 if $webcontent =~ /AvailableThreadCount=(\d+)/mi ;
    $self->{handlers}->{$options{name}}->{busythreadcount} = $1 if $webcontent =~ /BusyThreadCount=(\d+)/mi ;
    $self->{handlers}->{$options{name}}->{maxavailablethreadcount} = $1 if $webcontent =~ /MaxAvailableThreadCount=(\d+)/mi ;
    $self->{handlers}->{$options{name}}->{maxbusythreadcount} = $1 if $webcontent =~ /MaxBusyThreadCount=(\d+)/mi ;
    $self->{handlers}->{$options{name}}->{maxprocessedtime} = $1 if $webcontent =~ /MaxProcessedTime=(\d+)/mi ;
    $self->{handlers}->{$options{name}}->{createcount} = $1 if $webcontent =~ /CreateCount=(\d+)/mi ;
    $self->{handlers}->{$options{name}}->{destroycount} = $1 if $webcontent =~ /DestroyCount=(\d+)/mi ;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{handlers} = {};
    $self->manager_handler(custom => $options{custom}, name => 'http');
    $self->manager_handler(custom => $options{custom}, name => 'mux');

    $self->{cache_name} = 'kingdee_' . $self->{mode} . '_' . $options{custom}->get_hostname() . '_' . $options{custom}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_handler}) ? md5_hex($self->{option_results}->{filter_handler}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check EAS instance handlers (http and mux).

=over 8

=item B<--urlpath-httphandler>

Set path to get status page. (Default: '/easportal/tools/nagios/checkhttphandler.jsp')

=item B<--urlpath-muxhandler>

Set path to get status page. (Default: '/easportal/tools/nagios/checkmuxhandler.jsp')

=item B<--filter-handler>

Handler filter (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'threads-max', 'threads-spare-min', 'threads-spare-max', 'queue-size-max'
'idle-timeout', 'threads-processed', 'threads-current', 'threads-current', 
'threads-available', 'threads-busy', 'threads-available-max', 'threads-busy-max',
'threads-processedtime-max', 'threads-created', 'threads-destroyed'.

=back

=cut
