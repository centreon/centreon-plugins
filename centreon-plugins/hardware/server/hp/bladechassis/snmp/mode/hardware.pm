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

package hardware::server::hp::bladechassis::snmp::mode::hardware;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use hardware::server::hp::bladechassis::snmp::mode::components::enclosure;
use hardware::server::hp::bladechassis::snmp::mode::components::manager;
use hardware::server::hp::bladechassis::snmp::mode::components::fan;
use hardware::server::hp::bladechassis::snmp::mode::components::blade;
use hardware::server::hp::bladechassis::snmp::mode::components::network;
use hardware::server::hp::bladechassis::snmp::mode::components::psu;
use hardware::server::hp::bladechassis::snmp::mode::components::temperature;
use hardware::server::hp::bladechassis::snmp::mode::components::fuse;

my $thresholds = {
    temperature => [
        ['other', 'CRITICAL'], 
        ['ok', 'OK'], 
        ['degraded', 'WARNING'], 
        ['failed', 'CRITICAL'],
    ],
    blade => [
        ['other', 'CRITICAL'], 
        ['ok', 'OK'], 
        ['degraded', 'WARNING'], 
        ['failed', 'CRITICAL'],
    ],
    enclosure => [
        ['other', 'CRITICAL'], 
        ['ok', 'OK'], 
        ['degraded', 'WARNING'], 
        ['failed', 'CRITICAL'],
    ],
    fan => [
        ['other', 'CRITICAL'], 
        ['ok', 'OK'], 
        ['degraded', 'WARNING'], 
        ['failed', 'CRITICAL'],
    ],
    fuse => [
        ['other', 'CRITICAL'], 
        ['ok', 'OK'], 
        ['degraded', 'WARNING'], 
        ['failed', 'CRITICAL'],
    ],
    manager => [
        ['other', 'CRITICAL'], 
        ['ok', 'OK'], 
        ['degraded', 'WARNING'], 
        ['failed', 'CRITICAL'],
    ],
    psu => [
        ['other', 'CRITICAL'], 
        ['ok', 'OK'], 
        ['degraded', 'WARNING'], 
        ['failed', 'CRITICAL'],
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "exclude:s"               => { name => 'exclude' },
                                  "absent-problem:s"        => { name => 'absent' },
                                  "component:s"             => { name => 'component', default => 'all' },
                                  "no-component:s"          => { name => 'no_component' },
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                });
    $self->{components} = {};
    $self->{no_components} = undef;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
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
    if (defined($self->{option_results}->{no_component})) {
        if ($self->{option_results}->{no_component} ne '') {
            $self->{no_components} = $self->{option_results}->{no_component};
        } else {
            $self->{no_components} = 'critical';
        }
    }
}

sub global {
    my ($self, %options) = @_;

    hardware::server::hp::bladechassis::snmp::mode::components::enclosure::check($self);
    hardware::server::hp::bladechassis::snmp::mode::components::manager::check($self);
    hardware::server::hp::bladechassis::snmp::mode::components::fan::check($self);
    hardware::server::hp::bladechassis::snmp::mode::components::blade::check($self);
    hardware::server::hp::bladechassis::snmp::mode::components::network::check($self);
    hardware::server::hp::bladechassis::snmp::mode::components::psu::check($self);
    hardware::server::hp::bladechassis::snmp::mode::components::temperature::check($self);
    hardware::server::hp::bladechassis::snmp::mode::components::fuse::check($self);
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    
    if ($self->{option_results}->{component} eq 'all') {
        $self->global();
    } elsif ($self->{option_results}->{component} eq 'enclosure') {
        hardware::server::hp::bladechassis::snmp::mode::components::enclosure::check($self);
    } elsif ($self->{option_results}->{component} eq 'manager') {
        hardware::server::hp::bladechassis::snmp::mode::components::manager::check($self, force => 1);
    } elsif ($self->{option_results}->{component} eq 'fan') {
        hardware::server::hp::bladechassis::snmp::mode::components::fan::check($self);
    } elsif ($self->{option_results}->{component} eq 'blade') {
        hardware::server::hp::bladechassis::snmp::mode::components::blade::check($self);
    } elsif ($self->{option_results}->{component} eq 'network') {
        hardware::server::hp::bladechassis::snmp::mode::components::network::check($self);
    } elsif ($self->{option_results}->{component} eq 'psu') {
        hardware::server::hp::bladechassis::snmp::mode::components::psu::check($self);
    } elsif ($self->{option_results}->{component} eq 'temperature') {
        hardware::server::hp::bladechassis::snmp::mode::components::temperature::check($self);
    } elsif ($self->{option_results}->{component} eq 'fuse') {
        hardware::server::hp::bladechassis::snmp::mode::components::fuse::check($self);
    } else {
        $self->{output}->add_option_msg(short_msg => "Wrong option. Cannot find component '" . $self->{option_results}->{component} . "'.");
        $self->{output}->option_exit();
    }
    
    my $total_components = 0;
    my $display_by_component = '';
    my $display_by_component_append = '';
    foreach my $comp (sort(keys %{$self->{components}})) {
        # Skipping short msg when no components
        next if ($self->{components}->{$comp}->{total} == 0 && $self->{components}->{$comp}->{skip} == 0);
        $total_components += $self->{components}->{$comp}->{total} + $self->{components}->{$comp}->{skip};
        $display_by_component .= $display_by_component_append . $self->{components}->{$comp}->{total} . '/' . $self->{components}->{$comp}->{skip} . ' ' . $self->{components}->{$comp}->{name};
        $display_by_component_append = ', ';
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All %s components [%s] are ok.", 
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

Check Hardware (Fans, Power Supplies, Blades, Temperatures, Fuses).

=over 8

=item B<--component>

Which component to check (Default: 'all').
Can be: 'enclosure', 'manager', 'fan', 'blade', 'network', 'psu', 'temperature', 'fuse'.

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=temperature,psu).
Can also exclude specific instance: --exclude=temperature#1#

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma seperated list)
Can be specific or global: --absent-problem=blade#12#

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='temperature,OK,other'

=back

=cut
    
