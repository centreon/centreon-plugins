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

package centreon::common::smcli::mode::healthstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "storage-command:s"       => { name => 'storage_command', },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    my $smcli = $options{custom};

    my $response = $smcli->execute_command(cmd => $self->{option_results}->{storage_command});
    # IBM smcli: Storage Subsystem health status = optimal.
    # Dell smcli: Storage array health status = optimal.
    
    my $match_ok_regexp = 'health status.*optimal';
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("storage health status is optimal"));
    if ($response !~ /$match_ok_regexp/msi) {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("Some failures have been found (verbose mode for more details)"));
        $self->{output}->output_add(long_msg => $response);
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check health status

=over 8

=item B<--storage-command>

By default for Dell MD: 'show storageArray healthstatus;'
By default for IBM DS: 'show storageSubsystem healthstatus;'

=back

=cut
