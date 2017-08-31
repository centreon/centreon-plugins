#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package apps::java::awa::jmx::jolokia_extend;

use strict;
use warnings;
use JMX::Jmx4Perl::Request;

use POSIX qw(strftime);
use Time::Local;

use Data::Dumper;

use centreon::common::protocols::jmx::custom::jolokia;
our @ISA = qw(centreon::common::protocols::jmx::custom::jolokia);

my $debug = 0;

sub match_input {
    my ($self, $key, @input) = @_;

    my @selected = grep(/^$key$/, @input);

    if (@selected) {

        #foreach (@selected) {print "'$_'\n";}
        return (1, $key);
    }
    else {
        return (0, $key);
    }
}

sub get_data_disco {
    my ($self, %params) = @_;

    my %options = %{ $params{'-option_results'} };

    my $pattern_name = '*';
    my $pattern_side
        = defined($options{'mbean_pattern_side'})
        ? $options{'mbean_pattern_side'}
        : 'SIDE';
    my $pattern_type = '*';
    my $pattern      = "Automic:name=$pattern_name," . "side=$pattern_side," . "type=$pattern_type";

    my %output = ();

    eval { local $SIG{__DIE__} = 'IGNORE'; };

    if (!defined($self->{'jmx4perl'})) {
        $self->connect();
    }

    my $mbeans = $self->{jmx4perl}->search($pattern);

    for my $mbean (@$mbeans) {

        $mbean =~ s/Automic:(.*)/$1/g;
        $mbean =~ s/name=(.*)/$1/g;
        $mbean =~ s/side=(.*)/$1/g;
        $mbean =~ s/type=(.*)/$1/g;
        my ($name, $side, $type) = split /,/, $mbean;

        my %extend_infos;
        $extend_infos{'side'}                   = $side;
        $extend_infos{'type'}                   = $type;
        $output{'disco'}{$name}{'extend_infos'} = \%extend_infos;
    }

    print Data::Dumper->Dump([ \%output ], [qw(*output)]) if $debug;
    return \%output;
}

sub get_data {
    my ($self, %params) = @_;

    my %options = %{ $params{'-option_results'} };
    my @input   = @{ $params{'-data'} };

    my $max_depth   = defined($options{'max_depth'})   ? $options{'max_depth'}   : 5;
    my $max_objects = defined($options{'max_objects'}) ? $options{'max_objects'} : 100;
    my $max_collection_size
        = defined($options{'max_collection_size'})
        ? $options{'max_collection_size'}
        : 50;

    my $pattern_name
        = defined($options{'mbean_pattern_name'})
        ? $options{'mbean_pattern_name'}
        : 'NAME';
    my $pattern_side
        = defined($options{'mbean_pattern_side'})
        ? $options{'mbean_pattern_side'}
        : 'SIDE';
    my $pattern_type
        = defined($options{'mbean_pattern_type'})
        ? $options{'mbean_pattern_type'}
        : 'TYPE';

    my $pattern = "Automic:name=$pattern_name," . "side=$pattern_side," . "type=$pattern_type";
    my %output  = ();

    eval { local $SIG{__DIE__} = 'IGNORE'; };

    if (!defined($self->{'jmx4perl'})) {
        $self->connect();
    }

    my $mbeans = $self->{jmx4perl}->search($pattern);

    for my $mbean (@$mbeans) {
        my $request = JMX::Jmx4Perl::Request->new(
            READ, $mbean, undef,
            {   maxDepth          => $max_depth,
                maxObjects        => $max_objects,
                maxCollectionSize => $max_collection_size,
                ignoreErrors      => 1,
            }
        );
        my $response = $self->{'jmx4perl'}->request($request);
        if ($response->is_error) {
            print "ERROR: " . $response->error_text . "\n";
            print JMX::Jmx4Perl::Util->dump_value($response, { format => 'DATA' });
        }
        else {
            my $values = $response->value;
            if (keys %$values) {
                for my $a (keys %$values) {
                    my ($ret, $k) = $self->match_input($a, @input);
                    next unless $ret;

                    my $val = $values->{$a};
                    if (JMX::Jmx4Perl::Util->is_object_to_dump($val)) {
                        my $v = JMX::Jmx4Perl::Util->dump_value($val, { format => 'DATA' });
                        $v =~ s/^\s*//;
                        $output{$k} = $v;
                    }
                    else {
                        if (my $scal = JMX::Jmx4Perl::Util->dump_scalar($val)) {
                            $output{$k} = $scal;
                        }
                        else {
                            $output{$k} = undef;
                        }
                    }
                }
            }
        }
    }

    # print Data::Dumper->Dump([\%output], [qw(*output)]);
    return \%output;
}

1;

__END__

=head1 NAME

JOlokia connector library

=head1 SYNOPSIS

my jolokia connector

=head1 JOLOKIA OPTIONS

=over 8

=item B<--url>

Url where the jolokia agent is deployed (required).
Example: http://localhost:8080/jolokia

=item B<--timeout>  

Timeout in seconds for HTTP requests (Defaults: 30 seconds)

=item B<--username>

Credentials to use for the HTTP request

=item B<--password>

Credentials to use for the HTTP request

=item B<--proxy-url>

Optional HTTP proxy to use.

=item B<--proxy-username>

Credentials to use for the proxy

=item B<--proxy-password>

Credentials to use for the proxy

=item B<--target-url>

Target to use (if you use jolokia agent as a proxy in --url option).

=item B<--target-username>

Credentials to use for the target

=item B<--target-password>

Credentials to use for the target

=back

=head1 DESCRIPTION

B<custom>.

=cut
