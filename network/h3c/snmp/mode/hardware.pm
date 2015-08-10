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

package network::h3c::snmp::mode::hardware;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;

my $thresholds = {
    psu => [
        ['notSupported', 'WARNING'],
        ['normal', 'OK'],
        ['entityAbsent', 'OK'],
        ['psuError', 'CRITICAL'],
        ['hardwareFaulty', 'CRITICAL'],
    ],
    fan => [
        ['notSupported', 'WARNING'],
        ['normal', 'OK'],
        ['entityAbsent', 'OK'],
        ['fanError', 'CRITICAL'],
        ['hardwareFaulty', 'CRITICAL'],
    ],
    sensor => [
        ['notSupported', 'WARNING'],
        ['normal', 'OK'],
        ['entityAbsent', 'OK'],
        ['sensorError', 'CRITICAL'],
        ['hardwareFaulty', 'CRITICAL'],
    ],
    other => [
        ['notSupported', 'WARNING'],
        ['normal', 'OK'],
        ['entityAbsent', 'OK'],
        ['hardwareFaulty', 'CRITICAL'],
    ],
    unknown => [
        ['notSupported', 'WARNING'],
        ['normal', 'OK'],
        ['entityAbsent', 'OK'],
        ['hardwareFaulty', 'CRITICAL'],
    ],
    chassis => [
        ['notSupported', 'WARNING'],
        ['normal', 'OK'],
        ['entityAbsent', 'OK'],
        ['hardwareFaulty', 'CRITICAL'],
    ],
    backplane => [
        ['notSupported', 'WARNING'],
        ['normal', 'OK'],
        ['entityAbsent', 'OK'],
        ['hardwareFaulty', 'CRITICAL'],
    ],
    container => [
        ['notSupported', 'WARNING'],
        ['normal', 'OK'],
        ['entityAbsent', 'OK'],
        ['hardwareFaulty', 'CRITICAL'],
    ],
    module => [
        ['notSupported', 'WARNING'],
        ['normal', 'OK'],
        ['entityAbsent', 'OK'],
        ['hardwareFaulty', 'CRITICAL'],
    ],
    port => [
        ['notSupported', 'WARNING'],
        ['normal', 'OK'],
        ['entityAbsent', 'OK'],
        ['hardwareFaulty', 'CRITICAL'],
    ],
    stack => [
        ['notSupported', 'WARNING'],
        ['normal', 'OK'],
        ['entityAbsent', 'OK'],
        ['hardwareFaulty', 'CRITICAL'],
    ],
    cpu => [
        ['notSupported', 'WARNING'],
        ['normal', 'OK'],
        ['entityAbsent', 'OK'],
        ['hardwareFaulty', 'CRITICAL'],
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "exclude:s"        => { name => 'exclude' },
                                  "absent-problem:s" => { name => 'absent' },
                                  "component:s"      => { name => 'component', default => '.*' },
                                  "no-component:s"   => { name => 'no_component' },
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                  "warning:s@"              => { name => 'warning' },
                                  "critical:s@"             => { name => 'critical' },
                                  "reload-cache-time:s"     => { name => 'reload_cache_time', default => 180 },
                                });

    $self->{components} = {};
    $self->{no_components} = undef;
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (defined($self->{option_results}->{no_component})) {
        if ($self->{option_results}->{no_component} ne '') {
            $self->{no_components} = $self->{option_results}->{no_component};
        } else {
            $self->{no_components} = 'critical';
        }
    }
    
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
    
    $self->{numeric_threshold} = {};
    foreach my $option (('warning', 'critical')) {
        foreach my $val (@{$self->{option_results}->{$option}}) {
            if ($val !~ /^(.*?),(.*?),(.*)$/) {
                $self->{output}->add_option_msg(short_msg => "Wrong $option option '" . $val . "'.");
                $self->{output}->option_exit();
            }
            my ($section, $regexp, $value) = ($1, $2, $3);
            if ($section !~ /^(temperature)$/) {
                $self->{output}->add_option_msg(short_msg => "Wrong $option option '" . $val . "' (type must be: temperature).");
                $self->{output}->option_exit();
            }
            my $position = 0;
            if (defined($self->{numeric_threshold}->{$section})) {
                $position = scalar(@{$self->{numeric_threshold}->{$section}});
            }
            if (($self->{perfdata}->threshold_validate(label => $option . '-' . $section . '-' . $position, value => $value)) == 0) {
                $self->{output}->add_option_msg(short_msg => "Wrong $option threshold '" . $value . "'.");
                $self->{output}->option_exit();
            }
            $self->{numeric_threshold}->{$section} = [] if (!defined($self->{numeric_threshold}->{$section}));
            push @{$self->{numeric_threshold}->{$section}}, { label => $option . '-' . $section . '-' . $position, threshold => $option, regexp => $regexp };
        }
    }
    
    $self->{statefile_cache}->check_options(%options);
}

