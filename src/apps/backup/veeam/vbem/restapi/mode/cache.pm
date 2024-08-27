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

package apps::backup::veeam::vbem::restapi::mode::cache;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'timeframe:s' => { name => 'timeframe' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{timeframe}) || $self->{option_results}->{timeframe} eq '') {
        $self->{option_results}->{timeframe} = 86400;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{custom}->cache_repository();
    $options{custom}->cache_backup_job_session(timeframe => $self->{option_results}->{timeframe});

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'Cache files created successfully'
    );
}

1;

__END__

=head1 MODE

Create cache files (other modes could use it with --cache-use option).

=over 8

=item B<--timeframe>

Timeframe to get BackupJobSession (in seconds. Default: 86400). 

=back

=cut
