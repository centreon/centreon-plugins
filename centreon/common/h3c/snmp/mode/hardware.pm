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

package centreon::common::h3c::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;
use centreon::plugins::statefile;

sub set_system {
    my ($self, %options) = @_;
    
    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature)$';
    
    $self->{cb_hook1} = 'init_cache';
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
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
    
    $self->{components_path} = 'centreon::common::h3c::snmp::mode::components';
    $self->{components_module} = ['chassis', 'backplane', 'container', 'psu', 'fan', 'sensor',
        'module', 'port', 'stack', 'cpu', 'other', 'unknown'];
    
    $self->{mapping_name} = {
        1 => 'other', 2 => 'unknown', 3 => 'chassis', 4 => 'backplane', 5 => 'container', 6 => 'psu', 
        7 => 'fan', 8 => 'sensor', 9 => 'module', 10 => 'port', 11 => 'stack', 12 => 'cpu'
    };
    $self->{mapping_component} = {
        1 => 'default', 2 => 'default', 3 => 'default', 4 => 'default', 5 => 'default', 6 => 'psu', 
        7 => 'fan', 8 => 'sensor', 9 => 'default', 10 => 'default', 11 => 'default', 12 => 'default'
    };
}

my $oid_hh3cEntityExtStateEntry = '.1.3.6.1.4.1.25506.2.6.1.1.1.1';
my $oid_h3cEntityExtStateEntry = '.1.3.6.1.4.1.2011.10.2.6.1.1.1.1';
my $oid_h3cEntityExtErrorStatus = '.1.3.6.1.4.1.2011.10.2.6.1.1.1.1.19';
my $oid_hh3cEntityExtErrorStatus = '.1.3.6.1.4.1.25506.2.6.1.1.1.1.19';

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
    $self->write_cache();
    
    $self->{branch} = $oid_hh3cEntityExtStateEntry;
    if (defined($self->{results}->{$oid_h3cEntityExtErrorStatus}) && scalar(keys %{$self->{results}->{$oid_h3cEntityExtErrorStatus}}) > 0) {
        $self->{branch} = $oid_h3cEntityExtStateEntry;
    }
}

sub init_cache {
    my ($self, %options) = @_;

    $self->{request} = [ 
                        { oid => $oid_h3cEntityExtErrorStatus },
                        { oid => $oid_hh3cEntityExtErrorStatus },
                       ];
    $self->check_cache(%options);
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "reload-cache-time:s"     => { name => 'reload_cache_time', default => 180 },
                                  "short-name"              => { name => 'short_name' },
                                });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{short_name} = (defined($self->{option_results}->{short_name})) ? 1 : 0;
    
    $self->{statefile_cache}->check_options(%options);
}

my $oid_entPhysicalEntry = '.1.3.6.1.2.1.47.1.1.1.1';
my $oid_entPhysicalDescr = '.1.3.6.1.2.1.47.1.1.1.1.2';
my $oid_entPhysicalContainedIn = '.1.3.6.1.2.1.47.1.1.1.1.4';
my $oid_entPhysicalClass = '.1.3.6.1.2.1.47.1.1.1.1.5';
my $oid_entPhysicalName = '.1.3.6.1.2.1.47.1.1.1.1.7';

sub check_cache {
    my ($self, %options) = @_;

    $self->{hostname} = $options{snmp}->get_hostname();
    $self->{snmp_port} = $options{snmp}->get_port();
    
    # init cache file
    $self->{write_cache} = 0;
    my $has_cache_file = $self->{statefile_cache}->read(statefile => 'cache_h3c_entity_' . $self->{hostname}  . '_' . $self->{snmp_port});
    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');
    if ($has_cache_file == 0 ||
        !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($self->{option_results}->{reload_cache_time}) * 60)) && $self->{option_results}->{reload_cache_time} != '-1') {
        push @{$self->{request}}, { oid => $oid_entPhysicalEntry, start => $oid_entPhysicalDescr, end => $oid_entPhysicalName };
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

sub get_short_name {
    my ($self, %options) = @_;
    
    return $self->{results}->{$oid_entPhysicalEntry}->{$oid_entPhysicalName . '.' . $options{instance}};
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

sub load_components {
    my ($self, %options) = @_;
    
    foreach (keys %{$self->{mapping_name}}) {
        if ($self->{mapping_name}->{$_} =~ /$self->{option_results}->{component}/) {
            my $mod_name = $self->{components_path} . "::" . $self->{mapping_component}->{$_};
            centreon::plugins::misc::mymodule_load(output => $self->{output}, module => $mod_name,
                                                   error_msg => "Cannot load module '$mod_name'.");
            $self->{loaded} = 1;
        }
    }
}

sub exec_components {
    my ($self, %options) = @_;
    
     foreach (keys %{$self->{mapping_name}}) {
        if ($self->{mapping_name}->{$_} =~ /$self->{option_results}->{component}/) {
            my $mod_name = $self->{components_path} . "::" . $self->{mapping_component}->{$_};
            my $func = $mod_name->can('check');
            $func->($self, component => $self->{mapping_name}->{$_}, component_class => $_); 
        }
    }
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

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=fan --filter=psu)
Can also exclude specific instance: --filter=fan,101

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma seperated list)
Can be specific or global: --absent-problem=psu#44#

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='psu,CRITICAL,^(?!(normal)$)'

=item B<--warning>

Set warning threshold for 'temperature' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,40'

=item B<--critical>

Set critical threshold for 'temperature' (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,45'

=item B<--warning-count-*>

Set warning threshold for component count.
Can be: 'fan', 'psu', 'other', 'unknown', 'sensor', 'chassis', 'backplane',
'container', 'module', 'port', 'stack', 'cpu'.

=item B<--critical-count-*>

Set critical threshold for component count.
Can be: 'fan', 'psu', 'other', 'unknown', 'sensor', 'chassis', 'backplane',
'container', 'module', 'port', 'stack', 'cpu'.

=item B<--reload-cache-time>

Time in seconds before reloading cache file (Default: 180).
Use '-1' to disable cache reload.

=back

=cut
