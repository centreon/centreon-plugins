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

package network::citrix::netscaler::common::mode::vserverstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {
    status => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'state' },
                                      ],
                        closure_custom_calc => \&custom_status_calc,
                        closure_custom_output => \&custom_status_output,
                        closure_custom_perfdata => sub { return 0; },
                        closure_custom_threshold_check => \&custom_threshold_output,
                    }
               },
    health => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'health' }, { name => 'display' },
                                      ],
                        output_template => 'Health: %.2f %%', output_error_template => 'Health: %s',
                        output_use => 'health_absolute', threshold_use => 'health_absolute',
                        perfdatas => [
                            { value => 'health_absolute', label => 'health', template => '%.2f',
                              unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
};

my $overload_th = {};
my $oid_vsvrName = '.1.3.6.1.4.1.5951.4.1.3.1.1.1';
my $oid_vsvrState = '.1.3.6.1.4.1.5951.4.1.3.1.1.5';
my $oid_vsvrHealth = '.1.3.6.1.4.1.5951.4.1.3.1.1.62';
my $oid_vsvrEntityType = '.1.3.6.1.4.1.5951.4.1.3.1.1.64';

my $thresholds = {
    vs => [
        ['unknown', 'UNKNOWN'],
        ['down|outOfService|transitionToOutOfService|transitionToOutOfServiceDown', 'CRITICAL'],
        ['up', 'OK'],
    ],
};

my %map_vs_type = (
    0 => 'unknown', 
    1 => 'loadbalancing', 
    2 => 'loadbalancinggroup', 
    3 => 'sslvpn', 
    4 => 'contentswitching', 
    5 => 'cacheredirection',
);

my %map_vs_status = (
    1 => 'down', 
    2 => 'unknown', 
    3 => 'busy', 
    4 => 'outOfService', 
    5 => 'transitionToOutOfService', 
    7 => 'up',
    8 => 'transitionToOutOfServiceDown',
);

sub get_severity {
    my (%options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($overload_th->{$options{section}})) {
        foreach (@{$overload_th->{$options{section}}}) {            
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

sub custom_threshold_output {
    my ($self, %options) = @_;
    
    return get_severity(section => 'vs', value => $map_vs_status{$self->{result_values}->{state}});
}

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = 'State : ' . $map_vs_status{$self->{result_values}->{state}};

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "name:s"                => { name => 'name' },
                                  "regexp"                => { name => 'use_regexp' },
                                  "filter-type:s"         => { name => 'filter_type' },
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                });

    $self->{vs_id_selected} = {};
     
    foreach (keys %{$maps_counters}) {
        $options{options}->add_options(arguments => {
                                                     'warning-' . $_ . ':s'    => { name => 'warning-' . $_ },
                                                     'critical-' . $_ . ':s'    => { name => 'critical-' . $_ },
                                      });
        my $class = $maps_counters->{$_}->{class};
        $maps_counters->{$_}->{obj} = $class->new(output => $self->{output}, perfdata => $self->{perfdata},
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
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ('vs', $1, $2);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $overload_th->{$section} = [] if (!defined($overload_th->{$section}));
        push @{$overload_th->{$section}}, {filter => $filter, status => $status};
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{vs_id_selected}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All Virtual Servers are ok.');
    }
    
    foreach my $id (sort keys %{$self->{vs_id_selected}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits;
        foreach (sort keys %{$maps_counters}) {
            $maps_counters->{$_}->{obj}->set(instance => $id);
        
            my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{vs_id_selected}->{$id});

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
            
            $maps_counters->{$_}->{obj}->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "Virtual Server '" . $self->{vs_id_selected}->{$id}->{display} . "' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Virtual Server '" . $self->{vs_id_selected}->{$id}->{display} . "' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "Virtual Server '" . $self->{vs_id_selected}->{$id}->{display} . "' $long_msg");
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

sub add_result {
    my ($self, %options) = @_;
    
    $self->{vs_id_selected}->{$options{instance}} = {};
    $self->{vs_id_selected}->{$options{instance}}->{display} = $self->{results}->{$oid_vsvrName}->{$oid_vsvrName . '.' . $options{instance}};    
    $self->{vs_id_selected}->{$options{instance}}->{health} = $self->{results}->{$oid_vsvrHealth}->{$oid_vsvrHealth . '.' . $options{instance}};
    $self->{vs_id_selected}->{$options{instance}}->{state} = $self->{results}->{$oid_vsvrState}->{$oid_vsvrState . '.' . $options{instance}};
}

sub manage_selection {
    my ($self, %options) = @_;
 
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_vsvrName },
                                                            { oid => $oid_vsvrState },
                                                            { oid => $oid_vsvrHealth },
                                                            { oid => $oid_vsvrEntityType },
                                                         ],
                                                         , nothing_quit => 1);
 
    foreach my $oid (keys %{$self->{results}->{$oid_vsvrName}}) {
        $oid =~ /^$oid_vsvrName\.(.*)$/;
        my $instance = $1;
        my $filter_name = $self->{results}->{$oid_vsvrName}->{$oid}; 
        my $filter_type = $self->{results}->{$oid_vsvrEntityType}->{$oid_vsvrEntityType . '.' . $instance};
        
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $map_vs_type{$filter_type} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "Skipping Virtual Server '" . $filter_name . "'.");
            next;
        }
        if (!defined($self->{option_results}->{name})) {
            $self->add_result(instance => $instance);
            next;
        }
        if (!defined($self->{option_results}->{use_regexp}) && $filter_name eq $self->{option_results}->{name}) {
            $self->add_result(instance => $instance);
        }
        if (defined($self->{option_results}->{use_regexp}) && $filter_name =~ /$self->{option_results}->{name}/) {
            $self->add_result(instance => $instance);
        }
    }
    
    if (scalar(keys %{$self->{vs_id_selected}}) <= 0) {
        if (defined($self->{option_results}->{name})) {
            $self->{output}->add_option_msg(short_msg => "No Virtual Server found '" . $self->{option_results}->{name} . "'.");
        } else {
            $self->{output}->add_option_msg(short_msg => "No Virtual Server found.");
        }
        $self->{output}->option_exit();
    }    
}

1;

__END__

=head1 MODE

Check vservers status and health.

=over 8

=item B<--warning-health>

Threshold warning in percent.

=item B<--critical-health>

Threshold critical in percent.

=item B<--name>

Set the virtual server name.

=item B<--regexp>

Allows to use regexp to filter virtual server name (with option --name).

=item B<--filter-type>

Filter which type of vserver (can be a regexp).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='CRITICAL,^(?!(green)$)'

=back

=cut
