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

package storage::ibm::storwize::ssh::custom::api;

use strict;
use warnings;
use centreon::plugins::ssh;
use centreon::plugins::misc;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments =>  {                      
            'hostname:s'        => { name => 'hostname' },
            'timeout:s'         => { name => 'timeout', default => 30 },
            'sudo'              => { name => 'sudo' },
            'command:s'         => { name => 'command' },
            'command-path:s'    => { name => 'command_path' },
            'command-options:s' => { name => 'command_options' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'STORWIZE OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{ssh} = centreon::plugins::ssh->new(%options);
    
    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        $self->{ssh}->check_options(option_results => $self->{option_results});
    }

    centreon::plugins::misc::check_security_command(
        output => $self->{output},
        command => $self->{option_results}->{command},
        command_options => $self->{option_results}->{command_options},
        command_path => $self->{option_results}->{command_path}
    );

    return 0;
}

sub get_hasharray {
    my ($self, %options) = @_;

    my $result = [];
    return $result if ($options{content} eq '');

    $self->{output}->add_option_msg(long_msg => "Response: $options{content}", debug => 1);

    my ($header, @lines) = split /\n/, $options{content};
    my @header_names = split /$options{delim}/, $header;

    for (my $i = 0; $i <= $#lines; $i++) {
        my @content = split /$options{delim}/, $lines[$i];
        my $data = {};
        for (my $j = 0; $j <= $#header_names; $j++) {
            $data->{$header_names[$j]} = $content[$j];
        }
        push @$result, $data;
    }

    return $result;
}

sub execute_command {
    my ($self, %options) = @_;

    my $content;
    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        my ($command, $prefix, $suffix, $command_prefix, $command_suffix) = ('', '', '', '', '');
        # When wrap_command is set we surround the command with markers to be able to remove unwanted ssh banner
        if ($options{wrap_command}) {
            $prefix = '=========='.md5_hex(rand().'-'.time()).'==========';
            $suffix = '===============';
            $command_prefix = qq(echo '$prefix';);
            $command_suffix = qq(;echo '$suffix';);
        }
        $command = defined($self->{option_results}->{command}) && $self->{option_results}->{command} ne '' ? $self->{option_results}->{command} : $options{command};
        ($content) = $self->{ssh}->execute(
            hostname => $self->{option_results}->{hostname},
            command => $command_prefix.$command.$command_suffix,
            command_path => $self->{option_results}->{command_path},
            command_options => defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '' ? $self->{option_results}->{command_options} : undef,
            timeout => $self->{option_results}->{timeout},
            sudo => $self->{option_results}->{sudo}
        );

        if ($options{wrap_command}) {
            # Extract content between our markers
            $self->{output}->option_exit(short_msg => "Cannot find output markers")
                unless $content =~ /$prefix.*?\n(.*)$suffix/msi;
            $content = $1;
        }
    } else {
        if (!defined($self->{option_results}->{command}) || $self->{option_results}->{command} eq '') {
            $self->{output}->add_option_msg(short_msg => 'please set --hostname option for ssh connection (or --command for local)');
            $self->{output}->option_exit();
        }
        ($content) = centreon::plugins::misc::execute(
            output => $self->{output},
            options => { timeout => $self->{option_results}->{timeout} },
            sudo => $self->{option_results}->{sudo},
            command => $self->{option_results}->{command},
            command_path => $self->{option_results}->{command_path},
            command_options => defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '' ? $self->{option_results}->{command_options} : undef
        );
    }

    return $content;
}

1;

__END__

=head1 NAME

storwize

=head1 SYNOPSIS

storwize

=head1 STORWIZE OPTIONS

=over 8

=item B<--hostname>

Hostname to query.

=item B<--timeout>

Timeout in seconds for the command (default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information. Used it you have output in a file.

=item B<--command-path>

Command path.

=item B<--command-options>

Command options.

=back

=head1 DESCRIPTION

B<custom>.

=cut
