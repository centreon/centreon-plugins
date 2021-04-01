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

package hardware::ups::standard::rfc1628::snmp::mode::outputsource;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %outputsource_status = (
    1 => ['other', 'UNKNOWN'], 
    2 => ['none', 'CRITICAL'], 
    3 => ['normal', 'OK'], 
    4 => ['bypass', 'WARNING'],
    5 => ['battery', 'WARNING'],
    6 => ['booster', 'WARNING'],
    7 => ['reducer', 'WARNING'],
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
    
    my $oid_upsOutputSource = '.1.3.6.1.2.1.33.1.4.1.0';
    
    my $result = $self->{snmp}->get_leef(oids => [$oid_upsOutputSource], nothing_quit => 1);
    my $status = $result->{'.1.3.6.1.2.1.33.1.4.1.0'};
  
    $self->{output}->output_add(severity => ${$outputsource_status{$status}}[1],
                                short_msg => sprintf("Output source status is %s", ${$outputsource_status{$status}}[0]));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check output source status.

=over 8

=back

=cut
