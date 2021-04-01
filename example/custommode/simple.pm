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

package example::custommode::simple;

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;
    # $options{options} = options object
    # $options{output} = output object
    # $options{exit_value} = integer
    # $options{noptions} = integer

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => 
                    { "customarg:s@"       => { name => 'customarg' },
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'CUSTOM OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{custommode_name} = $options{custommode_name};
    
    $self->{customarg} = undef;
    
    return $self;
}

# Method to manage multiples
sub set_options {
    my ($self, %options) = @_;
    # options{options_result}

    $self->{option_results} = $options{option_results};
}

# Method to manage multiples
sub set_defaults {
    my ($self, %options) = @_;
    # options{default}
    
    # Manage default value
    foreach (keys %{$options{default}}) {
        if ($_ eq $self->{custommode_name}) {
            for (my $i = 0; $i < scalar(@{$options{default}->{$_}}); $i++) {
                foreach my $opt (keys %{$options{default}->{$_}[$i]}) {
                    if (!defined($self->{option_results}->{$opt}[$i])) {
                        $self->{option_results}->{$opt}[$i] = $options{default}->{$_}[$i]->{$opt};
                    }
                }
            }
        }
    }
}

sub check_options {
    my ($self, %options) = @_;
    # return 1 = ok still customarg
    # return 0 = no customarg left

    $self->{customarg} = (defined($self->{option_results}->{customarg})) ? shift(@{$self->{option_results}->{customarg}}) : undef;

    if (!defined($self->{customarg}) ||
        scalar(@{$self->{option_results}->{customarg}}) == 0) {
        return 0;
    }
    return 1;
}

##############
# Specific methods
##############
sub test {
    my ($self, %options) = @_;
    
    use Data::Dumper;
    print Data::Dumper::Dumper($self);
}

1;

__END__

=head1 NAME

My Custom global

=head1 SYNOPSIS

my custom class example

=head1 CUSTOM OPTIONS

=over 8

=item B<--customarg>

Argument test.

=back

=head1 DESCRIPTION

B<custom>.

=cut
