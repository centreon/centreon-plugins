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

package cloud::aws::cloudtrail::mode::checktrailstatus;

use strict;
use warnings;

use base qw(centreon::plugins::mode);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'trail-name:s' => { name => 'trail_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!length($self->{option_results}->{trail_name})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --trail-name option.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    my $status = $options{custom}->cloudtrail_trail_status(
        trail_name => $self->{option_results}->{trail_name}
    );

    $self->{output}->output_add(severity => $status->{IsLogging} ? "ok" : "critical",
                                short_msg => sprintf("Trail is logging: %s", $status->{IsLogging}));
    $self->{output}->perfdata_add(label => "trail_is_logging", unit => '',
                                  value => sprintf("%s", $status->{IsLogging} ),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0
                                  );

    $self->{output}->display();
    $self->{output}->exit();
}


1;

=head1 MODE

Check cloudtrail trail status.

=over 8

=item B<--trail-name>

Filter by trail name.

=back

=cut