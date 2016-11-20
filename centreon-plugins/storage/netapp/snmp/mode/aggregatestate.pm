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

package storage::netapp::snmp::mode::aggregatestate;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $thresholds = {
    state => [
        ['online', 'OK'],
        ['offline', 'CRITICAL'],
    ],
    status => [
        ['normal', 'OK'],
        ['mirrored', 'OK'],
        ['.*', 'CRITICAL'],
    ],
};
my $instance_mode;

my $maps_counters = {
    agg => {
        '000_state'   => { set => {
                        key_values => [ { name => 'aggrState' } ],
                        closure_custom_calc => \&custom_state_calc,
                        output_template => "State : '%s'", output_error_template => "State : '%s'",
                        output_use => 'aggrState',
                        closure_custom_perfdata => sub { return 0; },
                        closure_custom_threshold_check => \&custom_state_threshold,
                    }
               },
        '001_status'   => { set => {
                        key_values => [ { name => 'aggrStatus' } ],
                        closure_custom_calc => \&custom_status_calc,
                        output_template => "Status : '%s'", output_error_template => "Status : '%s'",
                        output_use => 'aggrStatus',
                        closure_custom_perfdata => sub { return 0; },
                        closure_custom_threshold_check => \&custom_status_threshold,
                    }
               },
        },
};

sub custom_state_threshold {
    my ($self, %options) = @_;
    
    return $instance_mode->get_severity(section => 'state', value => $self->{result_values}->{aggrState});
}

sub custom_state_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{aggrState} = $options{new_datas}->{$self->{instance} . '_aggrState'};
    return 0;
}

sub custom_status_threshold {
    my ($self, %options) = @_;
    
    return $instance_mode->get_severity(section => 'status', value => $self->{result_values}->{aggrStatus});
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{aggrStatus} = $options{new_datas}->{$self->{instance} . '_aggrStatus'};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-name:s"  => { name => 'filter_name' },
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                });
 
    foreach my $key (('agg')) {
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
    
    foreach my $key (('agg')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }
    
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
    $self->{snmp} = $options{snmp};
    
    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{agg}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All aggregates status are ok');
    }
    
    foreach my $id (sort keys %{$self->{agg}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (sort keys %{$maps_counters->{agg}}) {
            my $obj = $maps_counters->{agg}->{$_}->{obj};
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(values => $self->{agg}->{$id});

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
            
            $maps_counters->{agg}->{$_}->{obj}->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "Aggregate '$self->{agg}->{$id}->{aggrName}' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Aggregate '$self->{agg}->{$id}->{aggrName}' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "Aggregate '$self->{agg}->{$id}->{aggrName}' Usage $long_msg");
        }
    }
    
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

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_aggrName = '.1.3.6.1.4.1.789.1.5.11.1.2';
    my $oid_aggrState = '.1.3.6.1.4.1.789.1.5.11.1.5';
    my $oid_aggrStatus = '.1.3.6.1.4.1.789.1.5.11.1.6';
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_aggrName },
                                                            { oid => $oid_aggrState },
                                                            { oid => $oid_aggrStatus },
                                                         ],
                                                         , nothing_quit => 1);
    
    $self->{agg} = {};
    foreach my $oid (keys %{$self->{results}->{$oid_aggrState}}) {
        next if ($oid !~ /^$oid_aggrState\.(.*)$/);
        my $instance = $1;
        my $name = $self->{results}->{$oid_aggrName}->{$oid_aggrName . '.' . $instance};
        my $state = $self->{results}->{$oid_aggrState}->{$oid_aggrState . '.' . $instance};
        my $status = $self->{results}->{$oid_aggrStatus}->{$oid_aggrStatus . '.' . $instance};
        
        if (!defined($state) || $state eq '') {
            $self->{output}->output_add(long_msg => "Skipping  '" . $name . "': state value not set.");
            next;
        } 
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $name . "': no matching filter name.");
            next;
        }
        
        $self->{agg}->{$instance} = { aggrName => $name, aggrState => $state, aggrStatus => $status};
    }
    
    if (scalar(keys %{$self->{agg}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No aggregate found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check state and status from aggregates.

=over 8

=item B<--filter-name>

Filter by aggregate name.

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='state,CRITICAL,^(?!(online)$)'

=back

=cut
