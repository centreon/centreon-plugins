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

package hardware::pdu::apc::mode::outlet;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_rPDUOutletStatusOutletName = '.1.3.6.1.4.1.318.1.1.12.3.5.1.1.2';
my $oid_rPDUOutletStatusOutletPhase = '.1.3.6.1.4.1.318.1.1.12.3.5.1.1.3';
my $oid_rPDUOutletStatusOutletState = '.1.3.6.1.4.1.318.1.1.12.3.5.1.1.4';
my $oid_rPDUOutletStatusOutletBank = '.1.3.6.1.4.1.318.1.1.12.3.5.1.1.6';
my $oid_rPDUOutletStatusLoad = '.1.3.6.1.4.1.318.1.1.12.3.5.1.1.7';

my %states = (
    1 => ['outletStatusOn', 'OK'],
    2 => ['outletStatusOff', 'CRITICAL'],
);

my %phases = (
	1 => '1',
    2 => '2',
	3 => '3',
    4 => '1-2',
	5 => '2-3',
    6 => '1-3',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
									"name:s"        => { name => 'name', },
									"regexp"		=> { name => 'use_regexp', },
                                });
    $self->{outlet_selected} = [];
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{result_names} = $self->{snmp}->get_table(oid => $oid_rPDUOutletStatusOutletName, nothing_quit => 1);
 
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{result_names}})) {
	next if ($oid !~ /\.([0-9]+)$/);
	my $instance = $1;
	# Get all without a name
	if (!defined($self->{option_results}->{name})) {
		push @{$self->{outlet_selected}}, $instance; 
		next;
	}
	$self->{result_names}->{$oid} = $self->{output}->to_utf8($self->{result_names}->{$oid});
	if (!defined($self->{option_results}->{use_regexp}) && $self->{result_names}->{$oid} eq $self->{option_results}->{name}) {
		push @{$self->{outlet_selected}}, $instance; 
	}
	if (defined($self->{option_results}->{use_regexp}) && $self->{result_names}->{$oid} =~ /$self->{option_results}->{name}/) {
		push @{$self->{outlet_selected}}, $instance;
	}
    }
    if (scalar(@{$self->{outlet_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No outlet found for name '" . $self->{option_results}->{name} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    $self->{snmp}->load(oids => [$oid_rPDUOutletStatusOutletPhase,
                                 $oid_rPDUOutletStatusOutletState,
                                 $oid_rPDUOutletStatusOutletBank,
                                 $oid_rPDUOutletStatusLoad],
                        instances => $self->{outlet_selected});
    my $result = $self->{snmp}->get_leef();
    if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All outlets are ok.');
    }

    foreach my $instance (@{$self->{outlet_selected}}) {    
        my $outlet_name = $self->{result_names}->{$oid_rPDUOutletStatusOutletName . '.' . $instance};
        my $outlet_phase = $result->{$oid_rPDUOutletStatusOutletPhase . '.' . $instance};
        my $outlet_state = $result->{$oid_rPDUOutletStatusOutletState . '.' . $instance};
        my $outlet_bank = $result->{$oid_rPDUOutletStatusOutletBank . '.' . $instance};
        my $outlet_load = $result->{$oid_rPDUOutletStatusLoad . '.' . $instance} / 10;
		
	$self->{output}->output_add(long_msg => sprintf("Outlet %s '%s' state is '%s' [Bank : %d , Phase : %d] [Load : %dA]", $instance, $outlet_name,
												${$states{$outlet_state}}[0], $outlet_bank, $phases{$outlet_phase}, $outlet_load));
	if (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp})) {
		$self->{output}->output_add(severity => ${$states{$outlet_state}}[1],
                                        short_msg => sprintf("Outlet %s '%s' state is '%s' [Bank : %d , Phase : %d]", $instance, $outlet_name,
                                                                 ${$states{$outlet_state}}[0], $outlet_bank, $phases{$outlet_phase}));
	} elsif (${$states{$outlet_state}}[1] ne 'OK') {
		$self->{output}->output_add(severity => ${$states{$outlet_state}}[1],
					short_msg => sprintf("Outlet %s '%s' state is '%s' [Bank : %d , Phase : %d]", $instance, $outlet_name,
								 ${$states{$outlet_state}}[0], $outlet_bank, $phases{$outlet_phase}));
	}
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check APC outlets.

=over 8

=item B<--name>

Set the outlet name.

=item B<--regexp>

Allows to use regexp to filter outlet (with option --name).

=back

=cut
    
