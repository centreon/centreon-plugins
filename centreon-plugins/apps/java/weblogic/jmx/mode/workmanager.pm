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

package apps::java::weblogic::jmx::mode::workmanager;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my $thresholds = {
    health => [
        ['HEALTH_OK', 'OK'],
        ['HEALTH_WARNING', 'WARNING'],
        ['HEALTH_CRITICAL', 'CRITICAL'],
        ['HEALTH_FAILED', 'CRITICAL'],
        ['HEALTH_OVERLOADED', 'CRITICAL'],
        ['LOW_MEMORY_REASON', 'CRITICAL'],
    ],
};
my $instance_mode;

my $maps_counters = {
    runtime => { 
        '000_status'   => { set => {
                        key_values => [ { name => 'health_state' } ],
                        closure_custom_calc => \&custom_status_calc,
                        output_template => 'State : %s', output_error_template => 'State : %s',
                        output_use => 'health_state',
                        closure_custom_perfdata => sub { return 0; },
                        closure_custom_threshold_check => \&custom_threshold_output,
                    }
               },
        
        '001_request-completed' => { set => {
                        key_values => [ { name => 'completed', diff => 1 }, { name => 'runtime' } ],
                        output_template => 'Requests completed : %s',
                        perfdatas => [
                            { label => 'request_completed', value => 'completed_absolute', template => '%s',
                              min => 0, label_extra_instance => 1, instance_use => 'runtime_absolute' },
                        ],
                    }
               },
        '002_request-pending' => { set => {
                        key_values => [ { name => 'pending' }, { name => 'runtime' } ],
                        output_template => 'Requests pending : %s',
                        perfdatas => [
                            { label => 'request_pending', value => 'pending_absolute', template => '%s',
                              min => 0, label_extra_instance => 1, instance_use => 'runtime_absolute' },
                        ],
                    }
               },
        '003_thread-stuck' => { set => {
                        key_values => [ { name => 'stuck' }, { name => 'runtime' } ],
                        output_template => 'Threads stuck : %s',
                        perfdatas => [
                            { label => 'thread_stuck', value => 'stuck_absolute', template => '%s',
                              min => 0, label_extra_instance => 1, instance_use => 'runtime_absolute' },
                        ],
                    }
               }, 
    },
};

sub custom_threshold_output {
    my ($self, %options) = @_;
    
    return $instance_mode->get_severity(section => 'health', value => $self->{result_values}->{health_state});
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{health_state} = $options{new_datas}->{$self->{instance} . '_health_state'};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-application:s"    => { name => 'filter_application' },
                                  "filter-name:s"           => { name => 'filter_name' },
                                  "filter-runtime:s"        => { name => 'filter_runtime' },
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                });
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
 
    foreach my $key (('runtime')) {
        foreach (keys %{$maps_counters->{$key}}) {
            my ($id, $name) = split /_/;
            if (!defined($maps_counters->{$key}->{$_}->{threshold}) || $maps_counters->{$key}->{$_}->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                            'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                            'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                               });
            }
            $maps_counters->{$key}->{$_}->{obj} = centreon::plugins::values->new(
                                                      statefile => $self->{statefile_value},
                                                      output => $self->{output}, perfdata => $self->{perfdata},
                                                      label => $name);
            $maps_counters->{$key}->{$_}->{obj}->set(%{$maps_counters->{$key}->{$_}->{set}});
        }
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach my $key (('runtime')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }
    
    $self->{statefile_value}->check_options(%options);
    $instance_mode = $self;
    
    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{connector} = $options{custom};
    
    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{runtime}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All WorkerManagers are ok');
    }
    
    my $matching = '';
    foreach (('filter_application', 'filter_name', 'filter_runtime')) {
        $matching .= defined($self->{option_results}->{$_}) ? $self->{option_results}->{$_} : 'all';
    }
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => "weblogic_" . $self->{mode} . '_' .  md5_hex($self->{connector}->{url}) . '_' . md5_hex($matching));
    $self->{new_datas}->{last_timestamp} = time();
    
    foreach my $id (sort keys %{$self->{runtime}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (sort keys %{$maps_counters->{runtime}}) {
            my $obj = $maps_counters->{runtime}->{$_}->{obj};
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(values => $self->{runtime}->{$id},
                                              new_datas => $self->{new_datas});

            if ($value_check != 0) {
                $long_msg .= $long_msg_append . $obj->output_error();
                $long_msg_append = ', ';
                next;
            }
            my $exit2 = $obj->threshold_check();
            push @exits, $exit2;

            my $output = $obj->output();
            $long_msg .= $long_msg_append . $output;
            $long_msg_append = ', ';
            
            if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
                $short_msg .= $short_msg_append . $output;
                $short_msg_append = ', ';
            }
            
            $obj->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "WorkerManager '$id' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "WorkerManager '$id' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "WorkerManager '$id' $long_msg");
        }
    }

    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {           
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

my %map_state = (
    0 => 'HEALTH_OK',
    1 => 'HEALTH_WARNING',
    2 => 'HEALTH_CRITICAL',
    3 => 'HEALTH_FAILED',
    4 => 'HEALTH_OVERLOADED',
    5 => 'LOW_MEMORY_REASON',
);

sub manage_selection {
    my ($self, %options) = @_;

    $self->{request} = [
         { mbean => 'com.bea:ApplicationRuntime=*,Name=*,ServerRuntime=*,Type=WorkManagerRuntime', 
          attributes => [ { name => 'HealthState' }, { name => 'StuckThreadCount' }, { name => 'CompletedRequests' }, { name => 'PendingRequests' } ] }
    ];
    my $result = $self->{connector}->get_attributes(request => $self->{request}, nothing_quit => 1);
    
    $self->{runtime} = {};
    foreach my $mbean (keys %{$result}) { 
        next if ($mbean !~ /ApplicationRuntime=(.*?),Name=(.*?),ServerRuntime=(.*?),/);
        my ($app, $name, $runtime) = ($1, $2, $3);
        my $health_state = defined($map_state{$result->{$mbean}->{HealthState}->{state}}) ? 
                            $map_state{$result->{$mbean}->{HealthState}->{state}} : 'unknown';
        
        if (defined($self->{option_results}->{filter_application}) && $self->{option_results}->{filter_application} ne '' &&
            $app !~ /$self->{option_results}->{filter_application}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $app . "': no matching filter application.");
            next;
        }
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $name . "': no matching filter name.");
            next;
        }
        if (defined($self->{option_results}->{filter_runtime}) && $self->{option_results}->{filter_runtime} ne '' &&
            $runtime !~ /$self->{option_results}->{filter_runtime}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $runtime . "': no matching filter runtime.");
            next;
        }
        
        $self->{runtime}->{$app . '/' . $name . '/' . $runtime} = { health_state => $health_state, runtime => $app . '/' . $name . '/' . $runtime,
            completed => $result->{$mbean}->{CompletedRequests}, pending => $result->{$mbean}->{PendingRequests}, stuck => $result->{$mbean}->{StuckThreadCount} };
    }
    
    if (scalar(keys %{$self->{runtime}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check WebLogic WorkManagers.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'thread-stuck', 'request-completed', 'request-pending'.

=item B<--critical-*>

Threshold critical.
Can be: 'thread-stuck', 'request-completed', 'request-pending'.

=item B<--filter-application>

Filter by application runtime.

=item B<--filter-name>

Filter by name (regexp can be used).

=item B<--filter-runtime>

Filter by server runtime.

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='health,CRITICAL,^(?!(HEALTH_OK)$)'

=back

=cut
