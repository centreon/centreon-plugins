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

package database::sap::hana::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_sql);

sub new {
    my ($class, %options) = @_;
    
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
        'blocked-transactions' => 'database::sap::hana::mode::blockedtransactions',
        'connected-users'      => 'database::sap::hana::mode::connectedusers',
        'connection-time'      => 'centreon::common::protocols::sql::mode::connectiontime',
        'disk-usage'           => 'database::sap::hana::mode::diskusage',
        'host-memory'          => 'database::sap::hana::mode::hostmemory',
        'host-cpu'             => 'database::sap::hana::mode::hostcpu',
        'sql'                  => 'centreon::common::protocols::sql::mode::sql',
        'volume-usage'         => 'database::sap::hana::mode::volumeusage',
    );

    return $self;
}

sub init {
    my ($self, %options) = @_;

    $self->{options}->add_options(
        arguments => {
            'servernode:s@' => { name => 'servernode' },
            'port:s@'       => { name => 'port' },
            'database:s'    => { name => 'database' },
        }
    );
    $self->{options}->parse_options();
    my $options_result = $self->{options}->get_options();
    $self->{options}->clean();

    if (defined($options_result->{servernode})) {
        @{$self->{sqldefault}->{dbi}} = ();
        for (my $i = 0; $i < scalar(@{$options_result->{servernode}}); $i++) {
            $self->{sqldefault}->{dbi}[$i] = { data_source => 'ODBC:DRIVER={HDBODBC};SERVERNODE=' . $options_result->{servernode}[$i] };
            if (defined($options_result->{port}[$i])) {
                $self->{sqldefault}->{dbi}[$i]->{data_source} .= ':' . $options_result->{port}[$i];
            } else {
                $self->{sqldefault}->{dbi}[$i]->{data_source} .= ':30013';
            }
            if ((defined($options_result->{database})) && ($options_result->{database} ne '')) {
                $self->{sqldefault}->{dbi}[$i]->{data_source} .= ';DATABASENAME=' . $options_result->{database};
            }
        }
    }
    $self->SUPER::init(%options);    
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check SAP Hana DB Server.
Prerequisite on the system:

=over 8

=item * SAP Hana client for Linux/Unix

=item * unixODBC and perl DBD::ODBC

=item * Add in file /etc/odbcinst.ini

[HDBODBC]
Description = "SmartCloudPT HANA"
Driver=/usr/sap/hdbclient/libodbcHDB.so

=item * Use option --connect-options="LongReadLen=1000000,LongTruncOk=1"

=back 

=over 8

=item B<--servernode>

Hostname to query.

=item B<--port>

Database Server Port (default: 30013).

=item B<--database>

Database name to connect.

=back

=cut
