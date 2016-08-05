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

package storage::netapp::snmp::mode::globalstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

my $instance_mode;

sub custom_status_threshold {
    my ($self, %options) = @_;
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        if (defined($instance_mode->{option_results}->{critical_attributes}) && $instance_mode->{option_results}->{critical_attributes} ne '' &&
            eval "$instance_mode->{option_results}->{critical_attributes}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_attributes}) && $instance_mode->{option_results}->{warning_attributes} ne '' &&
                 eval "$instance_mode->{option_results}->{warning_attributes}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_global_output {
    my ($self, %options) = @_;
    my $msg;
	
	$msg = defined($self->{extra_msg}->{global}) ?  
	       sprintf("Overall global status is '%s' [message: '%s'", $self->{result_values}->{status}, $self->{extra_msg}->{global}) : 
		   sprintf("Overall global status is '%s'", $self->{result_values}->{status});

    return $msg;
}

sub custom_fs_output {
    my ($self, %options) = @_;
    my $msg;
	
	$msg = defined($self->{extra_msg}->{filesystem}) ?  
	       sprintf("Filesystem status is '%s' [message: '%s'", $self->{result_values}->{status}, $self->{extra_msg}->{filesystem}) : 
		   sprintf("Filesystem global status is '%s'", $self->{result_values}->{status});

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'filesystem', type => 0 }
    ];
    $self->{maps_counters}->{global} = [
        { label => 'status', set => {
                key_values => [ { name => 'status' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_global_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_threshold_output'),
            }
        },
    ];
    $self->{maps_counters}->{filesystem} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_fs_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_threshold_output'),
            }
        },
        { label => 'read', set => {
                key_values => [ { name => 'read' }, diff => 1 ],
		        per_second => 1,
                output_template => 'Read I/O : %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'read', value => 'read_per_second', template => '%s',
                      unit => 'B/s', min => 0 },
                ],
            }
        },
        { label => 'write', set => {
                key_values => [ { name => 'write' }, diff => 1 ],
		        per_second => 1,
                output_template => 'Write I/O : %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'write', value => 'write_per_second', template => '%s',
                      unit => 'B/s', min => 0 },
                ],
            }
        },
];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-name:s"           => { name => 'filter_name' },
                                  "warning-status:s"        => { name => 'warning_status', default => '' },
                                  "critical-status:s"       => { name => 'critical_status', default => '%{status} !~ /ok|non critical/' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $instance_mode = $self;
    $self->change_macros();

    $self->{statefile_value}->check_options(%options);
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (('warning_status', 'critical_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

my %map_global_states = (
    1 => 'other',
    2 => 'unknown',
    3 => 'ok', 
    4 => 'non critical',
    5 => 'critical',
    6 => 'nonRecoverable',
);

my %map_fs_states = (
    1 => 'ok',
    2 => 'nearly full',
    3 => 'full',
);

sub manage_selection {
    my ($self, %options) = @_;
    $self->{cache_name} = "netapp_io_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' . md5_hex('all');

	my $oid_fsOverallStatus = '.1.3.6.1.4.1.789.1.5.7.1.0';
	my $oid_fsStatusMessage = '.1.3.6.1.4.1.789.1.5.7.2.0';
	my $oid_miscGlobalStatus = '.1.3.6.1.4.1.789.1.2.2.4.0';
	my $oid_miscGlobalStatusMessage = '.1.3.6.1.4.1.789.1.2.2.25.0';
	my $oid_misc64DiskReadBytes = '.1.3.6.1.4.1.789.1.2.2.32.0';
	my $oid_misc64DiskWriteBytes = '.1.3.6.1.4.1.789.1.2.2.33.0';
	my $oid_miscHighDiskReadBytes = '.1.3.6.1.4.1.789.1.2.2.15.0';
	my $oid_miscLowDiskReadBytes = '.1.3.6.1.4.1.789.1.2.2.16.0';
	my $oid_miscHighDiskWriteBytes = '.1.3.6.1.4.1.789.1.2.2.17.0';
	my $oid_miscLowDiskWriteBytes = '.1.3.6.1.4.1.789.1.2.2.18.0';

	$self->{extra_msg} = {};
	
	$self->{results}->{$oid_miscGlobalStatusMessage} =~ s/\n//g;
  
    my $request = [$oid_fsOverallStatus, $oid_fsStatusMessage,
                   $oid_miscGlobalStatus, $oid_miscGlobalStatusMessage, 
                   $oid_miscHighDiskReadBytes, $oid_miscLowDiskReadBytes,
                   $oid_miscHighDiskWriteBytes, $oid_miscLowDiskWriteBytes];
    if (!$self->{snmp}->is_snmpv1()) {
        push @{$request}, ($oid_misc64DiskReadBytes, $oid_misc64DiskWriteBytes);
    }
    
    $self->{results} = $self->{snmp}->get_leef(oids => $request, nothing_quit => 1);
    
    $self->{global}->{status} = $map_global_states{$self->{results}->{$oid_miscGlobalStatus}};
    $self->{filesystem} = { read => defined($self->{results}->{$oid_misc64DiskReadBytes}) ?
									$self->{results}->{$oid_misc64DiskReadBytes} :
									($self->{results}->{$oid_miscHighDiskReadBytes} << 32) + $self->{results}->{$oid_miscLowDiskReadBytes},
							write => defined($self->{results}->{$oid_misc64DiskWriteBytes}) ?
									 $self->{results}->{$oid_misc64DiskWriteBytes} : 
									 ($self->{results}->{$oid_miscHighDiskWriteBytes} << 32) + $self->{results}->{$oid_miscLowDiskWriteBytes},
							status => $map_fs_states{$self->{results}->{$oid_fsOverallStatus}},
						  };
						  
	$self->{extra_msg}->{global} = defined($self->{results}->{$oid_miscGlobalStatusMessage}) ?
								   $self->{results}->{$oid_miscGlobalStatusMessage} =~ s/\n//g :
								   undef;
	$self->{extra_msg}->{filesystem} = defined($self->{results}->{$oid_fsOverallStatus}) ?
								       $self->{results}->{$oid_fsStatusMessage} =~ s/\n//g :
								       undef;						   

}

1;

__END__

=head1 MODE

Check the overall status of the appliance and some metrics (total read bytes per seconds and total write bytes per seconds).
If you are in cluster mode, the following mode doesn't work. Ask to netapp to add it :)

=over 8

=item B<--filter-counters>

Filter counter to display. Can be 'global' or 'filesystem'

=item B<--warning-status>

Set warning threshold for status. (%{status}) 

=item B<--critical-status>

Set critical threshold for status. (%{status}) 
(Default: "%{status} !~ /ok|non critical/")

=item B<--warning-*>

Threshold warning.
Can be: 'read', 'write'.

=item B<--critical-*>

Threshold critical.
Can be: 'read', 'write'.

=back

=cut
