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

package apps::centreon::local::mode::dummy;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %errors_num = (0 => 'OK', 1 => 'WARNING', 2 => 'CRITICAL', 3 => 'UNKNOWN');

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "status:s"    => { name => 'status' },
                                  "output:s"    => { name => 'output' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{status}) || ($self->{option_results}->{status} !~ /^[0-3]$/ &&
        $self->{option_results}->{status} !~ /ok|warning|critical|unknown/i)) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --status option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{output}) || $self->{option_results}->{output} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --output option.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    my $status = $self->{option_results}->{status};
    $status = $errors_num{$status} if $status =~ /^[0-3]$/;
    
    $self->{output}->output_add(severity => $status,
                                short_msg => $self->{option_results}->{output});
    $self->{output}->display(force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Do a dummy check.

=over 8

=item B<--status>

Status to be returned (Should be numeric value between 0 and 3, or string in ok, warning, critical, unknown).

=item B<--output>

Output to be returned.

=back

=cut
