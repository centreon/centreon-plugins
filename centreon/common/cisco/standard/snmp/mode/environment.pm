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

package centreon::common::cisco::standard::snmp::mode::environment;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_type_mon = (
    1 => 'oldAgs',
    2 => 'ags',
    3 => 'c7000',
    4 => 'ci',
    6 => 'cAccessMon',
    7 => 'cat6000',
    8 => 'ubr7200',
    9 => 'cat4000',
    10 => 'c10000',
    11 => 'osr7600',
    12 => 'c7600',
    13 => 'c37xx',
    14 => 'other'
);

my $thresholds = {
    fan => [
        ['unknown', 'UNKNOWN'],
        ['down', 'CRITICAL'],
        ['up', 'OK'],
        
        ['normal', 'OK'],
        ['warning', 'WARNING'],
        ['critical', 'CRITICAL'],
        ['shutdown', 'CRITICAL'],
        ['not present', 'OK'],
        ['not functioning', 'WARNING'],
    ],
    psu => [
        ['^off*', 'WARNING'],
        ['failed', 'CRITICAL'],
        ['onButFanFail|onButInlinePowerFail', 'WARNING'],
        ['on', 'OK'],
        
        ['normal', 'OK'],
        ['warning', 'WARNING'],
        ['critical', 'CRITICAL'],
        ['shutdown', 'CRITICAL'],
        ['not present', 'OK'],
        ['not functioning', 'WARNING'],
    ],
    temperature => [
        ['normal', 'OK'],
        ['warning', 'WARNING'],
        ['critical', 'CRITICAL'],
        ['shutdown', 'CRITICAL'],
        ['not present', 'OK'],
        ['not functioning', 'WARNING'],
    ],
    voltage => [
        ['normal', 'OK'],
        ['warning', 'WARNING'],
        ['critical', 'CRITICAL'],
        ['shutdown', 'CRITICAL'],
        ['not present', 'OK'],
        ['not functioning', 'WARNING'],
    ],
    module => [
        ['unknown|mdr', 'UNKNOWN'],
        ['disabled|okButDiagFailed|missing|mismatchWithParent|mismatchConfig|dormant|outOfServiceAdmin|outOfServiceEnvTemp|powerCycled|okButPowerOverWarning|okButAuthFailed|fwMismatchFound|fwDownloadFailure', 'WARNING'],
        ['failed|diagFailed|poweredDown|powerDenied|okButPowerOverCritical', 'CRITICAL'],
        ['boot|selfTest|poweredUp|syncInProgress|upgrading|fwDownloadSuccess|ok', 'OK'],
    ],
    physical => [
        ['other', 'UNKNOWN'],
        ['incompatible|unsupported', 'CRITICAL'],
        ['supported', 'OK'],
    ],
    sensor => [
        ['ok', 'OK'],
        ['unavailable', 'OK'],
        ['nonoperational', 'CRITICAL'],
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
        next if (!defined($val) || $val eq '');
        my @values = split (/,/, $val);
        if (scalar(@values) < 3) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $instance, $status, $filter);
        if (scalar(@values) == 3) {
            ($section, $status, $filter) = @values;
            $instance = '.*';
        } else {
             ($section, $instance, $status, $filter) = @values;
        }
        if ($section !~ /^(temperature|fan|psu)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload section '" . $val . "'.");
            $self->{output}->option_exit();
        }
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status, instance => $instance };
    }
    
    $self->{numeric_threshold} = {};
    foreach my $option (('warning', 'critical')) {
        foreach my $val (@{$self->{option_results}->{$option}}) {
            if ($val !~ /^(.*?),(.*?),(.*)$/) {
                $self->{output}->add_option_msg(short_msg => "Wrong $option option '" . $val . "'.");
                $self->{output}->option_exit();
            }
            my ($section, $regexp, $value) = ($1, $2, $3);
            if ($section !~ /(temperature|voltage|sensor)/i) {
                $self->{output}->add_option_msg(short_msg => "Wrong $option option '" . $val . "' (type must be: temperature, voltage or sensor).");
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
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_entPhysicalDescr = '.1.3.6.1.2.1.47.1.1.1.1.2';
    my $oid_ciscoEnvMonPresent = ".1.3.6.1.4.1.9.9.13.1.1";
    my $snmp_request = [ { oid => $oid_entPhysicalDescr }, { oid => $oid_ciscoEnvMonPresent } ];
    
    my @components = ('fan', 'psu', 'temperature', 'voltage', 'module', 'physical', 'sensor');
    foreach (@components) {
        if (/$self->{option_results}->{component}/) {
            my $mod_name = "centreon::common::cisco::standard::snmp::mode::components::$_";
            centreon::plugins::misc::mymodule_load(output => $self->{output}, module => $mod_name,
                                                   error_msg => "Cannot load module '$mod_name'.");
            my $func = $mod_name->can('load');
            $func->(request => $snmp_request); 
        }
    }
    
    if (scalar(@{$snmp_request}) == 2) {
        $self->{output}->add_option_msg(short_msg => "Wrong option. Cannot find component '" . $self->{option_results}->{component} . "'.");
        $self->{output}->option_exit();
    }
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $snmp_request);
    
    $self->{output}->output_add(long_msg => sprintf("Environment type: %s", 
                                                    defined($self->{results}->{$oid_ciscoEnvMonPresent}->{$oid_ciscoEnvMonPresent . '.0'}) && defined($map_type_mon{$self->{results}->{$oid_ciscoEnvMonPresent}->{$oid_ciscoEnvMonPresent . '.0'}} ) ? 
                                                        $map_type_mon{$self->{results}->{$oid_ciscoEnvMonPresent}->{$oid_ciscoEnvMonPresent . '.0'}} : 'unknown'));
    
    foreach (@components) {
        if (/$self->{option_results}->{component}/) {
            my $mod_name = "centreon::common::cisco::standard::snmp::mode::components::$_";
            my $func = $mod_name->can('check');
            $func->($self); 
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
            if ($options{instance} =~ /$_->{regexp}/i) {
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
            if ($options{value} =~ /$_->{filter}/i && 
                (!defined($options{instance}) || $options{instance} =~ /$_->{instance}/)) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    my $label = defined($options{label}) ? $options{label} : $options{section};
    foreach (@{$thresholds->{$label}}) {
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

Check environment (Power Supplies, Fans, Temperatures, Voltages, Modules, Physical Entities).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'fan', 'psu', 'temperature', 'voltage', 'module', 'physical', 'sensor'.

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=fan)
Can also exclude specific instance: --exclude=fan#1#,psu#3#

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma seperated list)
Can be specific or global: --absent-problem=fan#1#

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='fan,CRITICAL,^(?!(up|normal)$)'

=item B<--warning>

Set warning threshold for temperatures, voltages, sensors (syntax: type,regexp,treshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold for temperatures, voltages, sensors (syntax: type,regexp,treshold)
Example: --critical='temperature,.*,40'

=back

=cut