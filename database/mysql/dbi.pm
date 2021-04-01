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

package database::mysql::dbi;

use base qw(centreon::plugins::dbi);

use strict;
use warnings;

sub is_mariadb {
    my ($self) = @_;

    return $self->{is_mariadb};
}

sub set_version {
    my ($self) = @_;

    $self->{is_mariadb} = 0;
    $self->{version} = $self->{instance}->get_info(18); # SQL_DBMS_VER
    # MariaDB: 5.5.5-10.1.36-MariaDB or 10.1.36-MariaDB
    if ($self->{version} =~ /([0-9\.]*?)-MariaDB/i) {
        $self->{version} = $1;
        $self->{is_mariadb} = 1;
    }
}

1;

__END__
