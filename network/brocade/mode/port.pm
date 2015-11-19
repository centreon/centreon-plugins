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

package network::brocade::mode::port;

use base qw(centreon::plugins::mode);
use strict;
use warnings;

my %port_oper_state = (
    0 => "unknown",
    1 => "online",
    2 => "offline",
    3 => "testing",
    4 => "faulty",
);

my %port_physical_state = (
    1 => "noCard",
    2 => "noTransceiver",
    3 => "LaserFault",
    4 => "noLight",
    5 => "noSync",
    6 => "inSync",
    7 => "portFault",
    8 => "diagFault",
    9 => "lockref"
);

my $thresholds = {
    operstate => [
        ['online', 'OK'],
        ['offline', 'CRITICAL'],
        ['testing', 'WARNING'],
        ['faulty', 'CRITICAL'],
	['unknown', 'UNKNOWN']
    ],
    physicalstate => [
        ['noCard', 'UNKNOWN'],
        ['noTransceiver', 'CRITICAL'],
        ['LaserFault', 'CRITICAL'],
        ['noLight', 'CRITICAL'],
        ['noSync', 'WARNING'],
        ['inSync', 'OK'],
        ['portFault', 'CRITICAL'],
	['diagFault', 'WARNING' ],
	['lockref', 'CRITICAL' ]
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =
				{
				"threshold-overload:s@" => { name => 'threshold_overload' }, 
				"warning:s"  		=> { name => 'warning' },
				"critical:s	  	=> { name => 'critical' },
        			"filter:s@"             => { name => 'filter' },
                		});
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->{filter} = [];
    foreach my $val (@{$self->{option_results}->{filter}}) {
        next if (!defined($val) || $val eq '');
        my @values = split (/,/, $val);
        push @{$self->{filter}}, { filter => $values[0], instance => $values[1] };
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

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }

}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    my $oid_swFcPortEntry = '.1.3.6.1.4.1.1588.2.1.1.1.6.2.1.1';
    my $oid_swFcPortOperState = '.1.3.6.1.4.1.1588.2.1.1.1.6.2.1.4';
    my $oid_swFcPortPhysicalState = '.1.3.6.1.4.1.1588.2.1.1.1.6.2.1.3';
    my $oid_swFcPortDescription = '.1.3.6.1.4.1.1588.2.1.1.1.6.2.1.36';
    my $oid_swFcPortTemperature = '.1.3.6.1.4.1.1588.2.1.1.1.10.3.1.5.4';
    my $oid_swFcPortTempThreshold = '.1.3.6.1.4.1.1588.2.1.1.1.10.2.1.6.4';
    my $oid_swFwFabricWatchLicense = '.1.3.6.1.4.1.1588.2.1.1.1.10.1.0';

    $self->{results} = $self->{snmp}->get_multiple_table(oids => [{ oid => $oid_swFcPortEntry },
								  { oid => $oid_swFcPortOperState },
								  { oid =>  $oid_swFcPortPhysicalState },
								  { oid =>  $oid_swFcPortDescription },
                                                                  { oid =>  $oid_swFcPortTemperature }],
							 nothing_quit => 1);

    my $result = $self->{snmp}->get_leef(oids => [$oid_swFcPortTempThreshold, $oid_swFwFabricWatchLicense],
					 nothing_quit => 1);

    if ($result->{$oid_swFwFabricWatchLicense} == 2) {
        $self->{output}->add_option_msg(short_msg => "Need Fabric Watch License to get information.");
        $self->{output}->option_exit();
    }

    $self->{output}->output_add(severity => 'OK',
				short_msg => 'All ports are OK');

    foreach my $oid (keys %{$self->{results}->{$oid_swFcPortEntry}}) {
        next if ($oid !~ /^$oid_swFcPortEntry\.(\d+)/);
        my $index = $1;
        my $name = $self->{results}->{$oid_swFcPortDescription}->{$oid_swFcPortDescription . '.' . $index};
        my $status = $self->{results}->{$oid_swFcPortOperState}->{$oid_swFcPortOperState . '.' . $index};
        my $type = $self->{results}->{$oid_swFcPortPhysicalState}->{$oid_swFcPortPhysicalState . '.' . $index};
        my $temp = $self->{results}->{$oid_swFcPortTemperature}->{$oid_swFcPortTemperature . '.' . $index};

        next if ($self->check_filter(section => 'port', instance => $name));

        $self->{output}->output_add(long_msg => sprintf("Port '%s' (id:'%i') state is '%s' and type is '%s' Temp is '%i'C", 
							$name, $index, $port_oper_state{$status}, $port_physical_state{$type}, $temp));

        if (defined($self->{option_results}->{warning}) || defined($self->{option_results}->{critical})) {
            my $exit = $self->{perfdata}->threshold_check(value => $temp,
                                                          threshold => [ { label => 'critical', 'exit_litteral' => 'critical' },
									 { label => 'warning', exit_litteral => 'warning' } ]);
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Port '%s' temperature is '%i'", $name, $temp));
        } elsif ($temp > $result->{$oid_swFcPortTempThreshold}) {        
            $self->{output}->output_add(severity => 'CRITICAL',
					short_msg => sprintf("Port '%s' temperature is '%i'", $name, $temp)); 
        }
		
        my $exit1 = $self->get_severity(section => 'operstate', value => $port_oper_state{$status});
        my $exit2 = $self->get_severity(section => 'physicalstate', value => $port_physical_state{$type});       
		
        if (!$self->{output}->is_status(value => $exit1, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit1,
                                        short_msg => sprintf("Port '%s' operstate is '%s'.", $name, $port_oper_state{$status}));
        }
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Port '%s' physical state is '%s'", $name, $port_physical_state{$type}));
        }
		
        $self->{output}->perfdata_add(label => "port_".$name, unit => 'C',
                                      value => $temp,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
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

Check brocade port informations (SW.mib).

=over 8

=item B<--warning>

Threshold warning in celcius degres for temperature

=item B<--critical>

Threshold critical in celcius degres for temperature, if not defined manufacturer default mib threshold is used (85°C)

=item B<--threshold-overload>

Overload some values for threshold, section are 'operstate' and 'physicalstate'. E.g: --threshold-overload 'operstate,OK,offline' or --threshold-overload 'physicalstate,OK,noSync'

=item B<--filter>

Filter ports. E.g --filter "port,'^HBA[1-4]$'"

=back

=cut
