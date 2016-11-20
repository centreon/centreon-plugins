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

package storage::netapp::snmp::mode::cpstatistics;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use centreon::plugins::values;

my $maps_counters = {
    timer   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'timer', diff => 1 }, ],
                        output_template => 'CP timer : %s',
                        perfdatas => [
                            { value => 'timer_absolute', template => '%d', min => 0 },
                        ],
                    }
               },
    snapshot   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'snapshot', diff => 1 }, ],
                        output_template => 'CP snapshot : %s',
                        perfdatas => [
                            { value => 'snapshot_absolute', template => '%d', min => 0 },
                        ],
                    }
               },
    lowerwater   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'lowerwater', diff => 1 }, ],
                        output_template => 'CP low water mark : %s',
                        perfdatas => [
                            { value => 'lowerwater_absolute', template => '%d', min => 0 },
                        ],
                    }
               },
    highwater   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'highwater', diff => 1 }, ],
                        output_template => 'CP high water mark : %s',
                        perfdatas => [
                            { value => 'highwater_absolute', template => '%d', min => 0 },
                        ],
                    }
               },
    logfull   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'logfull', diff => 1 }, ],
                        output_template => 'CP nv-log full : %s',
                        perfdatas => [
                            { value => 'logfull_absolute', template => '%d', min => 0 },
                        ],
                    }
               },
    back   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'back', diff => 1 }, ],
                        output_template => 'CP back-to-back : %s',
                        perfdatas => [
                            { value => 'back_absolute', template => '%d', min => 0 },
                        ],
                    }
               },
    flush   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'flush', diff => 1 }, ],
                        output_template => 'CP flush unlogged write data : %s',
                        perfdatas => [
                            { value => 'flush_absolute', template => '%d', min => 0 },
                        ],
                    }
               },
    sync   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'sync', diff => 1 }, ],
                        output_template => 'CP sync requests : %s',
                        perfdatas => [
                            { value => 'sync_absolute', template => '%d', min => 0 },
                        ],
                    }
               },
    lowvbuf   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'lowvbuf', diff => 1 }, ],
                        output_template => 'CP low virtual buffers : %s',
                        perfdatas => [
                            { value => 'lowvbuf_absolute', template => '%d', min => 0 },
                        ],
                    }
               },
    deferred   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'deferred', diff => 1 }, ],
                        output_template => 'CP deferred : %s',
                        perfdatas => [
                            { value => 'deferred_absolute', template => '%d', min => 0 },
                        ],
                    }
               },
    lowdatavecs   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'lowdatavecs', diff => 1 }, ],
                        output_template => 'CP low datavecs : %s',
                        perfdatas => [
                            { value => 'lowdatavecs_absolute', template => '%d', min => 0 },
                        ],
                    }
               },
};

