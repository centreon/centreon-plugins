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

package network::ruggedcom::mode::hardware;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_rcDeviceStsPowerSupply1_entry = '.1.3.6.1.4.1.15004.4.2.2.4';
my $oid_rcDeviceStsPowerSupply1 = '.1.3.6.1.4.1.15004.4.2.2.4.0';
my $oid_rcDeviceStsPowerSupply2_entry = '.1.3.6.1.4.1.15004.4.2.2.5';
my $oid_rcDeviceStsPowerSupply2 = '.1.3.6.1.4.1.15004.4.2.2.5.0';
my $oid_rcDeviceStsFanBank1_entry = '.1.3.6.1.4.1.15004.4.2.2.10';
my $oid_rcDeviceStsFanBank1 = '.1.3.6.1.4.1.15004.4.2.2.10.0';
my $oid_rcDeviceStsFanBank2_entry = '.1.3.6.1.4.1.15004.4.2.2.11';
my $oid_rcDeviceStsFanBank2 = '.1.3.6.1.4.1.15004.4.2.2.11.0';

my $thresholds = {
    psu => [
        ['notPresent', 'OK'],
        ['functional', 'OK'],
        ['notFunctional', 'CRITICAL'],
        ['notConnected', 'WARNING'],
    ],
    fan => [
        ['notPresent', 'OK'],
        ['failed', 'CRITICAL'],
        ['standby', 'OK'],
        ['on', 'OK'],
        ['off', 'WARNING'],
    ],
};

my %map_states_fan = (
    1 => 'notPresent',
    2 => 'failed',
    3 => 'standby',
    4 => 'off',
    5 => 'on',
);

my %map_states_psu = (
    1 => 'notPresent',
    2 => 'functional',
    3 => 'notFunctional',
    4 => 'notConnected',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "exclude:s"               => { name => 'exclude' },
                                  "component:s"             => { name => 'component', default => 'all' },
                                  "absent-problem:s"        => { name => 'absent' },
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
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    # There is a bug with get_leef and snmpv1.
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                { oid => $oid_rcDeviceStsPowerSupply1_entry },
                                                { oid => $oid_rcDeviceStsPowerSupply2_entry },
                                                { oid => $oid_rcDeviceStsFanBank1_entry },
                                                { oid => $oid_rcDeviceStsFanBank2_entry },
                                               ],
                                               return_type => 1);

    if ($self->{option_results}->{component} eq 'all') {    
        $self->check_fan();
        $self->check_psu();
    } elsif ($self->{option_results}->{component} eq 'fan') {
        $self->check_fan();
    } elsif ($self->{option_results}->{component} eq 'psu') {
        $self->check_psu();
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

sub check_fan {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fan'));

    my $instance = 0;
    foreach my $value (($self->{results}->{$oid_rcDeviceStsFanBank1}, $self->{results}->{$oid_rcDeviceStsFanBank2})) {
        $instance++;
        next if (!defined($value));
        my $fan_state = $value;

        next if ($self->check_exclude(section => 'fan', instance => $instance));
        next if ($map_states_fan{$fan_state} eq 'notPresent' && 
                 $self->absent_problem(section => 'fan', instance => $instance));
        
        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan Bank '%s' state is %s.",
                                    $instance, $map_states_fan{$fan_state}));
        my $exit = $self->get_severity(section => 'fan', value => $map_states_fan{$fan_state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan Bank '%s' state is %s.", $instance, $map_states_fan{$fan_state}));
        }
    }
}

sub check_psu {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'psu'));

    my $instance = 0;
    foreach my $value (($self->{results}->{$oid_rcDeviceStsPowerSupply1}, $self->{results}->{$oid_rcDeviceStsPowerSupply2})) {
        $instance++;
        next if (!defined($value));
        my $psu_state = $value;

        next if ($self->check_exclude(section => 'psu', instance => $instance));
        next if ($map_states_psu{$psu_state} eq 'notPresent' && 
                 $self->absent_problem(section => 'psu', instance => $instance));
        
        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Power Supply '%s' state is %s.",
                                    $instance, $map_states_psu{$psu_state}));
        my $exit = $self->get_severity(section => 'psu', value => $map_states_psu{$psu_state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power Supply '%s' state is %s.", $instance, $map_states_psu{$psu_state}));
        }
    }
}

1;

__END__

=head1 MODE

Check hardware (RUGGEDCOM-SYS-INFO-MIB) (Fans, Power Supplies).

=over 8

=item B<--component>

Which component to check (Default: 'all').
Can be: 'psu', 'fan'.

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=psu)
Can also exclude specific instance: --exclude='psu#1#'

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma seperated list)
Can be specific or global: --absent-problem=fan#1#

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='psu,CRITICAL,^(?!(on)$)'

=back

=cut
    
