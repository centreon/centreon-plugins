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

package apps::pfsense::fauxapi::mode::backupfiles;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use POSIX;
use DateTime;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'backups.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'number of backups: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'time-last', nlabel => 'backups.time.last.seconds', set => {
                key_values => [ { name => 'since' }, { name => 'readable_since' } ],
                output_template => 'last backup time: %s',
                output_use => 'readable_since',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'ms' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(action => 'config_backup_list');

    $self->{global} = { total => 0 };
    my $recent_time = 0;
    if (defined($results->{data}->{backup_files})) {
        foreach (@{$results->{data}->{backup_files}}) {
            # 20200511Z094516
            return if ($_->{timestamp} !~ /^\s*(\d{4})(\d{2})(\d{2})Z(\d{2})(\d{2})(\d{2})/);

            my $dt = DateTime->new(
                year       => $1,
                month      => $2,
                day        => $3,
                hour       => $4,
                minute     => $5,
                second     => $6,
                time_zone   => 'GMT'
            );
            my $time = $dt->epoch();
            $recent_time = $time if ($recent_time < $time);

            $self->{global}->{total}++;
        }
    }

    if ($recent_time > 0) {
        $self->{global}->{since} = POSIX::strftime('%s', gmtime()) - $recent_time;
        $self->{global}->{readable_since} = centreon::plugins::misc::change_seconds(value => $self->{global}->{since});
    }
}

1;

__END__

=head1 MODE

Check backup files.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='total'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total', 'time-last'.

=back

=cut
