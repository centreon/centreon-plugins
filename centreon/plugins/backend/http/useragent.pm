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

package centreon::plugins::backend::http::useragent;

use strict;
use warnings;
use base 'LWP::UserAgent';

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    $self = LWP::UserAgent::new(@_);
    $self->agent("centreon::plugins::backend::http::useragent");

    $self->{credentials} = $options{credentials} if defined($options{credentials});
    $self->{username} = $options{username} if defined($options{username});
    $self->{password} = $options{password} if defined($options{password});

    return $self;
}

sub get_basic_credentials {
    my($self, $realm, $uri, $proxy) = @_;
    return if $proxy;
    return $self->{username}, $self->{password} if $self->{credentials} and wantarray;
    return $self->{username} . ':' . $self->{password} if $self->{credentials};
    return undef;
}

1;
