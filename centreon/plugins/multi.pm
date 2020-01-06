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

package centreon::plugins::multi;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'modes-exec:s'   => { name => 'modes_exec' },
        'option-mode:s@' => { name => 'option_mode' },
    });
    $self->{options} = $options{options};

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{modes_exec})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --modes-exec option.");
        $self->{output}->option_exit(); 
    }
    $self->{options_mode_extra} = {};
    if (defined($self->{option_results}->{option_mode})) {
        foreach (@{$self->{option_results}->{option_mode}}) {
            next if (! /^(.+?),(.*)$/);
            $self->{options_mode_extra}->{$1} = [] if (!defined($self->{options_mode_extra}->{$1}));
            push @{$self->{options_mode_extra}->{$1}}, $2;
        }
    }

    $self->{modes} = $options{modes};
}

sub run {
    my ($self, %options) = @_;

    $self->{output}->parameter(attr => 'nodisplay', value => 1);
    $self->{output}->parameter(attr => 'noexit_die', value => 1);
    $self->{output}->use_new_perfdata(value => 1);

    my @modes = split /,/, $self->{option_results}->{modes_exec};
    foreach (@modes) {
        next if (!defined($self->{modes}->{$_}));
        eval {
            centreon::plugins::misc::mymodule_load(
                output => $self->{output},
                module => $self->{modes}->{$_}, 
                error_msg => "Cannot load module --mode $_"
            );
            @ARGV = (@{$self->{options_mode_extra}->{$_}}) if (defined($self->{options_mode_extra}->{$_}));
            $self->{output}->mode(name => $_);
            
            my $mode = $self->{modes}->{$_}->new(options => $self->{options}, output => $self->{output}, mode => $_);
            $self->{options}->parse_options();
            my $option_results = $self->{options}->get_options();
            $mode->check_options(option_results => $option_results, %options);
            $mode->run(%options);
        };
        if ($@) {
            $self->{output}->output_add(long_msg => 'eval result mode ' . $_ . ': ' . $@, debug => 1);
        }
    }

    $self->{output}->mode(name => 'multi');
    $self->{output}->parameter(attr => 'nodisplay', value => 0);
    $self->{output}->parameter(attr => 'noexit_die', value => 0);
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check multiple modes at once. You cannot set specific thresholds or filter options for modes.

=over 8

=item B<--modes-exec>

Which modes to select (separated by coma).
Example for linux: --modes-exec=cpu,memory,storage,interfaces

=item B<--option-mode>

Set options for a specifi mode (can be multiple).
Example interfaces and storage snmp:
--option-mode='interfaces,--statefile-dir=/tmp' --option-mode='interfaces,--add-traffic' --option-mode='storage,--statefile-dir=/tmp'

=back

=cut
