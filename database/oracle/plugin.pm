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

package database::oracle::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_sql);

sub new {
    my ($class, %options) = @_;
    
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
        'asm-diskgroup-usage'      => 'database::oracle::mode::asmdiskgroupusage',
        'connection-time'          => 'centreon::common::protocols::sql::mode::connectiontime',
        'connected-users'          => 'database::oracle::mode::connectedusers',
        'corrupted-blocks'         => 'database::oracle::mode::corruptedblocks',
        'dataguard'                => 'database::oracle::mode::dataguard',
        'data-files-status'        => 'database::oracle::mode::datafilesstatus',
        'datacache-hitratio'       => 'database::oracle::mode::datacachehitratio',
        'dictionary-cache-usage'   => 'database::oracle::mode::dictionarycacheusage',
        'event-waits-usage'        => 'database::oracle::mode::eventwaitsusage',
        'fra-usage'                => 'database::oracle::mode::frausage',
        'invalid-object'           => 'database::oracle::mode::invalidobject',
        'library-cache-usage'      => 'database::oracle::mode::librarycacheusage',
        'list-asm-diskgroups'      => 'database::oracle::mode::listasmdiskgroups',
        'list-tablespaces'         => 'database::oracle::mode::listtablespaces',
        'long-queries'             => 'database::oracle::mode::longqueries',
        'password-expiration'      => 'database::oracle::mode::passwordexpiration',
        'process-usage'            => 'database::oracle::mode::processusage',
        'redolog-usage'            => 'database::oracle::mode::redologusage',
        'rman-backup-problems'     => 'database::oracle::mode::rmanbackupproblems',
        'rman-backup-age'          => 'database::oracle::mode::rmanbackupage',
        'rman-online-backup-age'   => 'database::oracle::mode::rmanonlinebackupage',
        'rollback-segment-usage'   => 'database::oracle::mode::rollbacksegmentusage',
        'session-usage'            => 'database::oracle::mode::sessionusage',
        'sql'                      => 'centreon::common::protocols::sql::mode::sql',
        'sql-string'               => 'centreon::common::protocols::sql::mode::sqlstring',
        'tablespace-usage'         => 'database::oracle::mode::tablespaceusage',
        'tnsping'                  => 'database::oracle::mode::tnsping'
    );

    $self->{sql_modes}->{dbi} = 'database::oracle::dbi';
    $self->{sql_modes}->{sqlpluscmd} = 'database::oracle::sqlpluscmd';						 
						 
    return $self;
}

sub init {
    my ($self, %options) = @_;

    $self->{options}->add_options(arguments => {
        'hostname:s@'   => { name => 'hostname' },
        'port:s@'       => { name => 'port' },
        'sid:s'         => { name => 'sid' },
        'servicename:s' => { name => 'servicename' },
        'container:s'   => { name => 'container' }
    });

    $self->{options}->parse_options();
    my $options_result = $self->{options}->get_options();
    $self->{options}->clean();

    if (defined($options_result->{hostname})) {
        @{$self->{sqldefault}->{dbi}} = ();
        @{$self->{sqldefault}->{sqlpluscmd}} = ();
        for (my $i = 0; $i < scalar(@{$options_result->{hostname}}); $i++) {
            $self->{sqldefault}->{dbi}[$i] = { data_source => 'Oracle:host=' . $options_result->{hostname}[$i] };
            $self->{sqldefault}->{sqlpluscmd}[$i] = { hostname => $options_result->{hostname}[$i] };
            if (defined($options_result->{port}[$i])) {
                $self->{sqldefault}->{dbi}[$i]->{data_source} .= ';port=' . $options_result->{port}[$i];
                $self->{sqldefault}->{sqlpluscmd}[$i]->{port} = $options_result->{port}[$i];
            }
            if (defined($options_result->{sid}) && $options_result->{sid} ne '') {
                $self->{sqldefault}->{dbi}[$i]->{data_source} .= ';sid=' . $options_result->{sid};
	            $self->{sqldefault}->{sqlpluscmd}[$i]->{sid} = $options_result->{sid};
            }
            if (defined($options_result->{servicename}) && $options_result->{servicename} ne '') {
                $self->{sqldefault}->{dbi}[$i]->{data_source} .= ';service_name=' . $options_result->{servicename};
	            $self->{sqldefault}->{sqlpluscmd}[$i]->{service_name} = $options_result->{servicename};
            }
            $self->{sqldefault}->{dbi}[$i]->{container} = $options_result->{container};
            $self->{sqldefault}->{sqlpluscmd}[$i]->{container} = $options_result->{container};
        }
    }
    $self->SUPER::init(%options);
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Oracle Server.

=over 8

=item B<--hostname>

Hostname to query.

=item B<--port>

Database Server Port.

=item B<--sid>

Database SID.

=item B<--servicename>

Database Service Name.

=item B<--container>

Change container (does an alter session set container command).

=back

=cut
