################################################################################
# Copyright 2005-2014 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package apps::java::weblogic::jmx::mode::health

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

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
                                  "filter-name:s"  => { name => 'filter_name' },
                                  "filter-runtime:s"  => { name => 'filter_runtime' },
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
    
    foreach my $key (('runtime')) {
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
    $self->{connector} = $options{custom};
    
    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{runtime}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All ServerRuntimes are ok');
    }
    
    foreach my $id (sort keys %{$self->{runtime}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (sort keys %{$maps_counters->{runtime}}) {
            my $obj = $maps_counters->{runtime}->{$_}->{obj};
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(values => $self->{runtime}->{$id});

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
            
            $maps_counters->{runtime}->{$_}->{obj}->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "ServerRuntime '$self->{runtime}->{$id}->{name}/$self->{runtime}->{$id}->{runtime}' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "ServerRuntime '$self->{runtime}->{$id}->{name}/$self->{runtime}->{$id}->{runtime}' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "ServerRuntime '$self->{runtime}->{$id}->{name}/$self->{runtime}->{$id}->{runtime}' $long_msg");
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
         { mbean => 'com.bea:ApplicationRuntime=bea_wls_deployment_internal,Name=*,ServerRuntime=*,Type=WorkManagerRuntime', attributes => [ { name => 'HealthState' } ] }
    ];
    my $result = $self->{connector}->get_attributes(request => $self->{request}, nothing_quit => 1);
    
    $self->{runtime} = {};
    foreach my $mbean (keys %{$result}) { 
        next if ($mbean !~ /Name=(.*?),ServerRuntime=(.*?),/);
        my ($name, $runtime) = ($1, $2);
        my $health_state = defined($map_state{$result->{$mbean}->{HealthState}->{state}}) ? 
                            $map_state{$result->{$mbean}->{HealthState}->{state}} : 'unknown';
        
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
        
        $self->{runtime}->{$name . $runtime} = { name => $name, runtime => $runtime, health_state => $state };
    }
    
    if (scalar(keys %{$self->{runtime}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check WebLogic Runtimes Health State.

=over 8

=item B<--filter-name>

Filter by name (regexp can be used).

=item B<--filter-runtime>

Filter by runtime.

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='health,CRITICAL,^(?!(mature)$)'

=back

=cut
