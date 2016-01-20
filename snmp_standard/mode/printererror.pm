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

package snmp_standard::mode::printererror;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %errors_printer = (
    0 => ["Printer is low paper", 'WARNING'], 
    1 => ["Printer has no paper", 'WARNING'],
    2 => ["Printer is low toner", 'WARNING'],
    3 => ["Printer has no toner", 'WARNING'], 
    4 => ["Printer has a door open", 'WARNING'], 
    5 => ["Printer is jammed", 'WARNING'], 
    6 => ["Printer is offline", 'WARNING'], 
    7 => ["Printer needs service requested", 'WARNING'], 
    
    8 => ["Printer has input tray missing", 'WARNING'], 
    9 => ["Printer has output tray missing", 'WARNING'], 
    10 => ["Printer has maker supply missing", 'WARNING'], 
    11 => ["Printer output is near full", 'WARNING'], 
    12 => ["Printer output is full", 'WARNING'], 
    13 => ["Printer has input tray empty", 'WARNING'], 
    14 => ["Printer is 'overdue prevent maint'", 'WARNING'], 
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

    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "Printer is ok.");
    
    my $oid_hrPrinterDetectedErrorState = '.1.3.6.1.2.1.25.3.5.1.2';
    my $result = $self->{snmp}->get_table(oid => $oid_hrPrinterDetectedErrorState, nothing_quit => 1);
    
    foreach (keys %$result) {
        my ($value1, $value2) = unpack('C', $result->{$_});
        
        foreach my $key (keys %errors_printer) {
            my ($byte_check, $pos);
            if ($key >= 8) {
                next if (!defined($value2));
                $byte_check = $value2;
                $pos = $key - 8;
            } else {
                $byte_check = $value1;
                $pos = $key
            }
        
            if (($byte_check & (1 << $pos)) &&
                (!$self->{output}->is_status(value => ${$errors_printer{$key}}[1], compare => 'ok', litteral => 1))) {
                $self->{output}->output_add(severity => ${$errors_printer{$key}}[1],
                                            short_msg => sprintf(${$errors_printer{$key}}[0]));
            }
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check printer errors (HOST-RESOURCES-MIB).

=over 8

=back

=cut
