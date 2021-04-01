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

package network::juniper::common::junos::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;
use centreon::plugins::statefile;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(operating-temperature|operating-cpu|operating-buffer|operating-heap)$';
    
    $self->{cb_hook1} = 'init_cache';
    $self->{cb_hook2} = 'snmp_execute';
    $self->{cb_hook3} = 'get_type';

    $self->{thresholds} = {
        fru => [
            ['unknown', 'UNKNOWN'],
            ['present', 'OK'],
            ['ready', 'OK'],
            ['announce online', 'OK'],
            ['online', 'OK'],
            ['announce offline', 'WARNING'],
            ['offline', 'CRITICAL'],
            ['diagnostic', 'WARNING'],
            ['standby', 'WARNING'],
            ['empty', 'OK'],
        ],
        operating => [
            ['runningAtFullSpeed', 'WARNING'],
            ['unknown', 'UNKNOWN'],
            ['running', 'OK'], 
            ['ready', 'OK'], 
            ['reset', 'WARNING'],
            ['down', 'CRITICAL'],
            ['standby', 'OK'],
        ],
        alarm => [
            ['other', 'OK'],
            ['off', 'OK'],
            ['on', 'CRITICAL'],
        ],
    };
    
    $self->{components_path} = 'network::juniper::common::junos::mode::components';
    $self->{components_module} = ['fru', 'operating', 'alarm'];
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
    $self->write_cache();
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'reload-cache-time:s' => { name => 'reload_cache_time', default => 180 }
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->{statefile_cache}->check_options(%options);
}

sub init_cache {
    my ($self, %options) = @_;

    $self->{hostname} = $options{snmp}->get_hostname();
    $self->{snmp_port} = $options{snmp}->get_port();

    $self->{oids_fru} = {
        jnxFruEntry => '.1.3.6.1.4.1.2636.3.1.15.1',
        jnxFruName => '.1.3.6.1.4.1.2636.3.1.15.1.5',
        jnxFruType => '.1.3.6.1.4.1.2636.3.1.15.1.6',
    };
    $self->{oids_operating} = {
        jnxOperatingEntry => '.1.3.6.1.4.1.2636.3.1.13.1',
        jnxOperatingDescr => '.1.3.6.1.4.1.2636.3.1.13.1.5',
    };
    
    $self->{write_cache} = 0;
    my $has_cache_file = $self->{statefile_cache}->read(statefile => 'cache_juniper_mseries_' . $self->{hostname}  . '_' . $self->{snmp_port});
    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');
    if ($has_cache_file == 0 ||
        !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($self->{option_results}->{reload_cache_time}) * 60)) && $self->{option_results}->{reload_cache_time} != '-1') {
        push @{$self->{request}}, { oid => $self->{oids_fru}->{jnxFruEntry}, start => $self->{oids_fru}->{jnxFruName}, end => $self->{oids_fru}->{jnxFruType} };
        push @{$self->{request}}, { oid => $self->{oids_operating}->{jnxOperatingEntry}, start => $self->{oids_operating}->{jnxOperatingDescr}, end => $self->{oids_operating}->{jnxOperatingDescr} };
        $self->{write_cache} = 1;
    }
}

sub write_cache {
    my ($self, %options) = @_;
    
    if ($self->{write_cache} == 1) {
        my $datas = {};
        $datas->{last_timestamp} = time();
        $datas->{$self->{oids_fru}->{jnxFruEntry}} = $self->{results}->{$self->{oids_fru}->{jnxFruEntry}};
        $datas->{$self->{oids_operating}->{jnxOperatingEntry}} = $self->{results}->{$self->{oids_operating}->{jnxOperatingEntry}};
        $self->{statefile_cache}->write(data => $datas);
    } else {
        $self->{results}->{$self->{oids_fru}->{jnxFruEntry}} = $self->{statefile_cache}->get(name => $self->{oids_fru}->{jnxFruEntry});
        $self->{results}->{$self->{oids_operating}->{jnxOperatingEntry}} = $self->{statefile_cache}->get(name => $self->{oids_operating}->{jnxOperatingEntry});
    }
}

sub get_cache {
    my ($self, %options) = @_;
    
    return $self->{results}->{$options{oid_entry}}->{$options{oid_name} . '.' . $options{instance}};
}

sub get_instances {
    my ($self, %options) = @_;
     
    my @instances = ();
    foreach (keys %{$self->{results}->{$options{oid_entry}}}) {
        if (/^$options{oid_name}\.(.*)/) {
            push @instances, $1;
        }
    }

    return @instances;
}

sub get_type {
    my ($self, %options) = @_;

    my $oid_jnxBoxDescr = ".1.3.6.1.4.1.2636.3.1.2.0";
    
    my $result = $options{snmp}->get_leef(oids => [$oid_jnxBoxDescr]);
    
    $self->{env_type} = defined($result->{$oid_jnxBoxDescr}) ? $result->{$oid_jnxBoxDescr} : 'unknown';
    $self->{output}->output_add(long_msg => sprintf("environment type: %s", $self->{env_type}));
}

sub load_components {
    my ($self, %options) = @_;

    foreach (@{$self->{components_module}}) {
        if (/$self->{option_results}->{component}/) {
            my $mod_name = $self->{components_path} . "::$_";
            centreon::plugins::misc::mymodule_load(output => $self->{output}, module => $mod_name,
                                                   error_msg => "Cannot load module '$mod_name'.") if ($self->{load_components} == 1);
            $self->{loaded} = 1;
        }
    }
}

sub exec_components {
    my ($self, %options) = @_;

    foreach (@{$self->{components_module}}) {
        if (/$self->{option_results}->{component}/) {
            my $mod_name = $self->{components_path} . "::$_";
            my $func = $mod_name->can('check');
            $func->($self);
        }
    }
}

1;

__END__

=head1 MODE

Check Hardware (JUNIPER-MIB) (frus, operating).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'fru', 'operating', 'alarm'.

=item B<--add-name-instance>

Add literal description for instance value (used in filter, absent-problem and threshold options).

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=fru)
Can also exclude specific instance: --filter=fru,7.3.0.0

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma seperated list)
Can be specific or global: --absent-problem=fru,7.1.0.0

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='operating,CRITICAL,^(?!(running)$)'

=item B<--warning>

Set warning threshold for fru temperatures (syntax: type,regexp,threshold)
Example: --warning='fru-temperature,.*,30'

=item B<--critical>

Set critical threshold for fru temperatures (syntax: type,regexp,threshold)
Example: --critical='fru-temperature,.*,40'

=item B<--reload-cache-time>

Time in minutes before reloading cache file (Default: 180).
Use '-1' to disable cache reload.

=back

=cut
    
