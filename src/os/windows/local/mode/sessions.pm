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

package os::windows::local::mode::sessions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use XML::Simple;
use centreon::plugins::constants qw(:counters);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, prefix_output => 'Sessions ' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'sessions-created', nlabel => 'sessions.created.total.count', set => {
                key_values => [ { name => 'sessions_created', diff => 1 } ],
                output_template => 'created: %s',
                perfdatas => [
                    { label => 'sessions_created', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'sessions-disconnected', nlabel => 'sessions.disconnected.total.count', set => {
                key_values => [ { name => 'sessions_disconnected', diff => 1 } ],
                output_template => 'disconnected: %s',
                perfdatas => [
                    { label => 'sessions_disconnected', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'sessions-reconnected', nlabel => 'sessions.reconnected.total.count', set => {
                key_values => [ { name => 'sessions_reconnected', diff => 1 } ],
                output_template => 'reconnected : %s',
                perfdatas => [
                    { label => 'sessions_reconnected', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'sessions-active', nlabel => 'sessions.active.current.count', set => {
                key_values => [ { name => 'sessions_active' } ],
                output_template => 'current active : %s',
                perfdatas => [
                    { label => 'sessions_active', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'sessions-disconnected-current', nlabel => 'sessions.disconnected.current.count', set => {
                key_values => [ { name => 'sessions_disconnected_current' } ],
                output_template => 'current disconnected : %s',
                perfdatas => [
                    { label => 'sessions_disconnected_current', template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'command:s'            => { name => 'command', default => 'qwinsta' },
        'command-path:s'       => { name => 'command_path' },
        'command-options:s'    => { name => 'command_options', default => '/COUNTER' },
        'timeout:s'            => { name => 'timeout', default => 30 },
        'filter-sessionname:s' => { name => 'filter_sessionname' },
        'config:s'             => { name => 'config' },
        'language:s'           => { name => 'language', default => 'en' }
    });
    
    return $self;
}

sub read_config {
    my ($self, %options) = @_;

    my $content_file = <<'END_FILE';
<?xml version="1.0" encoding="UTF-8"?>
<root>
    <qwinsta language="en">
        <created>Total sessions created</created>
        <disconnected>Total sessions disconnected</disconnected>
        <reconnected>Total sessions reconnected</reconnected>
        <activestate>Active</activestate>
        <disconnectedstate>Disc</disconnectedstate>
        <header_sessionname>SESSIONNAME</header_sessionname>
        <header_state>STATE</header_state>
    </qwinsta>
    <qwinsta language="fr">
        <created>Nombre total de sessions c.*?s</created>
        <disconnected>Nombre total de sessions d.*?connect.*?es</disconnected>
        <reconnected>Nombre total de sessions reconnect.*?es</reconnected>
        <activestate>Actif</activestate>
        <disconnectedstate>D.*?co</disconnectedstate>
        <header_sessionname>SESSION</header_sessionname>
        <header_state>^.*?TAT</header_state>
    </qwinsta>
    <qwinsta language="it">
        <created>Totale sessioni create</created>
        <disconnected>Totale sessioni disconnesse</disconnected>
        <reconnected>Totale sessioni riconnesse</reconnected>
        <activestate>Attivo</activestate>
        <disconnectedstate>Disc</disconnectedstate>
        <header_sessionname>NOMESESSIONE</header_sessionname>
        <header_state>STATO</header_state>
    </qwinsta>
    <qwinsta language="de">
        <created>Erstellte Sitzungen gesamt</created>
        <disconnected>Getrennte Sitzungen gesamt</disconnected>
        <reconnected>Erneut verbundene Sitzungen gesamt</reconnected>
        <activestate>Aktiv</activestate>
        <disconnectedstate>Getr\.</disconnectedstate>
        <header_sessionname>SITZUNGSNAME</header_sessionname>
        <header_state>STATUS</header_state>
    </qwinsta>
</root>
END_FILE

    if (defined($self->{option_results}->{config}) && $self->{option_results}->{config} ne '') {
        $content_file = do {
            local $/ = undef;
            if (!open my $fh, "<", $self->{option_results}->{config}) {
                $self->{output}->add_option_msg(short_msg => "Could not open file $self->{option_results}->{config} : $!");
                $self->{output}->option_exit();
            }
            <$fh>;
        };
    }

    my $content;
    eval {
        $content = XMLin($content_file, ForceArray => ['qwinsta'], KeyAttr => ['language']);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode xml response: $@");
        $self->{output}->option_exit();
    }

    if (!defined($content->{qwinsta}->{$self->{option_results}->{language}})) {
        $self->{output}->add_option_msg(short_msg => "Cannot find language '$self->{option_results}->{language}' in config file");
        $self->{output}->option_exit();
    }

    return $content->{qwinsta}->{$self->{option_results}->{language}};
}

# Split a line on whitespace.
# Returns the list of words, each one as [ value, column where it starts ].
sub split_words {
    my ($line) = @_;

    my @words;
    push @words, [ $1, $-[1] ] while ($line =~ /(\S+)/g);
    return @words;
}

# Spread the words found between two anchors over two optional adjacent columns,
# given the start column of their headers.
# Two words fill both columns. A single word goes to the column whose header
# starts closest to it (the right one on a tie, the left one if there is no
# right header).
# Returns the values of the two columns, undef for an empty cell.
sub fill_columns {
    my ($words, $left_pos, $right_pos) = @_;

    return map { $_->[0] } @$words if (@$words != 1);

    my ($value, $pos) = @{$words->[0]};
    return ($value, undef) if (!defined($right_pos) || $pos - $left_pos < $right_pos - $pos);
    return (undef, $value);
}

# Parse the sessions table of the qwinsta output. Example (labels are localized):
#
#    SESSIONNAME     USERNAME        ID STATE    TYPE    DEVICE
#    console         Administrator1  0 Active    wdcon
#   >rdp-tcp#1       User1           1 Active    wdtshare  rdpdr
#    rdp-tcp                         2 Listen    wdtshare
#                    User4           4 Disc              COM1
#
# Columns cannot be split on multiple spaces: some labels or values are separated
# by a single space ('ID STATE') and empty cells are left blank. So each line is
# split on any whitespace and the ID, always present, is used as an anchor:
#   - before the ID: SESSIONNAME and/or USERNAME (both optional),
#   - the ID and the STATE,
#   - after the STATE: TYPE and/or DEVICE (both optional).
# When only one of two optional columns is filled, the column is found from the
# position of the value compared to the headers (see fill_columns).
#
# Returns an array ref of hashes, one per session, keyed by the header labels.
# Missing values are set to '-'.
sub read_qwinsta {
    my ($self, %options) = @_;

    $self->{output}->output_add(long_msg => $options{stdout}, debug => 1);
    # The sessions table is everything before the counters section
    if ($options{stdout} !~ /^(.*?)$options{config}->{created}/si) {
        $self->{output}->add_option_msg(short_msg => "Cannot find information in command output");
        $self->{output}->option_exit();
    }
    my @lines = split(/\n/, $1);

    # The first line is the header: column labels and their start positions.
    # Labels fall back on the column index if the header is incomplete.
    my @header = split_words(shift(@lines));
    my @labels = map { defined($header[$_]) ? $header[$_]->[0] : $_ } (0..5);
    my @header_pos = map { $_->[1] } @header;

    my $sessions = [];
    foreach my $line (@lines) {
        # qwinsta prefixes the current session with '>' (e.g. '>rdp-tcp#1').
        # Replace it by a space, rather than removing it, so that the words keep
        # their position in the line, used to find their column.
        $line =~ s/^(\s*)>/$1 /;
        my @words = split_words($line);

        # The ID is the first number followed by a non-number (the state), within
        # the first 3 words. Lines without ID (blank lines, counters title) are skipped.
        my ($id_idx) = grep {
            $_ < $#words && $words[$_]->[0] =~ /^\d+$/ && $words[$_ + 1]->[0] !~ /^\d+$/
        } (0..2);
        next if (!defined($id_idx));

        my ($sessionname, $username) = fill_columns([ @words[0 .. $id_idx - 1] ], @header_pos[0, 1]);
        my ($id, $state) = map { $_->[0] } @words[$id_idx, $id_idx + 1];
        my ($type, $device) = fill_columns([ @words[$id_idx + 2 .. $#words] ], @header_pos[4, 5]);

        my @values = ($sessionname, $username, $id, $state, $type, $device);
        push @$sessions, { map { $labels[$_] => $values[$_] // '-' } (0..5) };
    }

    return $sessions;
}

sub read_qwinsta_counters {
    my ($self, %options) = @_;

    my $counters = {};
    $counters->{sessions_created} = $1
        if ($options{stdout} =~ /$options{config}->{created}.*?(\d+)/si);
    $counters->{sessions_disconnected} = $1
        if ($options{stdout} =~ /$options{config}->{disconnected}.*?(\d+)/si);
    $counters->{sessions_reconnected} = $1
        if ($options{stdout} =~ /$options{config}->{reconnected}.*?(\d+)/si);

    return $counters;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $config = $self->read_config();
    my ($stdout) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options}
    );

    my $datas = $self->read_qwinsta(stdout => $stdout, config => $config);
    my $counters = $self->read_qwinsta_counters(stdout => $stdout, config => $config);

    my ($active, $disconnected) = (0, 0);
    foreach my $session (@$datas) {
        if (defined($self->{option_results}->{filter_sessionname}) && $self->{option_results}->{filter_sessionname} ne '' &&
            $session->{$config->{header_sessionname}} !~ /$self->{option_results}->{filter_sessionname}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $session->{$config->{header_sessionname}} . "': no matching filter.", debug => 1);
            next;
        }

        my ($matching_active, $matching_discon) = (0, 0);
        foreach my $label (keys %$session) {
            $matching_active = 1 if ($label =~ /$config->{header_state}/ && 
                $session->{$label} =~ /$config->{activestate}/);
            $matching_discon = 1 if ($label =~ /$config->{header_state}/ && 
                $session->{$label} =~ /$config->{disconnectedstate}/);  
        }

        if ($matching_active == 1 || $matching_discon == 1) {
            $active++ if ($matching_active == 1);
            $disconnected++ if ($matching_discon == 1);
            my $output = '';
            $output .= " [$_ => $session->{$_}]" for (sort keys %$session);
            $self->{output}->output_add(long_msg => $output);
        }
    }

    $self->{global} = { %$counters, sessions_active => $active, sessions_disconnected_current => $disconnected };

    $self->{cache_name} = 'windows_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check sessions.

=over 8

=item B<--config>

The command can be localized by using a configuration file.
This parameter can be used to specify an alternative location for the configuration file.

=item B<--language>

Set the language used in config file (default: 'en').

=item B<--command>

Command to get information (default: 'qwinsta').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (default: none).

=item B<--command-options>

Command options (default: '/COUNTER').

=item B<--timeout>

Timeout in seconds for the command (default: 30).

=item B<--filter-sessionname>

Filter session name (can be a regexp).

=item B<--warning-sessions-created>

Threshold for the number of sessions created since the last check.

=item B<--critical-sessions-created>

Threshold for the number of sessions created since the last check.

=item B<--warning-sessions-disconnected>

Threshold for the number of sessions disconnected since the last check.

=item B<--critical-sessions-disconnected>

Threshold for the number of sessions disconnected since the last check.

=item B<--warning-sessions-reconnected>

Threshold for the number of sessions reconnected since the last check.

=item B<--critical-sessions-reconnected>

Threshold for the number of sessions reconnected since the last check.

=item B<--warning-sessions-active>

Threshold for the number of currently active sessions.

=item B<--critical-sessions-active>

Threshold for the number of currently active sessions.

=item B<--warning-sessions-disconnected-current>

Threshold for the number of currently disconnected sessions.

=item B<--critical-sessions-disconnected-current>

Threshold for the number of currently disconnected sessions.

=back

=cut
