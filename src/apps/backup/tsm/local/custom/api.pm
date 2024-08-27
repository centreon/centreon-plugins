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

package apps::backup::tsm::local::custom::api;

use base qw(centreon::plugins::script_custom::cli);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>  {                      
        'tsm-hostname:s' => { name => 'tsm_hostname' },
        'tsm-username:s' => { name => 'tsm_username' },
        'tsm-password:s' => { name => 'tsm_password' }
    });
    
    $options{options}->add_help(package => __PACKAGE__, sections => 'TSM CLI OPTIONS', once => 1);
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{tsm_hostname}) || $self->{option_results}->{tsm_hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to set tsm-hostname option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{tsm_username}) || $self->{option_results}->{tsm_username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to set tsm-username option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{tsm_password})) {
        $self->{output}->add_option_msg(short_msg => "Need to set tsm-password option.");
        $self->{output}->option_exit();
    }
 
    return 0;
}

sub get_tsm_id {
    my ($self, %options) = @_;
    
    return $self->{option_results}->{tsm_hostname} . '_' . $self->{option_results}->{tsm_username} . '_' . $self->{option_results}->{tsm_password};
}

sub execute_command {
    my ($self, %options) = @_;

    my $command = 'dsmadmc';
    my $command_options = "-comma -dataonly=yes -SERVER=\"$self->{option_results}->{tsm_hostname}\" -ID=\"$self->{option_results}->{tsm_username}\" -PASSWORD=\"$self->{option_results}->{tsm_password}\" -TAB \"$options{query}\"";;

    my ($stdout, $exit_code) = $self->SUPER::execute_command(
        %options,
        command => $command,
        command_options => $command_options,
        no_quit => 1
    );

    # 11 is for: ANR2034E SELECT: No match found using this criteria.
    if ($exit_code != 0 && $exit_code != 11) {
        $self->{output}->output_add(long_msg => $stdout);
        $self->{output}->add_option_msg(short_msg => "Execution command issue (details).");
        $self->{output}->option_exit();
    }

    $self->{output}->output_add(long_msg => $stdout, debug => 1);
    return $stdout;
}

1;

__END__

=head1 NAME

tsm cli

=head1 SYNOPSIS

my tsm cli

=head1 TSM CLI OPTIONS

=over 8

=item B<--tsm-hostname>

TSM hostname to query (required).

=item B<--tsm-username>

TSM username (required).

=item B<--tsm-password>

TSM password (required).

=back

=head1 DESCRIPTION

B<custom>.

=cut
