#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package apps::backup::netbackup::local::mode::drivecleaning;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'drive', type => 0 }
    ];

    $self->{maps_counters}->{drive} = [
        { label => 'cleaning', nlabel => 'drives.unclean.count', set => {
                key_values => [ { name => 'num_cleaning' }, { name => 'total' } ],
                output_template => '%d drives needs a reset mount time',
                perfdatas => [
                    { label => 'cleaning', template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'exec-only'     => { name => 'exec_only' },
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'tpconfig',
        command_options => '-l'
    );
    
    if (defined($self->{option_results}->{exec_only})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $stdout
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    $self->{drive} = { total => 0, num_cleaning => 0 };
    #Drive Name              Type      Mount Time  Frequency   Last Cleaned         Comment
    #**********              ****      **********  *********   ****************     *******
    #IBM.ULT3580-HH5.000     hcart2*   18.3        96          05:29 21/12/2015
    #IBM.ULT3580-HH5.002     hcart2*   36.8        0           11:10 20/12/2015
    my @lines = split /\n/, $stdout;
    splice(@lines, 0, 2);
    foreach my $line (@lines) {
        $line =~ /^(\S+)/;
        my $name = $1;

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        $self->{output}->output_add(long_msg => "drive '" . $name . "' checked.", debug => 1);

        $self->{drive}->{total}++;
        if ($line =~ /NEEDS CLEANING/i) {
            $self->{drive}->{num_cleaning}++;
        }
    }

    if (scalar(keys %{$self->{drive}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No drives found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check drive cleaning.

Command used: tpconfig -l

=over 8

=item B<--exec-only>

Print command output

=item B<--filter-name>

Filter drive name (can be a regexp).

=item B<--warning-*>

Warning threshold.
Can be: 'cleaning'.

=item B<--critical-*>

Critical threshold.
Can be: 'cleaning'.

=back

=cut
