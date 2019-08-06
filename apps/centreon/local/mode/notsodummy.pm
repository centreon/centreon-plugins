#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package apps::centreon::local::mode::notsodummy;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my %errors_service = (0 => 'OK', 1 => 'WARNING', 2 => 'CRITICAL', 3 => 'UNKNOWN');
my %errors_host = (0 => 'UP', 1 => 'DOWN');
my %errors_hash = ('UP' => 'OK', 'DOWN' => 'CRITICAL');

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "status-sequence:s"     => { name => 'status_sequence' },
        "host"                  => { name => 'host' },
        "restart-sequence"      => { name => 'restart_sequence' },
        "show-sequence"         => { name => 'show_sequence' },
        "output:s"              => { name => 'output' },
    });

    $self->{cache} = centreon::plugins::statefile->new(%options);
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{status_sequence}) || $self->{option_results}->{status_sequence} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --status option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{output}) || $self->{option_results}->{output} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --output option.");
        $self->{output}->option_exit();
    }

    foreach my $status (split(',', $self->{option_results}->{status_sequence})) {
        if (!defined($self->{option_results}->{host}) && $status !~ /^[0-3]$/ && $status !~ /ok|warning|critical|unknown/i) {
            $self->{output}->add_option_msg(short_msg => "Status should be in '0,1,2,3' or 'ok,warning,critical,unknown' (case isensitive).");
            $self->{output}->option_exit();
        }
        if (defined($self->{option_results}->{host}) && $status !~ /^[0-1]$/ && $status !~ /up|down/i) {
            $self->{output}->add_option_msg(short_msg => "Status should be in '0,1' or 'up,down' (case isensitive).");
            $self->{output}->option_exit();
        }
        push @{$self->{status_sequence}}, $status;
    }
    
    $self->{cache}->check_options(option_results => $self->{option_results});
}

sub get_next_status {
    my ($self, %options) = @_;

    my $index;
    my $has_cache_file = $options{statefile}->read(statefile => 'centreon_notsodummy_' .
        md5_hex(@{$self->{status_sequence}}) . '_' . md5_hex($self->{option_results}->{output}));

    if ($has_cache_file == 0 || $self->{option_results}->{restart_sequence}) {
        $index = 0;
        my $datas = { last_timestamp => time(), status_sequence => $self->{status_sequence}, status_sequence_index => $index };
        $options{statefile}->write(data => $datas);
    } else {
        $index = $options{statefile}->get(name => 'status_sequence_index');
        $index = ($index < scalar(@{$self->{status_sequence}} - 1)) ? $index + 1 : 0;
        my $datas = { last_timestamp => time(), status_sequence => $self->{status_sequence}, status_sequence_index => $index };
        $options{statefile}->write(data => $datas);
    }
    
    return $self->{status_sequence}[$index], $index;
}

sub get_sequence_output {
    my ($self, %options) = @_;

    my @sequence_output;

    my $i = 0;
    foreach my $status (split(',', $self->{option_results}->{status_sequence})) {
        $status = $errors_service{$status} if ($status =~ /^[0-3]$/ && !defined($self->{option_results}->{host}));
        $status = $errors_host{$status} if ($status =~ /^[0-1]$/ && defined($self->{option_results}->{host}));

        push @sequence_output, uc($status) if ($i == $options{index});
        push @sequence_output, lc($status) if ($i != $options{index});
        $i++
    }

    return join(',', @sequence_output);
}

sub run {
    my ($self, %options) = @_;

    my ($status, $index) = $self->get_next_status(statefile => $self->{cache});
    my $status_label = $status;
    if (defined($self->{option_results}->{host})) {
        $status_label = $errors_host{$status} if ($status =~ /^[0-1]$/);
        $status = $errors_host{$status} if ($status =~ /^[0-1]$/);
        $status = $errors_hash{uc($status)};
    } else {
        $status_label = $errors_service{$status} if ($status =~ /^[0-3]$/);
        $status = $errors_service{$status} if ($status =~ /^[0-3]$/);
    }
    my $output = $self->{option_results}->{output};
    $output .= ' [' . $self->get_sequence_output(index => $index) . ']' if ($self->{option_results}->{show_sequence});
    
    $self->{output}->output_add(
        severity => $status,
        short_msg => uc($status_label) . ': ' . $output
    );
    $self->{output}->perfdata_add(
        nlabel => 'sequence.index.position', value => ++$index,
        min => 1, max => scalar(@{$self->{status_sequence}})
    );
    $self->{output}->display(nolabel => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Do a not-so-dummy check.

=over 8

=item B<--status-sequence>

Comma separated sequence of statuses
from which the mode should pick is
return code from.
(Example: --status-sequence='ok,critical,ok,ok' or --status-sequence='up,up,down' --host)
(Should be numeric value between 0 and 3, or string in ok, warning, critical, unknown, up, down).

=item B<--host>

Host statuses.

=item B<--restart-sequence>

Restart the sequence from the beginning (ie. reset the sequence).

=item B<--show-sequence>

Show the sequence is the output.

=item B<--output>

Output to be returned.

=back

=cut
