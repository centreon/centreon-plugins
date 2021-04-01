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

package centreon::common::emc::navisphere::mode::faults;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

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
    my $clariion = $options{custom};
    
    my $response = $clariion->execute_command(cmd => 'faults -list', secure_only => 1);
    chomp $response;
    
    if ($response =~ /The array is operating normally/msg) {
        $self->{output}->output_add(severity => 'ok',
                                    short_msg => 'The array is operating normally');
    } else {
        $self->{output}->output_add(long_msg => $response);
        $self->{output}->output_add(severity => 'critical',
                                    short_msg => 'Problem detected (see detailed output for more details');
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Detect faults on the array.

=over 8

=back

=cut
