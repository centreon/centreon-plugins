#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package hardware::printers::standard::rfc3805::mode::coverstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

my %cover_status = (
    1 => ["'%s' status is other", 'UNKNOWN'], 
    3 => ["Cover '%s' status is open", 'WARNING'], 
    4 => ["Cover '%s' status is closed", 'OK'], 
    5 => ["Interlock '%s' status is open", 'WARNING'], 
    6 => ["Interlock '%s' status is closed", 'WARNING'], 
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
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
    $self->{snmp} = $options{snmp};

    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "All covers/interlocks are ok.");
    
    my $oid_prtCoverEntry = '.1.3.6.1.2.1.43.6.1.1';
    my $oid_prtCoverDescription = '.1.3.6.1.2.1.43.6.1.1.2';
    my $oid_prtCoverStatus = '.1.3.6.1.2.1.43.6.1.1.3';
    my $result = $self->{snmp}->get_table(oid => $oid_prtCoverEntry, nothing_quit => 1);
    
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_prtCoverStatus\.(\d+).(\d+)/);
        my ($hrDeviceIndex, $prtCoverIndex) = ($1, $2);
        my $instance = $hrDeviceIndex . '.' . $prtCoverIndex;
        my $status = $result->{$oid_prtCoverStatus . '.' . $instance};
        my $descr = centreon::plugins::misc::trim($result->{$oid_prtCoverDescription . '.' . $instance});
        
        $self->{output}->output_add(long_msg => sprintf(${$cover_status{$status}}[0], $descr));
        if (!$self->{output}->is_status(value => ${$cover_status{$status}}[1], compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => ${$cover_status{$status}}[1],
                                        short_msg => sprintf(${$cover_status{$status}}[0], $descr));
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check covers and interlocks of the printer.

=over 8

=back

=cut
