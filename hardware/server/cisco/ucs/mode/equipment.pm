################################################################################
# Copyright 2005-2013 MERETHIS
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

package hardware::server::cisco::ucs::mode::equipment;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use hardware::server::cisco::ucs::mode::components::resources qw($thresholds);
use hardware::server::cisco::ucs::mode::components::fan;
use hardware::server::cisco::ucs::mode::components::psu;
use hardware::server::cisco::ucs::mode::components::iocard;
use hardware::server::cisco::ucs::mode::components::chassis;
use hardware::server::cisco::ucs::mode::components::blade;
use hardware::server::cisco::ucs::mode::components::fex;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "exclude:s"        => { name => 'exclude' },
                                  "absent-problem:s" => { name => 'absent' },
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
    
    if (defined($self->{option_results}->{no_component})) {
        if ($self->{option_results}->{no_component} ne '') {
            $self->{no_components} = $self->{option_results}->{no_component};
        } else {
            $self->{no_components} = 'critical';
        }
    }
    
    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $type, $status, $filter) = ($1, $2, $3, $4);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = { } if (!defined($self->{overload_th}->{$section}));
        $self->{overload_th}->{$section}->{$type} = { } if (!defined($self->{overload_th}->{$section}->{$type}));
        $self->{overload_th}->{$section}->{$type}->{$filter} = $status;
    }
}

sub global {
    my ($self, %options) = @_;
 
    hardware::server::cisco::ucs::mode::components::fan::check($self);
    hardware::server::cisco::ucs::mode::components::psu::check($self);
    hardware::server::cisco::ucs::mode::components::iocard::check($self);
    hardware::server::cisco::ucs::mode::components::chassis::check($self);
    hardware::server::cisco::ucs::mode::components::blade::check($self);
    hardware::server::cisco::ucs::mode::components::fex::check($self);
}

sub component {
    my ($self, %options) = @_;
    
    if ($self->{option_results}->{component} eq 'fan') {
        hardware::server::cisco::ucs::mode::components::fan::check($self);
    } elsif ($self->{option_results}->{component} eq 'psu') {
        hardware::server::cisco::ucs::mode::components::psu::check($self);
    } elsif ($self->{option_results}->{component} eq 'iocard') {
        hardware::server::cisco::ucs::mode::components::iocard::check($self);
    } elsif ($self->{option_results}->{component} eq 'chassis') {
        hardware::server::cisco::ucs::mode::components::chassis::check($self);
    } elsif ($self->{option_results}->{component} eq 'blade') {
        hardware::server::cisco::ucs::mode::components::blade::check($self);
    } elsif ($self->{option_results}->{component} eq 'fex') {
        hardware::server::cisco::ucs::mode::components::fex::check($self);
    } else {
        $self->{output}->add_option_msg(short_msg => "Wrong option. Cannot find component '" . $self->{option_results}->{component} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    if ($self->{option_results}->{component} eq 'all') {
        $self->global();
    } else {
        $self->component();
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

sub get_severity {
    my ($self, %options) = @_;
    
    my $status = ${$thresholds->{$options{threshold}}->{$options{value}}}[1];
    if (defined($self->{overload_th}->{$options{section}}->{$options{threshold}})) {
        foreach (keys %{$self->{overload_th}->{$options{section}}->{$options{threshold}}}) {            
            if (${$thresholds->{$options{threshold}}->{$options{value}}}[0] =~ /$_/i) {
                $status = $self->{overload_th}->{$options{section}}->{$options{threshold}}->{$_};
                last;
            }
        }
    }
    return $status;
}

sub absent_problem {
    my ($self, %options) = @_;
    
    if (defined($self->{option_results}->{absent}) && 
        $self->{option_results}->{absent} =~ /(^|\s|,)($options{section}(\s*,|$)|${options{section}}[^,]*#\Q$options{instance}\E#)/) {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("Component '%s' instance '%s' is not present", 
                                                         $options{section}, $options{instance}));
        return 1;
    }
    
    return 0;
}

1;

__END__

=head1 MODE

Check Hardware (Fans, Power supplies, chassis, io cards, blades, fabric extenders).

=over 8

=item B<--component>

Which component to check (Default: 'all').
Can be: 'fan', 'psu', 'chassis', 'iocard', 'blade', 'fex'

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=fan)
Can also exclude specific instance: --exclude=fan#/sys/chassis-7/fan-module-1-7/fan-1#

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma seperated list)
Can be specific or global: --exclude=fan#/sys/chassis-7/fan-module-1-7/fan-1#

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,threshold,status,regexp)
Example: --threshold-overload='fan,operability,OK,poweredOff|removed'

=back

=cut
    
