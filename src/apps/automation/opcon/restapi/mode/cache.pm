#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::automation::opcon::restapi::mode::cache;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use DateTime;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'timeframe:s' => { name => 'timeframe', default => '3600' },
        'timezone:s'  => { name => 'timezone' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{option_results}->{timezone} = 'UTC' if (!defined($self->{option_results}->{timezone}) || $self->{option_results}->{timezone} eq '');
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{custom}->cache_machines();
    $options{custom}->cache_masterJobs();

    my $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
    my $dt = DateTime->from_epoch(epoch => time(), %$tz);
    my $to = sprintf("%02d-%02d-%d", $dt->day, $dt->month, $dt->year);
    $dt->subtract(seconds => $self->{option_results}->{timeframe});
    my $from = sprintf("%02d-%02d-%d", $dt->day, $dt->month, $dt->year);
    $options{custom}->cache_jobHistories(
        get_param => [
            'from=' . $from,
            'to=' . $to
        ]
    );

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

=item B<--timezone>

Timezone options. Default is 'UTC'.

=item B<--timeframe>

Define timeframe to query jobHistories endpoint (default: 3600)

=back

=cut
