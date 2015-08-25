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

package hardware::pdu::apc::mode::load;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %states = (
    1 => ['phaseLoadNormal', 'OK'],
    2 => ['phaseLoadLow', 'WARNING'],
    3 => ['phaseLoadNearOverload', 'WARNING'],
    4 => ['phaseLoadOverload', 'CRITICAL'],
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_rPDULoadStatusLoad = '.1.3.6.1.4.1.318.1.1.12.2.3.1.1.2';
    my $oid_rPDULoadStatusLoadState = '.1.3.6.1.4.1.318.1.1.12.2.3.1.1.3';
    my $oid_rPDULoadStatusPhaseNumber = '.1.3.6.1.4.1.318.1.1.12.2.3.1.1.4';
    my $oid_rPDULoadStatusBankNumber = '.1.3.6.1.4.1.318.1.1.12.2.3.1.1.5';

    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_rPDULoadStatusLoad },
                                                            { oid => $oid_rPDULoadStatusLoadState },
                                                            { oid => $oid_rPDULoadStatusPhaseNumber },
                                                            { oid => $oid_rPDULoadStatusBankNumber },
                                                         ],
                                                         , nothing_quit => 1);

    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All phases are ok');

    foreach my $oid (keys %{$self->{results}->{$oid_rPDULoadStatusLoad}}) {    
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;

        my $status_load = $self->{results}->{$oid_rPDULoadStatusLoad}->{$oid} / 10;
        my $status_load_state = $self->{results}->{$oid_rPDULoadStatusLoadState}->{$oid_rPDULoadStatusLoadState . '.' . $instance};
        my $status_phase_number = $self->{results}->{$oid_rPDULoadStatusPhaseNumber}->{$oid_rPDULoadStatusPhaseNumber . '.' . $instance};
        my $status_bank_number = $self->{results}->{$oid_rPDULoadStatusBankNumber}->{$oid_rPDULoadStatusBankNumber . '.' . $instance};

        $self->{output}->output_add(long_msg => sprintf("Phase state on Bank %s is '%s' [Load : %dA]", 
                                            $status_bank_number, ${$states{$status_load_state}}[0], $status_load));
		$self->{output}->perfdata_add(label => 'bank' . $status_bank_number,
                                      value => $status_load,
				      unit => 'A',
                                      min => 0);
		if (${$states{$status_load_state}}[1] ne 'OK') {
             $self->{output}->output_add(severity => ${$states{$status_load_state}}[1],
                                        short_msg => sprintf("Phase state on Bank %s is '%s'", 
                                                             $status_bank_number, ${$states{$status_load_state}}[0],));
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check APC phase load.

=over 8

=back

=cut
    
