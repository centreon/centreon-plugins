# Copyright 2026-Present Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package DBI;
use strict;
use warnings;

our $errstr = '';

sub connect {
    my ($class, $dsn, $user, $pass, $opts) = @_;
    return bless {}, 'DBI::db';
}

package DBI::db;
use strict;
use warnings;

sub get_info { return '15.00.2000'; }

sub disconnect { return 1; }

sub errstr { return ''; }

sub prepare {
    my ($self, $query) = @_;
    return bless { query => $query }, 'DBI::st';
}

package DBI::st;
use strict;
use warnings;

sub execute { return 1; }

sub errstr { return ''; }

sub fetchall_arrayref {
    my ($self) = @_;
    my $file = $ENV{MOCK_DBI_DATA_FILE};
    return [] unless defined $file && -f $file;
    my $data = do $file;
    return defined $data ? $data : [];
}

sub fetchrow_array { return (); }

sub fetchrow_hashref {
    return { product_version => '15.00.2000' };
}

1;
