#
# Copyright 2025-Present Centreon (http://www.centreon.com/)
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

package apps::monitoring::zscaler::zdx::api::mode::application;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

# All filter parameters that can be used
my @_options = qw/application_id/;

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        ( map { ($_ =~ s/_/-/gr).':s' => { name => $_, default => '' } } @_options )
    });

    return $self;
}

sub prefix_app_output {
    my ($self, %options) = @_;

    return 'App "' . $options{instance_value}->{name} . '": ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_app_output' }
    ];
    
    $self->{maps_counters}->{global} = [
        {   label => 'total-users', nlabel => 'application.total-users.count',
            set => {
                key_values => [ { name => 'total_users' } ],
                output_template => 'Users count: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
              }
        },
        {   label => 'score', nlabel => 'application.score.value',
            set => {
                key_values => [ { name => 'score' } ],
                output_template => 'Score: %s',
                perfdatas => [
                    { template => '%d' }
                ]
              }
        }
    ];

}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);
    $self->{output}->option_exit(short_msg => "Option application_id cannot be empty") if $self->{option_results}->{application_id} eq '';
    $self->{application_id} = $self->{option_results}->{application_id};

}

sub manage_selection {
    my ($self, %options) = @_;

    my $app = $options{custom}->get_apps(application_id => $self->{application_id});
    $self->{output}->option_exit(short_msg => 'score not available in API response') unless defined($app->{score});
    $self->{output}->option_exit(short_msg => 'active_users not available in API response') unless defined($app->{stats}->{active_users});
    $self->{global}->{score} = $app->{score};
    $self->{global}->{name} = $app->{name};
    $self->{global}->{total_users} = $app->{stats}->{active_users};


}

1;

__END__

=head1 MODE

Monitor an application overall stats.

=over 8

=item B<--application-id>

Define the C<appid> (mandatory parameter) to monitor.

=back

=item B<--warning-score>

Threshold.

=item B<--critical-score>

Threshold.

=item B<--warning-total-users>

Threshold.

=item B<--critical-total-users>

Threshold.

=cut