my $oid_entPhysicalEntry = '.1.3.6.1.2.1.47.1.1.1.1';
my $oid_entPhysicalDescr = '.1.3.6.1.2.1.47.1.1.1.1.2';
my $oid_entPhysicalContainedIn = '.1.3.6.1.2.1.47.1.1.1.1.4';
my $oid_entPhysicalClass = '.1.3.6.1.2.1.47.1.1.1.1.5';
my $oid_entPhysicalName = '.1.3.6.1.2.1.47.1.1.1.1.7';

sub check_cache {
    my ($self, %options) = @_;

    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();
    
    # init cache file
    $self->{write_cache} = 0;
    my $has_cache_file = $self->{statefile_cache}->read(statefile => 'cache_h3c_entity_' . $self->{hostname}  . '_' . $self->{snmp_port});
    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');
    if ($has_cache_file == 0 ||
        !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($self->{option_results}->{reload_cache_time}) * 60))) {
        push @{$self->{snmp_request}}, { oid => $oid_entPhysicalEntry, start => $oid_entPhysicalDescr, end => $oid_entPhysicalName };
        $self->{write_cache} = 1;
    }
}

sub write_cache {
    my ($self, %options) = @_;
    
    if ($self->{write_cache} == 1) {
        my $datas = {};
        $datas->{last_timestamp} = time();
        $datas->{oids} = $self->{results}->{$oid_entPhysicalEntry};
        $self->{statefile_cache}->write(data => $datas);
    } else {
        $self->{results}->{$oid_entPhysicalEntry} = $self->{statefile_cache}->get(name => 'oids');
    }
}

sub get_long_name {
    my ($self, %options) = @_;
    
    my @names = ($self->{results}->{$oid_entPhysicalEntry}->{$oid_entPhysicalDescr . '.' . $options{instance}});
    my %loop = ($options{instance} => 1);
    my $child = $self->{results}->{$oid_entPhysicalEntry}->{$oid_entPhysicalContainedIn . '.' . $options{instance}};
    while (1) {
        last if (!defined($child) || defined($loop{$child}) || !defined($self->{results}->{$oid_entPhysicalEntry}->{$oid_entPhysicalDescr . '.' . $child}));
        
        unshift @names, $self->{results}->{$oid_entPhysicalEntry}->{$oid_entPhysicalDescr . '.' . $child};
        $loop{$child} = 1;
        $child = $self->{results}->{$oid_entPhysicalEntry}->{$oid_entPhysicalContainedIn . '.' . $child};
    }
    
    return join(' > ', @names);
}

