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

package hardware::server::hp::proliant::snmp::mode::hardware;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

my $thresholds = {
    cpu => [
        ['unknown', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
        ['disabled', 'OK'],
    ],
    idectl => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
    ],
    ideldrive => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['rebuilding', 'WARNING'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
    ],
    idepdrive => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
    ],
    pc => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
    ],
    psu => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
    ],
    sasctl => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
    ],
    sasldrive => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['rebuilding', 'WARNING'],
        ['failed', 'CRITICAL'],
        ['offline', 'CRITICAL'],
    ],
    saspdrive => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
    ],
    scsictl => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
    ],
    scsildrive => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
        ['unconfigured', 'OK'],
        ['recovering', 'WARNING'],
        ['readyForRebuild', 'WARNING'],
        ['rebuilding', 'WARNING'],
        ['wrongDrive', 'CRITICAL'],
        ['badConnect', 'CRITICAL'],
        ['disabled', 'OK'],
    ],
    scsipdrive => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
    ],
    fcahostctl => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
    ],
    fcaexternalctl => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
    ],
    fcaexternalacc => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
    ],
    fcaexternalaccbattery => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
        ['recharging', 'WARNING'],
        ['not present', 'OK'],
    ],
    fcaldrive => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['failed', 'CRITICAL'],
        ['rebuilding', 'WARNING'],
        ['expanding', 'WARNING'],
        ['recovering', 'WARNING'],
        ['unconfigured', 'OK'],
        ['readyForRebuild', 'WARNING'],
        ['wrongDrive', 'CRITICAL'],
        ['badConnect', 'CRITICAL'],
        ['overheating', 'CRITICAL'],
        ['notAvailable', 'WARNING'],
        ['hardError', 'CRITICAL'],
        ['queuedForExpansion', 'WARNING'],
        ['shutdown', 'WARNING'],
    ],
    fcapdrive => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
    ],
    dactl => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
    ],
    daacc => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
    ],
    daaccbattery => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
        ['recharging', 'WARNING'],
        ['not present', 'OK'],
    ],
    daldrive => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['failed', 'CRITICAL'],
        ['rebuilding', 'WARNING'],
        ['expanding', 'WARNING'],
        ['recovering', 'WARNING'],
        ['unconfigured', 'OK'],
        ['readyForRebuild', 'WARNING'],
        ['wrongDrive', 'CRITICAL'],
        ['badConnect', 'CRITICAL'],
        ['overheating', 'CRITICAL'],
        ['notAvailable', 'WARNING'],
        ['hardError', 'CRITICAL'],
        ['queuedForExpansion', 'WARNING'],
        ['shutdown', 'WARNING'],
    ],
    dapdrive => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
    ],
    fan => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
    ],
    pnic => [
        ['other', 'UNKNOWN'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
    ],
    lnic => [
        ['other', 'OK'],
        ['ok', 'OK'],
        ['degraded', 'WARNING'],
        ['failed', 'CRITICAL'],
    ],
    temperature => [
        ['other', 'OK'],
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
                                  "exclude:s"        => { name => 'exclude' },
                                  "absent-problem:s" => { name => 'absent' },
                                  "component:s"      => { name => 'component', default => '.*' },
                                  "no-component:s"   => { name => 'no_component' },
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                  "warning:s@"              => { name => 'warning' },
                                  "critical:s@"             => { name => 'critical' },
                                });

    $self->{product_name} = undef;
    $self->{serial} = undef;
    $self->{romversion} = undef;
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
            if ($section !~ /(temperature)/) {
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
    if ($self->{option_results}->{component} =~ /storage/i) {
        $self->{option_results}->{component} = '^(sas|ide|fca|da|scsi).*';
    }
    if ($self->{option_results}->{component} =~ /network/i) {
        $self->{option_results}->{component} = '^(pnic|lnic)$';
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    $self->get_system_information();
    $self->{output}->output_add(long_msg => sprintf("Product Name: %s, Serial: %s, Rom Version: %s", 
                                                    $self->{product_name}, $self->{serial}, $self->{romversion})
                                );

    my $snmp_request = [];
    my @components = ('cpu', 'idectl', 'ideldrive', 'idepdrive', 'pc', 'psu',
                      'sasctl', 'sasldrive', 'saspdrive', 'scsictl', 'scsildrive', 'scsipdrive',
                      'fcahostctl', 'fcaexternalctl', 'fcaexternalacc', 'fcaldrive', 'fcapdrive',
                      'dactl', 'daacc', 'daldrive', 'dapdrive', 'fan', 'pnic', 'lnic', 'temperature');
    foreach (@components) {
        if (/$self->{option_results}->{component}/) {
            my $mod_name = "hardware::server::hp::proliant::snmp::mode::components::$_";
            centreon::plugins::misc::mymodule_load(output => $self->{output}, module => $mod_name,
                                                   error_msg => "Cannot load module '$mod_name'.");
            my $func = $mod_name->can('load');
            $func->(request => $snmp_request); 
        }
    }
    
    if (scalar(@{$snmp_request}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong option. Cannot find component '" . $self->{option_results}->{component} . "'.");
        $self->{output}->option_exit();
    }
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $snmp_request);
    
    foreach (@components) {
        if (/$self->{option_results}->{component}/) {
            my $mod_name = "hardware::server::hp::proliant::snmp::mode::components::$_";
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

sub get_system_information {
    my ($self) = @_;
    
    # In 'CPQSINFO-MIB'
    my $oid_cpqSiSysSerialNum = ".1.3.6.1.4.1.232.2.2.2.1.0";
    my $oid_cpqSiProductName = ".1.3.6.1.4.1.232.2.2.4.2.0";
    my $oid_cpqSeSysRomVer = ".1.3.6.1.4.1.232.1.2.6.1.0";
    
    my $result = $self->{snmp}->get_leef(oids => [$oid_cpqSiSysSerialNum, $oid_cpqSiProductName, $oid_cpqSeSysRomVer]);
    
    $self->{product_name} = defined($result->{$oid_cpqSiProductName}) ? centreon::plugins::misc::trim($result->{$oid_cpqSiProductName}) : 'unknown';
    $self->{serial} = defined($result->{$oid_cpqSiSysSerialNum}) ? centreon::plugins::misc::trim($result->{$oid_cpqSiSysSerialNum}) : 'unknown';
    $self->{romversion} = defined($result->{$oid_cpqSeSysRomVer}) ? centreon::plugins::misc::trim($result->{$oid_cpqSeSysRomVer}) : 'unknown';
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

Check Hardware (CPUs, Power Supplies, Power converters, Fans).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'cpu', 'psu', 'pc', 'fan', 'temperature', 'lnic', 'pnic',...
There are some magic words like: 'network', 'storage'.

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=fan,cpu)
Can also exclude specific instance: --exclude=fan#1.2#,lnic#1#,cpu

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma seperated list)
Can be specific or global: --absent-problem=fan#1.2#,cpu

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='temperature,CRITICAL,^(?!(ok)$)'

=item B<--warning>

Set warning threshold for temperatures (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold for temperatures (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,40'

=back

=cut