#
# Copyright 2019 Centreon (http://www.centreon.com/)
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
# Authors : Pedro Manuel Santos Delgado pedromanuelsant@yahoo.com

package network::cisco::catalyst::snmp::mode::cpu_load;

use strict;
use warnings;
use base qw(centreon::plugins::mode); # --> implies sub run; commented out as 
use Data::Dumper;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                {
                                "warning_1m:i"  	=> { name => 'w_1m', default => 6 },
                                "warning_5m:i"  	=> { name => 'w_5m', default => 4 },
                                "warning_15m:i"		=> { name => 'w_15m', default => 2 },
                                "critical_1m:i"  	=> { name => 'c_1m', default => 8 },
                                "critical_5m:i"  	=> { name => 'c_5m', default => 6 },
                                "critical_15m:i"	=> { name => 'c_15m', default => 4 },
                                "perfdata"   		=> { name => 'perfdata' },
                                });
	$self->{version} = '0.1';
    return $self;
}


sub check_options {
  	# From Docs - This will initialize all option names, if threshold sintax is ok
  	# as described on https://nagios-plugins.org/doc/guidelines.html#THRESHOLDFORMAT
      my ($self, %options) = @_;
    	$self->SUPER::init(%options);
    	my @warning_names=('w_1m','w_5m','w_15m');
    	foreach my $option_label (@warning_names) {
  	 	if (($self->{perfdata}->threshold_validate(label => $option_label, value => $self->{option_results}->{warning})) == 0) {
  		     $self->{output}->add_option_msg(short_msg => "Wrong $option_label threshold '" . $self->{option_results}->{warning} . "'.");
  		     $self->{output}->option_exit();
  		} 		
    	}
    	my @critical_names=('c_1m','c_5m','c_15m');
    	foreach my $option_label (@critical_names) {
  	 	if (($self->{perfdata}->threshold_validate(label => $option_label, value => $self->{option_results}->{critical})) == 0) {
  		     $self->{output}->add_option_msg(short_msg => "Wrong $option_label threshold '" . $self->{option_results}->{critical} . "'.");
  		     $self->{output}->option_exit();
  		} 		
    	}  	
}


  sub run {
  	#From Docs - Execute the check
  	my ($self, %options) = @_;
  	$self->{snmp} = $options{snmp};
  	# OIDs
  	my $ciscocata_cpmEntries = ".1.3.6.1.4.1.9.9.109.1.1.1.1.2"; # List of Physical devices
  	my $ciscocata_names=".1.3.6.1.2.1.47.1.1.1.1.2"; #name of the physical devices, use same number from previous
  	my $ciscocata_cpmCPULoadAvg1min = ".1.3.6.1.4.1.9.9.109.1.1.1.1.24"; # Cisco CPU load (5min %) per item in cmpEntries
  	my $ciscocata_cpmCPULoadAvg5min = ".1.3.6.1.4.1.9.9.109.1.1.1.1.25"; # Cisco CPU load (1min %) per item in cmpEntries
  	my $ciscocata_cpmCPULoadAvg15min = ".1.3.6.1.4.1.9.9.109.1.1.1.1.26"; # Cisco CPU load (5sec %) per item in cmpEntries
  	# OUTPUT Messages
  	my %out_messages=(
  		'ok' => 'CPU Load on all stack members within threshold.',
  		'warning' => 'CPU Load exceeding at least one warning thresholds.',
  		'critical' => 'CPU Load exceeding at least one critical thresholds.'
  	);
  	# Retrieve information - REFERENCES to Hashes
  	my $debug_script=1;
  	if ($debug_script==1) {
  		print("Collecting Entries\n");
  	}
  	my $cpm_entries = $self->{snmp}->get_table(oid => $ciscocata_cpmEntries, nothing_quit=>1) ;
  	if ($debug_script==1) {
  		print Dumper($cpm_entries);
  		print("Collecting names\n");
  	}
  	my @selection_of_cpm_names=();
  	my $cpm_names = $self->{snmp}->get_table(oid => $ciscocata_names, nothing_quit=>1);
  	if ($debug_script==1) {
  		print Dumper($cpm_names);
  		print("Collecting load values\n");
  	}
  	my $cpu_load_values = $self->{snmp}->get_multiple_table(oids =>  [
  										{oid => $ciscocata_cpmCPULoadAvg1min},
  										{oid => $ciscocata_cpmCPULoadAvg5min},
  										{oid => $ciscocata_cpmCPULoadAvg15min},
  	]) ;
  	if ($debug_script==1) {
  		print Dumper($cpu_load_values);
  		print("Starting snmp processing\n");
  	}
  	# Initialize exit code
  	my $exit_status='ok';
  	# How many entries
  	# my $members_count= keys $cpm_entries;
  	# my %catalyst_stack_details;
	foreach my $key ( keys %$cpm_entries) {
		#    .1.3.6.1.4.1.9.9.109.1.1.1.1.2.19 = INTEGER: 1000	   
	   	my @oid_list=split (/\./,$key);
	   	my $device_number=pop @oid_list; #19
	   	my $current_device="_" .$device_number; #_19
	   	my $current_value= $$cpm_entries{$key};  # 1.3.6.1.2.1.47.1.1.1.1.2 . The value 1000
	   	my $device_label=$$cpm_names{$ciscocata_names . "." . $current_value };
		# I need to use the method to create the device hash
		# $catalyst_stack_details{$current_device}{'label'}=$device_label;
	   	# $catalyst_stack_details={
		#		'_19' => {
		#			'label' => 'C9300-48U',
		#		},
		# }
		# Load
		my $load_1m_oid =	$ciscocata_cpmCPULoadAvg1min . '.' . $device_number;
		my $load_5m_oid =	$ciscocata_cpmCPULoadAvg5min . '.' . $device_number;
		my $load_15m_oid =	$ciscocata_cpmCPULoadAvg15min . '.' . $device_number;
		# $catalyst_stack_details{$current_device}{'load1m'}=$cpu_load_values{$load_1m_oid};
		# $catalyst_stack_details{$current_device}{'load5m'}=$cpu_load_values{$load_5m_oid};
		# $catalyst_stack_details{$current_device}{'load15m'}=$cpu_load_values{$load_15m_oid};
	   	# $catalyst_stack_details={
		#		'_19' => {
		#			'label' 	=> 'C9300-48U',
		#			'load1m'	=> 23,
		#			'load5m'	=> 18,
		#			'load15m'	=> 12				
		#		},
		# }
		$self->{output}->perfdata_add(
			label => $device_label . $current_device . "_load1m", 
			unit => undef,
			value => $$cpu_load_values{$load_1m_oid},
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'w_1m'),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'c_1m'),
            min => undef, 
            max => undef
        );
		$self->{output}->perfdata_add(
			label => $device_label . $current_device . "_load5m", 
			unit => undef,
			value => $$cpu_load_values{$load_5m_oid},
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'w_5m'),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'c_5m'),
            min => undef, 
            max => undef
        ); 
		$self->{output}->perfdata_add(
			label => $device_label . $current_device . "_load15m", 
			unit => undef,
			value => $$cpu_load_values{$load_15m_oid},
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'w_15m'),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'c_15m'),
            min => undef, 
            max => undef
        ); 
        #	Compare the value with the thresholds.  
        #	and set exit_status accordingly
        if (($exit_status eq 'ok') || ($exit_status eq 'warning')) {
        	my $check1m 	= $self -> {perfdata} -> threshold_check(value => $$cpu_load_values{$load_1m_oid}, threshold => [ { label => 'c_1m', 'exit_litteral' => 'critical' },{ label => 'w_1m', 'exit_litteral' => 'warning' }]);
        	my $check5m 	= $self -> {perfdata} -> threshold_check(value => $$cpu_load_values{$load_5m_oid}, threshold => [ { label => 'c_5m', 'exit_litteral' => 'critical' },{ label => 'w_5m', 'exit_litteral' => 'warning' }]);
        	my $check15m 	= $self -> {perfdata} -> threshold_check(value => $$cpu_load_values{$load_15m_oid}, threshold => [ { label => 'c_15m', 'exit_litteral' => 'critical' },{ label => 'w_15m', 'exit_litteral' => 'warning' }]);
        	my $plaintext 	= join('@', $check1m,$check5m,$check15m);
        	if ($plaintext =~ /critical/) {
        		$exit_status='critical';
        	} elsif (($exit_status eq 'ok')  && ($plaintext =~ /warning/ )) {
        		$exit_status='warning';
        	}
        } 

	}
	# Report exit Value and performance data	
	  
    $self->{output}->output_add(severity => $exit_status,
                                short_msg => $out_messages{$exit_status}
                                );
    $self->{output}->display();
    $self->{output}->exit(); 	
  }
 



1;

__END__

=head1 MODE

Reports CPU Load for  Cisco Catalyst (Catalyst L3 Switch Software (CAT9K_IOSXE), Version 16.6.4).

=over 8

=item B<--warning_*m>

Set warning threshold for status.
valid values: 1m, 5m, 15m

=item B<--critical_*m>

Set critical threshold for status.
valid values: 1m, 5m, 15m

=back

=cut
