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

package apps::microsoft::activedirectory::local::mode::netdom;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use Win32;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'domain:s'      => { name => 'domain' },
        'workstation:s' => { name => 'workstation' },
        'timeout:s'     => { name => 'timeout', default => 30 }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub netdom {
    my ($self, %options) = @_;

    my $netdom_cmd = 'netdom verify ';
    $netdom_cmd .= ' /Domain:' . $self->{option_results}->{domain} if (defined($self->{option_results}->{domain}) && $self->{option_results}->{domain} ne '');
    if (defined($self->{option_results}->{workstation})) {
        $netdom_cmd .= ' ' . $self->{option_results}->{workstation};
    } else {
        $netdom_cmd .= ' ' . Win32::NodeName();
    }
    
    my ($stdout, $exit_code) = centreon::plugins::misc::windows_execute(output => $self->{output},
                                                          timeout => $self->{option_results}->{timeout},
                                                          command => $netdom_cmd,
                                                          command_path => undef,
                                                          command_options => undef,
                                                          no_quit => 1);
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'Secure channel has been verified.');
    if ($exit_code != 0) {
        $self->{output}->output_add(long_msg => $stdout);
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => 'Secure channel had a problem (see additional info).');
    }
}

sub run {
    my ($self, %options) = @_;

    $self->netdom();   
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check the secure connection between a workstation and a domain controller (use 'netdom' command).

=over 8

=item B<--workstation>

Set the name of the workstation (Default: current hostname)

=item B<--domain>

Set the name of the domain (Default: current domain of the workstation)

=item B<--timeout>

Set timeout time for command execution (Default: 30 sec)

=back

=cut
