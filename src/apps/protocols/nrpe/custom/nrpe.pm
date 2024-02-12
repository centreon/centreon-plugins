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

package apps::protocols::nrpe::custom::nrpe;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::nrpe;

my %errors_num = (0 => 'OK', 1 => 'WARNING', 2 => 'CRITICAL', 3 => 'UNKNOWN');

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
        $options{options}->add_options(arguments => {
            'hostname:s'        => { name => 'hostname' },
            'nrpe-parse-output' => { name => 'nrpe_parse_output' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'CUSTOM MODE OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{nrpe} = centreon::plugins::nrpe->new(%options);
    
    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }

    $self->{nrpe}->check_options(option_results => $self->{option_results});

    return 0;
}

sub parse_plugin_output {
    my ($self, %options) = @_;

    my @lines = split(/\n/, $options{output});
    my $short = 'no output';
    my $line = shift(@lines);
    if (defined($line) && $line =~ /^(.*?)(?:\|(.*)|\Z)/) {
        $short = $1;
        if (defined($2)) {
            my $perf = $2;
            while ($perf =~ /(.*?)=([0-9\.]+)([^0-9;]+?)?([0-9.@;]+?)?(?:\s+|\Z)/g) {
                my ($label, $value, $unit, $extra) = ($1, $2, $3, $4);
                $label = centreon::plugins::misc::trim($label);
                $label =~ s/^'//;
                $label =~ s/'$//;
                my @extras = split(';', $extra);
                push @{$options{result}->{perf}}, { 
                    label => $label,
                    nlabel => $label,
                    unit => $unit,
                    value => $value,
                    warning => $extras[1],
                    critical => $extras[2],
                    min => $extras[3],
                    max => $extras[4]
                };
            }
        }
    }

    $options{result}->{message} = $short;
    $options{result}->{long_message} = [];
    foreach (@lines) {
        push @{$options{result}->{long_message}}, $_;
    }
}

sub format_result {
    my ($self, %options) = @_;

    my $result = {
        code => ($options{content}->{result_code} =~ /^[0-3]$/) ? $errors_num{$options{content}->{result_code}} : $options{content}->{result_code},
        message => $options{content}->{buffer},
        perf => []
    };

    if (defined($self->{option_results}->{nrpe_parse_output})) {
        $self->parse_plugin_output(result => $result, output => $options{content}->{buffer});
    }

    return $result;
}

sub request {
    my ($self, %options) = @_;
        
    my ($content) = $self->{nrpe}->request(check => $options{command}, arg => $options{arg});
    
    return $self->format_result(content => $content);
}

1;

__END__

=head1 NAME

NRPE protocol

=head1 CUSTOM MODE OPTIONS

NRPE protocol

=over 8

=item B<--hostname>

Remote hostname or IP address.

=item B<--nrpe-parse-output>

Parse remote plugin output.

=back

=head1 DESCRIPTION

B<custom>.

=cut
