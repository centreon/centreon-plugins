#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package hardware::server::sun::sfxxk::mode::boards;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'showfailover',
        command_options => '-r 2>&1',
        command_path => '/opt/SUNWSMS/bin'
    );

    if ($stdout =~ /SPARE/i) {
        $self->{output}->output_add(
            severity => 'OK', 
            short_msg => "System Controller is in spare mode."
        );
        $self->{output}->display();
        $self->{output}->exit();
    } elsif ($stdout !~ /MAIN/i) {
        $self->{output}->output_add(long_msg => $stdout);
        $self->{output}->output_add(
            severity => 'UNKNOWN', 
            short_msg => "Command problems (see additional info)."
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    ($stdout) = $options{custom}->execute_command(
        command => 'showboards',
        command_options => '2>&1',
        command_path => '/opt/SUNWSMS/bin'
    );
    
    $self->{output}->output_add(
        severity => 'OK', 
        short_msg => "No problems detected."
    );
    if ($stdout =~ /^Location(.*)/ims) {
        #Location    Pwr    Type of Board   Board Status  Test Status   Domain
        #--------    ---    -------------   ------------  -----------   ------
        #SB0         Off    V3CPU           Assigned      Unknown       B
        #SB1         Off    V3CPU           Assigned      Unknown       A
        #SB2         Off    V3CPU           Available     Unknown       Isolated
        #IO11        Off    HPCI            Assigned      Failed        engB
        my @content = split(/\n/, $1);
        shift @content;
        foreach my $line (@content) {
            
            next if ($line =~ /^---/);
            next if ($line !~ /^\s*(.*?)\s{2}\s*(.*?)\s{2}\s*(.*?)\s{2}\s*(.*?)\s{2}\s*(.*?)\s{2}\s*(.*?)(\s{2}|$)/);
            my ($location, $pwr, $type_board, $board_status, $test_status, $domain) = ($1, $2, $3, $4, $5, $6);

            if ($test_status =~ /Failed|Degraded/i) {
                $self->{output}->output_add(
                    severity => 'CRITICAL', 
                    short_msg => "Error on board '$location' ($type_board) with test status '$test_status'"
                );
            }
        }
    }
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Sun 'sfxxk' boards.

=over 8

=back

=cut
