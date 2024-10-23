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

package os::linux::local::mode::systemdjournal;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use Digest::MD5 qw(md5_hex);
use JSON::XS;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'entries', nlabel => 'journal.entries.count', set => {
                key_values => [ { name => 'entries' } ],
                output_template => 'Journal entries: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'unit:s'           => { name => 'unit' },
        'filter-message:s' => { name => 'filter_message' },
        'since:s'          => { name => 'since', default => 'cache' },
        'timezone:s'       => { name => 'timezone', default => 'local' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'cache_linux_local_' . $options{custom}->get_identifier()  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_message}) ? md5_hex($self->{option_results}->{filter_message}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{since}) ? md5_hex($self->{option_results}->{since}) : md5_hex('all'));

    my ($stdout_version) = $options{custom}->execute_command(
        command         => '/usr/bin/journalctl',
        command_options => '--version'
    );
    $stdout_version =~ /^systemd\s(\d+)\s/;
    my $journalctl_version = $1;

    my $command_options = '--output json --no-pager';
    # --output-field option has been added in version 236
    if ($journalctl_version >= 236) {
        $command_options .= '  --output-fields MESSAGE';
    };

    if (defined($self->{option_results}->{unit}) && $self->{option_results}->{unit} ne '') {
        $command_options .= ' --unit ' . $self->{option_results}->{unit};
    }

    if (defined($self->{option_results}->{since}) && $self->{option_results}->{since} ne '') {
        if ($self->{option_results}->{since} eq "cache") {
            my $last_timestamp = $self->read_statefile_key(key => 'last_timestamp');
            $last_timestamp = time() - (5 * 60) if (!defined($last_timestamp));
            my $dt = DateTime->from_epoch(epoch => $last_timestamp);
            $dt->set_time_zone($self->{option_results}->{timezone});
            $command_options .= ' --since "' . $dt->ymd . ' ' . $dt->hms . '"';
        } elsif ($self->{option_results}->{since} =~ /\d+/) {
            $command_options .= ' --since "' . $self->{option_results}->{since} . ' minutes ago"';
        }
    }

    my ($stdout) = $options{custom}->execute_command(
        command => 'journalctl',
        command_options => $command_options . ' 2>&1'
    );

    $self->{global} = { entries => 0 };

    my @lines = split /\n/, $stdout;
    foreach (@lines) {
        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($_);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
            $self->{output}->option_exit();
        }

        next if (defined($self->{option_results}->{filter_message}) && $self->{option_results}->{filter_message} ne '' &&
            $decoded->{MESSAGE} !~ /$self->{option_results}->{filter_message}/);
        
        $self->{global}->{entries}++;
    }
}

1;

__END__

=head1 MODE

Count journal entries.

Command used: journalctl --output json --output-fields MESSAGE --no-pager

Examples:

Look for sent emails by Postfix:

# perl centreon_plugins.pl --plugin=os::linux::local::plugin --mode=systemd-journal --unit=postfix.service
--filter-message='status=sent' --since=10 --change-short-output='Journal entries~Emails sent'
--change-perfdata='journal.entries.count,emails.sent.count'

OK: Emails sent: 17 | 'emails.sent.count'=17;;;0;

Look for Puppet errors:

# perl centreon_plugins.pl --plugin=os::linux::local::plugin --mode=systemd-journal
--unit=puppet.service --filter-message='error' --since=30

OK: Journal entries: 1 | 'journal.entries.count'=1;;;0;

Look for the number of Centreon Engine reloads

# perl centreon_plugins.pl --plugin=os::linux::local::plugin --mode=systemd-journal
--unit=centengine.service --filter-message='Reloaded.*Engine' --since=60
--change-short-output='Journal entries~Centreon Engine reloads over the last hour'
--change-perfdata='journal.entries.count,centreon.engine.reload.count'

OK: Centreon Engine reloads over the last hour: 0 | 'centreon.engine.reload.count'=0;;;0;

=over 8

=item B<--unit>

Only look for messages from the specified unit, i.e. the
name of the systemd service who created the message.

=item B<--filter-message>

Filter on message content (can be a regexp).

=item B<--since>

Defines the amount of time to look back at messages.
Can be minutes (example: 5 "minutes ago") or 'cache' to use the
timestamp from last execution. Default: 'cache'.

=item B<--timezone>

Defines the timezone to use for date/time conversion when using a timestamp from the cache.
Default: 'local'.

=item B<--warning-entries>

Thresholds to apply to the number of journal entries
found with the specified parameters.

=item B<--critical-entries>

Thresholds to apply to the number of journal entries
found with the specified parameters.

=back

=cut