my $oid_cpFromTimerOps = '.1.3.6.1.4.1.789.1.2.6.2.0';
my $oid_cpFromSnapshotOps = '.1.3.6.1.4.1.789.1.2.6.3.0';
my $oid_cpFromLowWaterOps = '.1.3.6.1.4.1.789.1.2.6.4.0';
my $oid_cpFromHighWaterOps = '.1.3.6.1.4.1.789.1.2.6.5.0';
my $oid_cpFromLogFullOps = '.1.3.6.1.4.1.789.1.2.6.6.0';
my $oid_cpFromCpOps = '.1.3.6.1.4.1.789.1.2.6.7.0';
my $oid_cpTotalOps = '.1.3.6.1.4.1.789.1.2.6.8.0';
my $oid_cpFromFlushOps = '.1.3.6.1.4.1.789.1.2.6.9.0';
my $oid_cpFromSyncOps = '.1.3.6.1.4.1.789.1.2.6.10.0';
my $oid_cpFromLowVbufOps = '.1.3.6.1.4.1.789.1.2.6.11.0';
my $oid_cpFromCpDeferredOps = '.1.3.6.1.4.1.789.1.2.6.12.0';
my $oid_cpFromLowDatavecsOps = '.1.3.6.1.4.1.789.1.2.6.13.0';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });

    $self->{statefile_value} = centreon::plugins::statefile->new(%options);  
    foreach (keys %{$maps_counters}) {
        $options{options}->add_options(arguments => {
                                                     'warning-' . $_ . ':s'    => { name => 'warning-' . $_ },
                                                     'critical-' . $_ . ':s'    => { name => 'critical-' . $_ },
                                      });
        my $class = $maps_counters->{$_}->{class};
        $maps_counters->{$_}->{obj} = $class->new(statefile => $self->{statefile_value},
                                                  output => $self->{output}, perfdata => $self->{perfdata},
                                                  label => $_);
        $maps_counters->{$_}->{obj}->set(%{$maps_counters->{$_}->{set}});
    }
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach (keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->init(option_results => $self->{option_results});
    }
    
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();

    $self->manage_selection();
    
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => "cache_netapp_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    $self->{new_datas}->{last_timestamp} = time();
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All CP statistics are ok');
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->set(instance => 'global');
    
        my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{global},
                                                                 new_datas => $self->{new_datas});

        if ($value_check != 0) {
            $long_msg .= $long_msg_append . $maps_counters->{$_}->{obj}->output_error();
            $long_msg_append = ', ';
            next;
        }
        my $exit2 = $maps_counters->{$_}->{obj}->threshold_check();
        push @exits, $exit2;

        my $output = $maps_counters->{$_}->{obj}->output();
        $long_msg .= $long_msg_append . $output;
        $long_msg_append = ', ';
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
            $short_msg .= $short_msg_append . $output;
            $short_msg_append = ', ';
        }
        
        $self->{output}->output_add(long_msg => $output);
        $maps_counters->{$_}->{obj}->perfdata();
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => "$short_msg"
                                    );
    }
    
    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $request = [$oid_cpFromTimerOps, $oid_cpFromSnapshotOps,
                   $oid_cpFromLowWaterOps, $oid_cpFromHighWaterOps,
                   $oid_cpFromLogFullOps, $oid_cpFromCpOps,
                   $oid_cpTotalOps, $oid_cpFromFlushOps,
                   $oid_cpFromSyncOps, $oid_cpFromLowVbufOps,
                   $oid_cpFromCpDeferredOps, $oid_cpFromLowDatavecsOps];
    
    $self->{results} = $self->{snmp}->get_leef(oids => $request, nothing_quit => 1);
    
    $self->{global} = {};
    $self->{global}->{timer} = defined($self->{results}->{$oid_cpFromTimerOps}) ? $self->{results}->{$oid_cpFromTimerOps} : 0;
    $self->{global}->{snapshot} = defined($self->{results}->{$oid_cpFromSnapshotOps}) ? $self->{results}->{$oid_cpFromSnapshotOps} : 0;
    $self->{global}->{lowerwater} = defined($self->{results}->{$oid_cpFromLowWaterOps}) ? $self->{results}->{$oid_cpFromLowWaterOps} : 0;
    $self->{global}->{highwater} = defined($self->{results}->{$oid_cpFromHighWaterOps}) ? $self->{results}->{$oid_cpFromHighWaterOps} : 0;
    $self->{global}->{logfull} = defined($self->{results}->{$oid_cpFromLogFullOps}) ? $self->{results}->{$oid_cpFromLogFullOps} : 0;
    $self->{global}->{back} = defined($self->{results}->{$oid_cpFromCpOps}) ? $self->{results}->{$oid_cpFromCpOps} : 0;
    $self->{global}->{flush} = defined($self->{results}->{$oid_cpFromFlushOps}) ? $self->{results}->{$oid_cpFromFlushOps} : 0;
    $self->{global}->{sync} = defined($self->{results}->{$oid_cpFromSyncOps}) ? $self->{results}->{$oid_cpFromSyncOps} : 0;
    $self->{global}->{lowvbuf} = defined($self->{results}->{$oid_cpFromLowVbufOps}) ? $self->{results}->{$oid_cpFromLowVbufOps} : 0;
    $self->{global}->{deferred} = defined($self->{results}->{$oid_cpFromCpDeferredOps}) ? $self->{results}->{$oid_cpFromCpDeferredOps} : 0;
    $self->{global}->{lowdatavecs} = defined($self->{results}->{$oid_cpFromLowDatavecsOps}) ? $self->{results}->{$oid_cpFromLowDatavecsOps} : 0;
}

1;

__END__

=head1 MODE

Check consistency point metrics.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'timer', 'snapshot', 'lowerwater', 'highwater', 
'logfull', 'back', 'flush', 'sync', 'lowvbuf', 'deferred', 'lowdatavecs'.

=item B<--critical-*>

Threshold critical.
Can be: 'timer', 'snapshot', 'lowerwater', 'highwater', 
'logfull', 'back', 'flush', 'sync', 'lowvbuf', 'deferred', 'lowdatavecs'.

=back

=cut
    