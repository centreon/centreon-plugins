#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package centreon::common::force10::snmp::mode::cpu;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $instance_mode;

my $maps_counters = {
    cpu => {
        '000_5s'   => {
            set => {
                key_values => [ { name => 'usage_5s' }, { name => 'display' } ],
                output_template => '%s %% (5sec)', output_error_template => "%s (5sec)",
                perfdatas => [
                    { label => 'cpu_5s', value => 'usage_5s_absolute', template => '%d',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            },
        },
        '001_1m'   => {
            set => {
                key_values => [ { name => 'usage_1m' }, { name => 'display' } ],
                output_template => '%s %% (1m)', output_error_template => "%s (1min)",
                perfdatas => [
                    { label => 'cpu_1m', value => 'usage_1m_absolute', template => '%d',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            },
        },
        '002_5m'   => {
            set => {
                key_values => [ { name => 'usage_5m' }, { name => 'display' } ],
                output_template => '%s %% (5min)', output_error_template => "%s (5min)",
                perfdatas => [
                    { label => 'cpu_5m', value => 'usage_5m_absolute', template => '%d',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            },
        },
    }
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                });
                                
    foreach my $key (('cpu')) {
        foreach (keys %{$maps_counters->{$key}}) {
            my ($id, $name) = split /_/;
            if (!defined($maps_counters->{$key}->{$_}->{threshold}) || $maps_counters->{$key}->{$_}->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                            'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                            'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                               });
            }
            $maps_counters->{$key}->{$_}->{obj} = centreon::plugins::values->new(output => $self->{output}, perfdata => $self->{perfdata},
                                                      label => $name);
            $maps_counters->{$key}->{$_}->{obj}->set(%{$maps_counters->{$key}->{$_}->{set}});
        }
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach my $key (('cpu')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }
    $instance_mode = $self;
}

sub run_instances {
    my ($self, %options) = @_;
    
    my $multiple = 1;
    if (scalar(keys %{$self->{cpu}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All CPU usages are ok');
    }
    
    foreach my $id (sort keys %{$self->{cpu}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (sort keys %{$maps_counters->{cpu}}) {
            my $obj = $maps_counters->{cpu}->{$_}->{obj};
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(values => $self->{cpu}->{$id});

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

        my $prefix = "CPU Usage ";
        if ($multiple == 1) {
            $prefix = sprintf("CPU '%s' Usage ", $self->{cpu}->{$id}->{display});
        }
        $self->{output}->output_add(long_msg => "${prefix}$long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "${prefix}$short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "${prefix}$long_msg");
        }
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    $self->run_instances();
     
    $self->{output}->display();
    $self->{output}->exit();
}

my $mapping = {
    sseries => {
        Util5Sec    => { oid => '.1.3.6.1.4.1.6027.3.10.1.2.9.1.2' },
        Util1Min    => { oid => '.1.3.6.1.4.1.6027.3.10.1.2.9.1.3' },
        Util5Min    => { oid => '.1.3.6.1.4.1.6027.3.10.1.2.9.1.4' },
    },
    mseries => {
        Util5Sec    => { oid => '.1.3.6.1.4.1.6027.3.19.1.2.8.1.2' },
        Util1Min    => { oid => '.1.3.6.1.4.1.6027.3.19.1.2.8.1.3' },
        Util5Min    => { oid => '.1.3.6.1.4.1.6027.3.19.1.2.8.1.4' },
    },
    zseries => {
        Util5Sec    => { oid => '.1.3.6.1.4.1.6027.3.25.1.2.3.1.1' },
        Util1Min    => { oid => '.1.3.6.1.4.1.6027.3.25.1.2.3.1.2' },
        Util5Min    => { oid => '.1.3.6.1.4.1.6027.3.25.1.2.3.1.3' },
    },
};

sub manage_selection {
    my ($self, %options) = @_;
    
    my $oids = { sseries => '.1.3.6.1.4.1.6027.3.10.1.2.9.1', mseries => '.1.3.6.1.4.1.6027.3.19.1.2.8.1', zseries => '.1.3.6.1.4.1.6027.3.25.1.2.3.1' };
    my $results = $options{snmp}->get_multiple_table(oids => [ { oid => $oids->{sseries} }, { oid => $oids->{mseries} }, { oid => $oids->{zseries} } ], 
                                                    nothing_quit => 1);
    $self->{cpu} = {};
    foreach my $name (keys %{$oids}) {
        foreach my $oid (keys %{$results->{$oids->{$name}}}) {
            next if ($oid !~ /^$mapping->{$name}->{Util5Min}->{oid}\.(.*)/);
            my $instance = $1;
            my $result = $options{snmp}->map_instance(mapping => $mapping->{$name}, results => $results->{$oids->{$name}}, instance => $instance);
        
            $self->{cpu}->{$instance} = { display => $instance, 
                                          usage_5s => $result->{Util5Sec},
                                          usage_1m => $result->{Util1Min},
                                          usage_5m => $result->{Util5Min},
                                        };
        }
    }
    
    if (scalar(keys %{$self->{cpu}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check cpu usages.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: '5s', '1m', '5m'.

=item B<--critical-*>

Threshold critical.
Can be: '5s', '1m', '5m'.

=back

=cut
