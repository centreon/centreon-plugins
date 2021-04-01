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

package apps::bluemind::local::custom::api;

use strict;
use warnings;
use centreon::plugins::ssh;
use centreon::plugins::misc;

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
    $options{options}->add_help(package => __PACKAGE__, sections => 'BLUEMIND OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{ssh} = centreon::plugins::ssh->new(%options);
    
    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub get_hostname {
    my ($self, %options) = @_;

    return defined($self->{option_results}->{hostname}) ? $self->{option_results}->{hostname} : 'local';
}

sub check_options {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        $self->{ssh}->check_options(option_results => $self->{option_results});
    }

    return 0;
}

sub execute_command {
    my ($self, %options) = @_;

    my $content;    
    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        ($content) = $self->{ssh}->execute(
            hostname => $self->{option_results}->{hostname},
            command => defined($self->{option_results}->{command}) && $self->{option_results}->{command} ne '' ? $self->{option_results}->{command} : $options{command},
            command_path => $self->{option_results}->{command_path},
            command_options => defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '' ? $self->{option_results}->{command_options} : undef,
            timeout => $self->{option_results}->{timeout},
            sudo => $self->{option_results}->{sudo}
        );
    } else {
        ($content) = centreon::plugins::misc::execute(
            output => $self->{output},
            options => { timeout => $self->{option_results}->{timeout} },
            sudo => $self->{option_results}->{sudo},
            command => defined($self->{option_results}->{command}) && $self->{option_results}->{command} ne '' ? $self->{option_results}->{command} : $options{command},
            command_path => $self->{option_results}->{command_path},
            command_options => defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '' ? $self->{option_results}->{command_options} : undef
        );
    }

    my $results = {};
    foreach (split /\n/, $content) {
        next if (! /$options{filter}/);
        my ($key, $value_str) = split /\s/;
        foreach my $value (split /,/, $value_str) {
            my ($field1, $field2) = split /=/, $value;
            $results->{$key}->{$field1} = $field2;
        }
    }
    
    return $results;
}

1;

__END__

=head1 NAME

bluemind

=head1 SYNOPSIS

bluemind

=head1 BLUEMIND OPTIONS

=over 8

=item B<--hostname>

Hostname to query.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

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
