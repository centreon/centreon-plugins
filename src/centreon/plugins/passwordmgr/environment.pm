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

package centreon::plugins::passwordmgr::environment;

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class PasswordMgr: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class PasswordMgr: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    $options{options}->add_options(arguments => {
        'environment-map-option:s@' => { name => 'environment_map_option' }
    });
    $options{options}->add_help(package => __PACKAGE__, sections => 'ENVIRONMENT OPTIONS');

    $self->{output} = $options{output};    

    return $self;
}

sub manage_options {
    my ($self, %options) = @_;

    return if (!defined($options{option_results}->{environment_map_option}));

    foreach (@{$options{option_results}->{environment_map_option}}) {
        next if (! /^(.+?)=(.+)$/);
        my ($option, $map) = ($1, $2);

        $options{option_results}->{$option} = defined($ENV{$map}) ? $ENV{$map} : '';
        
        $option =~ s/-/_/g;
        if ($option =~ /\@(.*)/) {
            push @{$options{option_results}->{$1}}, $ENV{$map} if (defined($ENV{$map}));
        } elsif ($option =~ /\%(.*)/) {
            my $opt = $1;
            next if ($map !~ /^(.+?)=(.+)$/);
            $options{option_results}->{$opt}->{$1} = $ENV{$2} if (defined($ENV{$2}));
        } else {
            $options{option_results}->{$option} = defined($ENV{$map}) ? $ENV{$map} : '';
        }
    }
}

1;

__END__

=head1 NAME

Environment global

=head1 SYNOPSIS

environment class

=head1 ENVIRONMENT OPTIONS

=over 8

=item B<--environment-map-option>

Overload plugin option.

Examples:

For simple options:
--environment-map-option="snmp-community=SNMPCOMMUNITY"

For options that can be set multiple times (ex Jolokia plugins):
--environment-map-option="@username=THEUSERNAME"

For options that are used to set key/value couple (ex Collection plugins):
--environment-map-option="%constant=password=THEPASSWORD"

=back

=head1 DESCRIPTION

B<environment>.

=cut
