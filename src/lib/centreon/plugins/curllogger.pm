#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package centreon::plugins::curllogger;

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    $self->{log_as_curl} = [];
    $self->{is_log_as_curl} = 0;

    # As this is only used for debugging purposes, we disable it if the ShellQuote
    # module is missing
    eval "use String::ShellQuote";
    if ($@) {
        $self->{is_log_as_curl} = -1;
    }

    $self;
}

sub init {
    my ($self, %options) = @_;

    $self->{log_as_curl} = [];
    return if $self->{is_log_as_curl} == -1;

    $self->{is_log_as_curl} = $options{enabled} || 0;
}

sub is_enabled {
    my ($self) = @_;

    return $self->{is_log_as_curl} == 1;
}

sub log {
    my ($self, @params) = @_;

    return unless $self->{is_log_as_curl} == 1 && @params;

    push @{$self->{log_as_curl}}, shell_quote(@params);
}

sub get_log {
    my ($self) = @_;

    return "curl ".join ' ', @{$self->{log_as_curl}};
}

# Conversion of some parameters manually passed to the set_extra_curl_opt function
# into their command-line equivalents. Only the parameters used in the plugin code
# are handled. If new parameters are added, this hash must be updated.
# The hash contains curl parameters CURLOPT_*. Its keys map to either a hash when
# multiple values are handled, or directly to an array when only one response is
# supported. The placeholder <value> is replaced by the provided value.
# Eg: "CURLOPT_POSTREDIR => CURL_REDIR_POST_ALL" will produce: --post301 --post302 --post303
#     "CURLOPT_SSL_VERIFYPEER => 0" will produce: --insecure
#     "CURLOPT_AWS_SIGV4 => 'osc'" will produce: --aws-sigv4 osc
our %curlopt_to_parameter = (
   'CURLOPT_POSTREDIR' => { 'CURL_REDIR_POST_ALL' => [ '--post301', '--post302', '--post303', ],
                            'CURL_REDIR_POST_301' => [ '--post301' ],
                            'CURL_REDIR_POST_302' => [ '--post302' ],
                            'CURL_REDIR_POST_303' => [ '--post303' ],
                          },
   'CURLOPT_SSLVERSION' => { 'CURL_SSLVERSION_TLSv1_0' => [ '--tlsv1.0' ],
                             'CURL_SSLVERSION_TLSv1_1' => [ '--tlsv1.1' ],
                             'CURL_SSLVERSION_TLSv1_2' => [ '--tlsv1.2' ],
                             'CURL_SSLVERSION_TLSv1_3' => [ '--tlsv1.3' ],
                           },
   'CURLOPT_SSL_VERIFYPEER' => { '0' => [ '--insecure' ] },
   'CURLOPT_SSL_VERIFYHOST' => { '0' => [ '--insecure' ] },

   'CURLOPT_AWS_SIGV4' => [ '--aws-sigv4', '<value>' ],
);

sub convert_curlopt_to_cups_parameter {
    my ($self, %options) = @_;

    my $key = $options{key};

    return unless exists $curlopt_to_parameter{$key};

    # we want an array of parameters
    my $parameters = ref $options{parameter} eq 'ARRAY' ? $options{parameter} : [ $options{parameter} ] ;

    my @cups_parameters ;
    if (ref $curlopt_to_parameter{$key} eq 'ARRAY') {
        @cups_parameters = map { s/<value>/$parameters->[0]/; $_ } @{$curlopt_to_parameter{$key}};
    } else {
        foreach my $parameter (@$parameters) {
            if (exists $curlopt_to_parameter{$key}->{$parameter}) {
                push @cups_parameters, @{$curlopt_to_parameter{$key}->{$parameter}};
            } elsif ($parameter =~ /^-/) {
                push @cups_parameters, $parameter;
            }
        }
    }
    $self->log($_) for @cups_parameters;
}

1;

