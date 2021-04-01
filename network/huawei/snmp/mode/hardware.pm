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

package network::huawei::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;
use centreon::plugins::statefile;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(fan|temperature)$';
    
    $self->{cb_hook1} = 'init_cache';
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        fan => [
            ['abnormal', 'CRITICAL'],
            ['normal', 'OK']
        ]
    };
    
    $self->{components_path} = 'network::huawei::snmp::mode::components';
    $self->{components_module} = ['fan', 'temperature'];
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
    $self->write_cache();
}

sub init_cache {
    my ($self, %options) = @_;

    $self->check_cache(%options);
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'reload-cache-time:s' => { name => 'reload_cache_time', default => 180 },
        'short-name'          => { name => 'short_name' }
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
    my $has_cache_file = $self->{statefile_cache}->read(statefile => 'cache_huawei_entity_' . $self->{hostname}  . '_' . $self->{snmp_port});
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

1;

__END__

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'fan'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=fan --filter=psu)
Can also exclude specific instance: --filter=fan,1.0

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma seperated list)
Can be specific or global: --absent-problem=fan,1.0

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='fan,WARNING,abnormal'

=item B<--warning>

Set warning threshold for 'fan', 'temperature' (syntax: type,regexp,threshold)
Example: --warning='fan,.*,40'

=item B<--critical>

Set critical threshold for 'fan', 'temperature' (syntax: type,regexp,threshold)
Example: --critical='fan,.*,45'

=item B<--reload-cache-time>

Time in seconds before reloading cache file (Default: 180).
Use '-1' to disable cache reload.

=back

=cut
