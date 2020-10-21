#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package apps::activedirectory::local::mode::dfsrbacklog;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'backlog', nlabel => 'backlog.file.count', set => {
                key_values => [ { name => 'backlog' } ],
                output_template => 'Backlog File Count : %s',
                perfdatas => [
                    { label => 'backlog', template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'sending-member:s'    => { name => 'sending_member' },
        'receiving-member:s'  => { name => 'receiving_member' },
        'replication-group:s' => { name => 'replication_group' },
        'replicated-folder:s' => { name => 'replicated_folder' },
        'timeout:s'           => { name => 'timeout', default => 30 }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);
    $self->{option_results}->{command} = 'dfsrdiag'; 
    $self->{option_results}->{command_options} = 'backlog ';

    if (!defined($self->{option_results}->{sending_member}) || $self->{option_results}->{sending_member} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify sending-member option.');
        $self->{output}->option_exit();
    }
    $self->{option_results}->{command_options} .= '/SendingMember:"' . $self->{option_results}->{sending_member} . '" ';

    if (defined($self->{option_results}->{receiving_member}) && $self->{option_results}->{receiving_member} ne '') {
        $self->{option_results}->{command_options} .= '/ReceivingMember:"' . $self->{option_results}->{receiving_member} . '" ';
    }

    if (!defined($self->{option_results}->{replication_group}) || $self->{option_results}->{replication_group} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify replication-group option.');
        $self->{output}->option_exit();
    }
    $self->{option_results}->{command_options} .= '/RGName:"' . $self->{option_results}->{replication_group} . '" ';

    if (!defined($self->{option_results}->{replicated_folder}) || $self->{option_results}->{replicated_folder} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify replicated-folder option.');
        $self->{output}->option_exit();
    }
    $self->{option_results}->{command_options} .= '/RFName:"' . $self->{option_results}->{replicated_folder} . '" ';
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options}
    );

    my $backlog = 0;
    my $pattern = 'Backlog\s+File\s+Count\s*:\s+(\d+)';
    $backlog = $1
        if ($stdout =~ /$pattern/si);

    $self->{global} = { backlog => $backlog };
}

1;

__END__

=head1 MODE

Check dfsr backlog.

=over 8

=item B<--sending-member>

Name of the member that is sending the replication data. (Mandatory)

=item B<--receiving-member>

Name of the member that is receiving the replication data. (NOT Mandatory)

=item B<--replication-group>

Name for the replication group. (Mandatory)

=item B<--replicated-folder>

Name name for the replicated folder. (Mandatory)

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--warning-backlog>

Threshold warning.

=item B<--critical-backlog>

Threshold critical.

=back

=cut
