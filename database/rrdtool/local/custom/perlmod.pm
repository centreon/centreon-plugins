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

package database::rrdtool::local::custom::perlmod;

use strict;
use warnings;
use RRDs;

sub new {
    my ($class, %options) = @_;
    my $self = {};
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
        });
    }

    $options{options}->add_help(package => __PACKAGE__, sections => 'PERLMOD OPTIONS', once => 1);

    $self->{output} = $options{output};

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options { return 0; }

sub get_identifier {
    my ($self, %options) = @_;

    return 'none';
}

sub query {
    my ($self, %options) = @_;

    my ($prints) = RRDs::graph(
        '/dev/null',
        '--start=' . $options{start},
        '--end=' . $options{end},
        '--imgformat=JSON',
        'DEF:v1=' . $options{rrd_file} . ':' . $options{ds_name} . ':AVERAGE',
        'LINE1:v1#00CC00:v1',
        'VDEF:v1max=v1,MAXIMUM',
        'VDEF:v1min=v1,MINIMUM',
        'VDEF:v1avg=v1,AVERAGE',
        'PRINT:v1max:MAX\:%6.2lf',
        'PRINT:v1min:MIN\:%6.2lf',
        'PRINT:v1avg:AVG\:%6.2lf'
    );

    if (RRDs::error()) {
        $self->{output}->add_option_msg(short_msg => "rrd graph error: " . RRDs::error());
        $self->{output}->option_exit();
    }

    my $results = {};
    foreach (@$prints) {
        if (/(MIN|MAX|AVG):\s*([0-9\.]+)/) {
            $results->{ lc($1) } = $2;
        }
    }

    return $results;
}

1;

__END__

=head1 NAME

perlmod rrds.

=head1 SYNOPSIS

perlmod rrds.

=head1 PERLMOD OPTIONS

no options.

=head1 DESCRIPTION

B<custom>.

=cut
