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

package snmp_standard::mode::hardwaredevice;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

my %device_status = (
    1 => ["Device '%s' status is unknown", 'UNKNOWN'], 
    2 => ["Device '%s' status is running", 'OK'], 
    3 => ["Device '%s' status is warning", 'WARNING'], 
    4 => ["Device '%s' status is testing", 'OK'], 
    5 => ["Device '%s' status is down", 'CRITICAL'], 
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
                                short_msg => "All devices are ok.");
    
    my $oid_hrDeviceEntry = '.1.3.6.1.2.1.25.3.2.1';
    my $oid_hrDeviceDescr = '.1.3.6.1.2.1.25.3.2.1.3';
    my $oid_hrDeviceStatus = '.1.3.6.1.2.1.25.3.2.1.5';
    my $result = $self->{snmp}->get_table(oid => $oid_hrDeviceEntry, nothing_quit => 1);
    
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_hrDeviceStatus\.(.*)/);
        my $index = $1;
        my $status = $result->{$oid_hrDeviceStatus . '.' . $index};
        my $descr = centreon::plugins::misc::trim($result->{$oid_hrDeviceDescr . '.' . $index});
        
        $self->{output}->output_add(long_msg => sprintf(${$device_status{$status}}[0], $descr));
        if (!$self->{output}->is_status(value => ${$device_status{$status}}[1], compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => ${$device_status{$status}}[1],
                                        short_msg => sprintf(${$device_status{$status}}[0], $descr));
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check hardware devices (HOST-RESOURCES-MIB).

=over 8

=back

=cut