sub get_instance_class {
    my ($self, %options) = @_;
     
    my @instances = ();
    foreach (keys %{$self->{results}->{$oid_entPhysicalEntry}}) {
        if (/^$oid_entPhysicalClass\.(\d+)/ && defined($options{class}->{$self->{results}->{$oid_entPhysicalEntry}->{$_}})) {
            push @instances, $1;
        }
    }

    return @instances;
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_hh3cEntityExtStateEntry = '.1.3.6.1.4.1.25506.2.6.1.1.1.1';
    my $oid_h3cEntityExtStateEntry = '.1.3.6.1.4.1.2011.10.2.6.1.1.1.1';
    my $oid_h3cEntityExtErrorStatus = '.1.3.6.1.4.1.2011.10.2.6.1.1.1.1.19';
    my $oid_hh3cEntityExtErrorStatus = '.1.3.6.1.4.1.25506.2.6.1.1.1.1.19';
    $self->{snmp_request} = [ 
                        { oid => $oid_h3cEntityExtErrorStatus },
                        { oid => $oid_hh3cEntityExtErrorStatus },
                       ];
    $self->check_cache();

    my %mapping_name = (
        1 => 'other', 2 => 'unknown', 3 => 'chassis', 4 => 'backplane', 5 => 'container', 6 => 'psu', 
        7 => 'fan', 8 => 'sensor', 9 => 'module', 10 => 'port', 11 => 'stack', 12 => 'cpu'
    );
    my %mapping_component = (
        1 => 'default', 2 => 'default', 3 => 'default', 4 => 'default', 5 => 'default', 6 => 'psu', 
        7 => 'fan', 8 => 'sensor', 9 => 'default', 10 => 'default', 11 => 'default', 12 => 'default'
    );
    
    my $component = 0;
    foreach (keys %mapping_name) {
        if ($mapping_name{$_} =~ /$self->{option_results}->{component}/) {
            my $mod_name = "network::h3c::snmp::mode::components::" . $mapping_component{$_};
            centreon::plugins::misc::mymodule_load(output => $self->{output}, module => $mod_name,
                                                   error_msg => "Cannot load module '$mod_name'.");
            $component = 1;
        }
    }
    if ($component == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong option. Cannot find component '" . $self->{option_results}->{component} . "'.");
        $self->{output}->option_exit();
    }
    
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{snmp_request});
    $self->write_cache();
    
    $self->{branch} = $oid_hh3cEntityExtStateEntry;
    if (defined($self->{results}->{$oid_h3cEntityExtErrorStatus}) && scalar(keys %{$self->{results}->{$oid_h3cEntityExtErrorStatus}}) > 0) {
        $self->{branch} = $oid_h3cEntityExtStateEntry;
    }
    
    foreach (keys %mapping_name) {
        if ($mapping_name{$_} =~ /$self->{option_results}->{component}/) {
            my $mod_name = "network::h3c::snmp::mode::components::" . $mapping_component{$_};
            my $func = $mod_name->can('check');
            $func->($self, component => $mapping_name{$_}, component_class => $_); 
        }
    }
    
    my $total_components = 0;
    my $display_by_component = '';
    my $display_by_component_append = '';
    foreach my $comp (sort(keys %{$self->{components}})) {
        # Skipping short msg when no components
        next if ($self->{components}->{$comp}->{total} == 0 && $self->{components}->{$comp}->{skip} == 0);
        $total_components += $self->{components}->{$comp}->{total} + $self->{components}->{$comp}->{skip};
        my $count_by_components = $self->{components}->{$comp}->{total} + $self->{components}->{$comp}->{skip}; 
        $display_by_component .= $display_by_component_append . $self->{components}->{$comp}->{total} . '/' . $count_by_components . ' ' . $self->{components}->{$comp}->{name};
        $display_by_component_append = ', ';
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All %s components are ok [%s].", 
                                                     $total_components,
                                                     $display_by_component)
                                );

    if (defined($self->{option_results}->{no_component}) && $total_components == 0) {
        $self->{output}->output_add(severity => $self->{no_components},
                                    short_msg => 'No components are checked.');
    }

    $self->{output}->display();
    $self->{output}->exit();
}

sub check_exclude {
    my ($self, %options) = @_;

    if (defined($options{instance})) {
        if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)${options{section}}[^,]*#\Q$options{instance}\E#/) {
            $self->{components}->{$options{section}}->{skip}++;
            $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section $options{instance} instance."));
            return 1;
        }
    } elsif (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)$options{section}(\s|,|$)/) {
        $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section."));
        return 1;
    }
    return 0;
}

sub absent_problem {
    my ($self, %options) = @_;
    
    if (defined($self->{option_results}->{absent}) && 
        $self->{option_results}->{absent} =~ /(^|\s|,)($options{section}(\s*,|$)|${options{section}}[^,]*#\Q$options{instance}\E#)/) {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("Component '%s' instance '%s' is not present", 
                                                         $options{section}, $options{instance}));
    }

    $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section $options{instance} instance (not present)"));
    $self->{components}->{$options{section}}->{skip}++;
    return 1;
}

sub get_severity_numeric {
    my ($self, %options) = @_;
    my $status = 'OK'; # default
    my $thresholds = { warning => undef, critical => undef };
    my $checked = 0;
    
    if (defined($self->{numeric_threshold}->{$options{section}})) {
        my $exits = [];
        foreach (@{$self->{numeric_threshold}->{$options{section}}}) {
            if ($options{instance} =~ /$_->{regexp}/) {
                push @{$exits}, $self->{perfdata}->threshold_check(value => $options{value}, threshold => [ { label => $_->{label}, exit_litteral => $_->{threshold} } ]);
                $thresholds->{$_->{threshold}} = $self->{perfdata}->get_perfdata_for_output(label => $_->{label});
                $checked = 1;
            }
        }
        $status = $self->{output}->get_most_critical(status => $exits) if (scalar(@{$exits}) > 0);
    }
    
    return ($status, $thresholds->{warning}, $thresholds->{critical}, $checked);
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

1;

__END__

=head1 MODE

Check Hardware (Fans, Power Supplies, Module,...).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'fan', 'psu', 'other', 'unknown', 'sensor', 'chassis', 'backplane', 
'container', 'module', 'port', 'stack', 'cpu'.

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=fan)
Can also exclude specific instance: --exclude=fan#101#

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma seperated list)
Can be specific or global: --absent-problem=psu#44#

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='psu,CRITICAL,^(?!(normal)$)'

=item B<--warning>

Set warning threshold for 'temperature' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,40'

=item B<--critical>

Set critical threshold for 'temperature' (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,45'

=item B<--reload-cache-time>

Time in seconds before reloading cache file (default: 180).

=back

=cut