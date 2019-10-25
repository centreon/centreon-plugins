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
                                "warning:s"		=> { name => 'warning', default => '6,4,2' },
                                "critical:s"	=> { name => 'critical', default => '8,6,4' },

                                });
	$self->{version} = '0.1';
    return $self;
}


sub check_options {
  	# From Docs - This will initialize all option names, if threshold sintax is ok
  	# as described on https://nagios-plugins.org/doc/guidelines.html#THRESHOLDFORMAT
  	my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    ($self->{warn1}, $self->{warn5}, $self->{warn15}) = split /,/, $self->{option_results}->{warning};
    ($self->{crit1}, $self->{crit5}, $self->{crit15}) = split /,/, $self->{option_results}->{critical};
    
    if (($self->{perfdata}->threshold_validate(label => 'warn1', value => $self->{warn1})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (1min) threshold '" . $self->{warn1} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn5', value => $self->{warn5})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (5min) threshold '" . $self->{warn5} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn15', value => $self->{warn15})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (15min) threshold '" . $self->{warn15} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit1', value => $self->{crit1})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (1min) threshold '" . $self->{crit1} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit5', value => $self->{crit5})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (5min) threshold '" . $self->{crit5} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit15', value => $self->{crit15})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (15min) threshold '" . $self->{crit15} . "'.");
       $self->{output}->option_exit();
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
  		'warning' => 'CPU Load exceeding at least one warning threshold.',
  		'critical' => 'CPU Load exceeding at least one critical threshold.'
  	);
  	# Retrieve information - REFERENCES to Hashes
  	my $cpm_entries = $self->{snmp}->get_table(oid => $ciscocata_cpmEntries, nothing_quit=>1) ;
  	my $cpu_load_values = $self->{snmp}->get_multiple_table(oids =>  [
  										{oid => $ciscocata_cpmCPULoadAvg1min},
  										{oid => $ciscocata_cpmCPULoadAvg5min},
  										{oid => $ciscocata_cpmCPULoadAvg15min},
  	]) ;
  	# Initialize exit code
  	my $exit_status='ok';
	foreach my $key ( keys %$cpm_entries) {
		#    .1.3.6.1.4.1.9.9.109.1.1.1.1.2.19 = INTEGER: 1000	   
	   	my @oid_list=split (/\./,$key);
	   	my $device_number=pop @oid_list; #19
	   	my $current_device="_" .$device_number; #_19
	   	my $current_value= $$cpm_entries{$key};  # 1.3.6.1.2.1.47.1.1.1.1.2 . The value 1000
	   	my $required_device_label=$ciscocata_names . "." . $current_value;
	   	my $label_reference = $self->{snmp}->get_leef(oids => [$required_device_label], nothing_quit=>1);
	    my $device_label=$$label_reference{$required_device_label };
		# Load
		my $load_1m_oid =	$ciscocata_cpmCPULoadAvg1min . '.' . $device_number;
		my $load_5m_oid =	$ciscocata_cpmCPULoadAvg5min . '.' . $device_number;
		my $load_15m_oid =	$ciscocata_cpmCPULoadAvg15min . '.' . $device_number;
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
			value => $$cpu_load_values{$ciscocata_cpmCPULoadAvg1min}{$load_1m_oid},
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn1'),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit1'),
            min => undef, 
            max => undef
        );
		$self->{output}->perfdata_add(
			label => $device_label . $current_device . "_load5m", 
			unit => undef,
			value => $$cpu_load_values{$ciscocata_cpmCPULoadAvg5min}{$load_5m_oid},
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn5'),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit5'),
            min => undef, 
            max => undef
        ); 
		$self->{output}->perfdata_add(
			label => $device_label . $current_device . "_load15m", 
			unit => undef,
			value => $$cpu_load_values{$ciscocata_cpmCPULoadAvg15min}{$load_15m_oid},
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn15'),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit15'),
            min => undef, 
            max => undef
        ); 
        #	Compare the value with the thresholds.  
        #	and set exit_status accordingly
        if (($exit_status eq 'ok') || ($exit_status eq 'warning')) {
        	my $check1m 	= $self -> {perfdata} -> threshold_check(value => $$cpu_load_values{$ciscocata_cpmCPULoadAvg1min}{$load_1m_oid}, threshold => [ { label => 'crit1', 'exit_litteral' => 'critical' },{ label => 'warn1', 'exit_litteral' => 'warning' }]);
        	my $check5m 	= $self -> {perfdata} -> threshold_check(value => $$cpu_load_values{$ciscocata_cpmCPULoadAvg5min}{$load_5m_oid}, threshold => [ { label => 'crit5', 'exit_litteral' => 'critical' },{ label => 'warn5', 'exit_litteral' => 'warning' }]);
        	my $check15m 	= $self -> {perfdata} -> threshold_check(value => $$cpu_load_values{$ciscocata_cpmCPULoadAvg15min}{$load_15m_oid}, threshold => [ { label => 'crit15', 'exit_litteral' => 'critical' },{ label => 'warn15', 'exit_litteral' => 'warning' }]);
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
