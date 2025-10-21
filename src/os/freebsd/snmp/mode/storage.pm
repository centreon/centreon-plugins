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

package os::freebsd::snmp::mode::storage;

use base qw(snmp_standard::mode::storage);

use strict;
use warnings;

sub default_storage_type {
    my ($self, %options) = @_;

    return '^(hrStorageFixedDisk|hrStorageNetworkDisk|hrFSBerkeleyFFS|hrFSOther)$';
}

1;

__END__

=head1 MODE

Check storage system.

=over 8

=item B<--warning-usage>

Warning threshold.

=item B<--critical-usage>

Critical threshold.

=item B<--warning-access>

Warning threshold. 

=item B<--critical-access>

Critical threshold.
Check if storage is C<readOnly>: C<--critical-access=readOnly>

=item B<--add-access>

Check storage access (C<readOnly>, C<readWrite>).

=item B<--units>

Units of thresholds (default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--storage>

Define the storage filter on IDs (OID indexes, e.g.: 1,2,...). If empty, all storage systems will be monitored.
To filter on storage names, see C<--name>.

=item B<--name>

Allows to use storage name with option C<--storage> instead of storage OID index.

=item B<--regexp>

Allows to use regexp to filter storage (with option C<--name>).

=item B<--regexp-insensitive>

Allows to use regexp non case-sensitive (with C<--regexp>).

=item B<--path-best-match>

Allows to select best path mount point (with C<--name>).

=item B<--reload-cache-time>

Time in minutes before reloading cache file (default: 180).

=item B<--oid-filter>

Choose OID used to filter storage (default: C<hrStorageDescr>) (values: C<hrStorageDescr>, C<hrFSMountPoint>).

=item B<--oid-display>

Choose OID used to display storage (default: C<hrStorageDescr>) (values: C<hrStorageDescr>, C<hrFSMountPoint>).

=item B<--display-transform-src> B<--display-transform-dst>

Modify the storage name displayed by using a regular expression.

Example: adding C<--display-transform-src='dev' --display-transform-dst='run'> will replace all occurrences of C<dev> with C<run>.

=item B<--show-cache>

Display cache storage data.

=item B<--space-reservation>

Some filesystem has space reserved (like ext4 for root).
The value is in percent of total (default: none) (results like 'df' command).

=item B<--filter-duplicate>

Filter duplicate storages (in used size and total size).

=item B<--filter-storage-type>

Filter storage types with a regexp (default: C<'^(hrStorageFixedDisk|hrStorageNetworkDisk|hrFSBerkeleyFFS|hrFSOther)$'>).
C<hrFSOther> is needed when the default file system is ZFS.

=back

=cut