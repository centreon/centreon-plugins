#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package cloud::aws::custom::awscli;

use strict;
use warnings;
use JSON;
use centreon::plugins::misc;

sub new {
    my ( $class, %options ) = @_;
    my $self = {};
    bless $self, $class;

    # $options{options} = options object
    # $options{output} = output object
    # $options{exit_value} = integer
    # $options{noptions} = integer

    if ( !defined( $options{output} ) ) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if ( !defined( $options{options} ) ) {
        $options{output}->add_option_msg( short_msg => "Class Custom: Need to specify 'options' argument." );
        $options{output}->option_exit();
    }

    if ( !defined( $options{noptions} ) ) {
        $options{options}->add_options( arguments => {
            "region:s"          => { name => 'region' },
            "command:s"         => { name => 'command', default => 'aws' },
            "command-path:s"    => { name => 'command_path' },
            "sudo"              => { name => 'sudo' },
        } );
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'AWSCLI OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{mode}   = $options{mode};
    return $self;
}

# Method to manage multiples
sub set_options {
    my ( $self, %options ) = @_;

    # options{options_result}

    $self->{option_results} = $options{option_results};
}

# Method to manage multiples
sub set_defaults {
    my ( $self, %options ) = @_;

    # Manage default value
    foreach ( keys %{ $options{default} } ) {
        if ( $_ eq $self->{mode} ) {
            for ( my $i = 0 ; $i < scalar( @{ $options{default}->{$_} } ) ; $i++ )
            {
                foreach my $opt ( keys %{ $options{default}->{$_}[$i] } ) {
                    if ( !defined( $self->{option_results}->{$opt}[$i] ) ) {
                        $self->{option_results}->{$opt}[$i] = $options{default}->{$_}[$i]->{$opt};
                    }
                }
            }
        }
    }
}

sub check_options {
    my ($self, %options) = @_;
    return 0;
}

sub execReq {
    my ($self, $options) = @_;
    my $jsoncontent;

    if (!defined($options->{output})) {
        $options->{output} = 'json';
    }

    my $json = JSON->new;
    my $json_encoded = $options->{command} . " " . $options->{subcommand};
    if (defined($self->{option_results}->{region})) {
        $json_encoded = $json_encoded . " --region '". $self->{option_results}->{region} . "'";
    }
    if (defined($options->{json})) {
        $json_encoded = $json_encoded . " --cli-input-json '" . $json->encode( $options->{json} ) . "'";
    }
    
    $self->{option_results}->{timeout} = 30;
    
    if ($options->{output} eq 'text') {
        $self->{stdout} = centreon::plugins::misc::execute(
            output => $self->{output},
            options => $self->{option_results},
            sudo => $self->{option_results}->{sudo},
            command => $self->{option_results}->{command},
            command_path => $self->{option_results}->{command_path},
            command_options => $json_encoded
        );
        my @return = split /\n/, $self->{stdout};
        $jsoncontent = $json->encode( [@return] );
    } else {
        $jsoncontent = centreon::plugins::misc::execute(
            output => $self->{output},
            options => $self->{option_results},
            sudo => $self->{option_results}->{sudo},
            command => $self->{option_results}->{command},
            command_path => $self->{option_results}->{command_path},
            command_options => $json_encoded
        );
    }
    if ($? > 0) {
        $self->{output}->add_option_msg( short_msg => "Cannot run aws" );
        $self->{output}->option_exit();
    }
    eval { $self->{command_return} = $json->decode($jsoncontent); };
    if ($@) {
        $self->{output}->add_option_msg( short_msg => "Cannot decode json answer" );
        $self->{output}->option_exit();
    }
    return $self->{command_return};
}

1;

__END__

=head1 NAME

AWS CLI API

=head1 SYNOPSIS

AWS cli API custom mode

=over 8

=item B<--region>

(optional) The region to use (should be configured directly in aws).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

(optional) Command to get information (Default: 'aws').

=item B<--command-path>

(optional) Command path (Default: none).

=back

=head1 DESCRIPTION

B<custom>.

=cut
