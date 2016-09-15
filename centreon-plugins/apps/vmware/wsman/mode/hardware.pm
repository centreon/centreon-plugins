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

package apps::vmware::wsman::mode::hardware;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use apps::vmware::wsman::mode::components::resources qw($mapping_HealthState $mapping_OperationalStatus);

my %type = ('cim_numericsensor' => 1);

my $thresholds = {
    default => [    
        ['Unknown', 'OK'],
        ['OK', 'OK'],
        ['Degraded', 'WARNING'],
        ['Minor failure', 'WARNING'],
        ['Major failure', 'CRITICAL'],
        ['Critical failure', 'CRITICAL'],
        ['Non-recoverable error', 'CRITICAL'],
        
        ['Other', 'UNKNOWN'],
        ['Stressed', 'WARNING'],
        ['Predictive Failure', 'WARNING'],
        ['Error', 'CRITICAL'],
        ['Starting', 'OK'],
        ['Stopping', 'WARNING'],
        ['In Service', 'OK'],
        ['No Contact', 'CRITICAL'],
        ['Lost Communication', 'CRITICAL'],
        ['Aborted', 'CRITICAL'],
        ['Dormant', 'OK'],
        ['Supporting Entity in Error', 'CRITICAL'],
        ['Completed', 'OK'],
        ['Power Mode', 'OK'],
        ['Relocating', 'WARNING'],
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "filter:s@"               => { name => 'filter' },
                                  "component:s"             => { name => 'component', default => '.*' },
                                  "no-component:s"          => { name => 'no_component' },
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
    
    $self->{filter} = [];
    foreach my $val (@{$self->{option_results}->{filter}}) {
        next if (!defined($val) || $val eq '');
        my @values = split (/,/, $val);
        push @{$self->{filter}}, { filter => $values[0], instance => $values[1] }; 
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
            next if (!defined($val) || $val eq '');
            if ($val !~ /^(.*?),(.*?),(.*)$/) {
                $self->{output}->add_option_msg(short_msg => "Wrong $option option '" . $val . "'.");
                $self->{output}->option_exit();
            }
            my ($section, $instance, $value) = ($1, $2, $3);
            if (!defined($type{$section})) {
                $self->{output}->add_option_msg(short_msg => "Wrong $option option '" . $val . "'.");
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
            push @{$self->{numeric_threshold}->{$section}}, { label => $option . '-' . $section . '-' . $position, threshold => $option, instance => $instance };
        }
    }
}


sub get_type {
    my ($self, %options) = @_;
    
    my $result = $self->{wsman}->request(uri => 'http://schema.omc-project.org/wbem/wscim/1/cim-schema/2/OMC_SMASHFirmwareIdentity');
    $result = pop(@$result);
    $self->{manufacturer} = 'unknown';
    if (defined($result->{Manufacturer}) && $result->{Manufacturer} ne '') {
        $self->{manufacturer} = $result->{Manufacturer};
    }
    
    $result = $self->{wsman}->request(uri => 'http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_Chassis');
    $result = pop(@$result);
    my $model = defined($result->{Model}) && $result->{Model} ne '' ? $result->{Model} : 'unknown';
    
    $self->{output}->output_add(long_msg => sprintf("Manufacturer : %s, Model : %s", $self->{manufacturer}, $model));
}

sub get_status {
    my ($self, %options) = @_;
    
    my $status;
    if ($self->{manufacturer} =~ /HP/i) {
        $status = $mapping_HealthState->{$options{entry}->{HealthState}} if (defined($options{entry}->{HealthState}) &&
            defined($mapping_HealthState->{$options{entry}->{HealthState}}));
    } else {
        $status = $mapping_OperationalStatus->{$options{entry}->{OperationalStatus}} if (defined($options{entry}->{OperationalStatus}) && 
            defined($mapping_OperationalStatus->{$options{entry}->{OperationalStatus}}));
    }
    return $status;
}

sub run {
    my ($self, %options) = @_;
    $self->{wsman} = $options{wsman};

    $self->get_type();
    
    my @components = ('omc_discretesensor', 'omc_fan', 'omc_psu', 'vmware_storageextent', 'vmware_controller',
                      'vmware_storagevolume', 'vmware_battery', 'vmware_sassataport', 'cim_card',
                      'cim_computersystem', 'cim_numericsensor', 'cim_memory', 'cim_processor', 'cim_recordlog');
    foreach (@components) {
        if (/$self->{option_results}->{component}/) {
            my $mod_name = "apps::vmware::wsman::mode::components::$_";
            centreon::plugins::misc::mymodule_load(output => $self->{output}, module => $mod_name,
                                                   error_msg => "Cannot load module '$mod_name'.");
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
                                short_msg => sprintf("All %s sensors are ok [%s].", 
                                                     $total_components,
                                                     $display_by_component)
                                );

    if (defined($self->{option_results}->{no_component}) && $total_components == 0) {
        $self->{output}->output_add(severity => $self->{no_components},
                                    short_msg => 'No sensors are checked.');
    }

    $self->{output}->display();
    $self->{output}->exit();
}

sub check_filter {
    my ($self, %options) = @_;

    foreach (@{$self->{filter}}) {
        if ($options{section} =~ /$_->{filter}/) {
            if (!defined($options{instance}) && !defined($_->{instance})) {
                $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section."));
                return 1;
            } elsif (defined($options{instance}) && $options{instance} =~ /$_->{instance}/) {
                $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section $options{instance} instance."));
                return 1;
            }
        }
    }
    
    return 0;
}

sub get_severity_numeric {
    my ($self, %options) = @_;
    my $status = 'OK'; # default
    my $thresholds = { warning => undef, critical => undef };
    my $checked = 0;
    
    if (defined($self->{numeric_threshold}->{$options{section}})) {
        my $exits = [];
        foreach (@{$self->{numeric_threshold}->{$options{section}}}) {
            if ($options{instance} =~ /$_->{instance}/) {
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

Check ESXi Hardware.
Example: centreon_plugins.pl --plugin=apps::vmware::wsman::plugin --mode=hardware --hostname='XXX.XXX.XXX.XXX' 
--wsman-username='XXXX' --wsman-password='XXXX'  --wsman-scheme=https --wsman-port=443 --verbose

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'omc_discretesensor', 'omc_fan', 'omc_psu', 'vmware_storageextent', 'vmware_controller',
'vmware_storagevolume', 'vmware_battery', 'vmware_sassataport', 'cim_card',
'cim_computersystem', 'cim_numericsensor', 'cim_memory', 'cim_processor', 'cim_recordlog'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=cim_card --filter=cim_recordlog)
Can also exclude specific instance: --filter='omc_psu,Power Supply 1'

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='cim_card,CRITICAL,^(?!(OK)$)'

=item B<--warning>

Set warning threshold for temperatures (syntax: type,instance,threshold)
Example: --warning='cim_numericsensor,.*,30'

=item B<--critical>

Set critical threshold for temperatures (syntax: type,instance,threshold)
Example: --critical='cim_numericsensor,.*,40'

=back

=cut