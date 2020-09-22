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

package os::windows::local::mode::sessions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use XML::Simple;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output',  },
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

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "Sessions ";
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

sub read_qwinsta {
    my ($self, %options) = @_;

    $self->{output}->output_add(long_msg => $options{stdout}, debug => 1);
    if ($options{stdout} !~ /^(.*?)$options{config}->{created}/si) {
        $self->{output}->add_option_msg(short_msg => "Cannot find information in command output");
        $self->{output}->option_exit();
    }
    my $sessions = $1;

    my @lines = split /\n/, $sessions;
    my $header = shift @lines;

    my @position_wrap = ();
    while ($header =~ /(\s+(\S+))/g) {
        push @position_wrap, { begin => $-[1], word_begin => $-[2], end => $+[1], label => $2 };
    }
    my $session_data = [];
    foreach my $line (@lines) {
        my $data = {};
        for (my $pos = 0; $pos <= $#position_wrap; $pos++) {
            my $area;

            if (length($line) < $position_wrap[$pos]->{begin}) {
                $area = '';
            } else {
                if ($pos + 1 <= $#position_wrap) {
                    $area = substr($line, $position_wrap[$pos]->{begin}, ($position_wrap[$pos]->{end} - $position_wrap[$pos]->{begin}) + ($position_wrap[$pos + 1]->{word_begin} - $position_wrap[$pos]->{end}));
                } else {
                    $area = substr($line, $position_wrap[$pos]->{begin});
                }
            }

            $data->{$position_wrap[$pos]->{label}} = '-';
            while ($area =~ /([^\s]+)/g) {
                if (($-[1] >= $position_wrap[$pos]->{word_begin} - $position_wrap[$pos]->{begin} && $-[1] <= $position_wrap[$pos]->{end} - $position_wrap[$pos]->{begin}) 
                    ||
                    ($+[1] >= $position_wrap[$pos]->{word_begin} - $position_wrap[$pos]->{begin} && $+[1] <= $position_wrap[$pos]->{end} - $position_wrap[$pos]->{begin})) {
                    $data->{$position_wrap[$pos]->{label}} = $1;
                    last;
                }
            }
        }
        push @$session_data, $data;
    }

    return $session_data;
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

command can be localized by using a configuration file.
This parameter can be used to specify an alternative location for the configuration file

=item B<--language>

Set the language used in config file (default: 'en').

=item B<--command>

Command to get information (Default: 'qwinsta').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '/COUNTER').

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--filter-sessionname>

Filter session name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'sessions-created', 'sessions-disconnected', 
'sessions-reconnected', 'sessions-active', 'sessions-disconnected-current'.

=back

=cut
