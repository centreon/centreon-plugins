#
# Copyright 2016 Centreon (http://www.centreon.com/)
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
                         'data-files-status'        => 'database::oracle::mode::datafilesstatus',
                         'datacache-hitratio'       => 'database::oracle::mode::datacachehitratio',
                         'process-usage'            => 'database::oracle::mode::processusage',
                         'rman-backup-problems'     => 'database::oracle::mode::rmanbackupproblems',
                         'rman-backup-age'          => 'database::oracle::mode::rmanbackupage',
                         'rman-online-backup-age'   => 'database::oracle::mode::rmanonlinebackupage',
                         'tablespace-usage'         => 'database::oracle::mode::tablespaceusage',
                         'session-usage'            => 'database::oracle::mode::sessionusage',
                         'sql'                      => 'centreon::common::protocols::sql::mode::sql',
                         'tnsping'                  => 'database::oracle::mode::tnsping',
                         );

    return $self;
}

sub init {
    my ($self, %options) = @_;

    $self->{options}->add_options(
                                   arguments => {
                                                'hostname:s@'   => { name => 'hostname' },
                                                'port:s@'       => { name => 'port' },
                                                'sid:s'         => { name => 'sid' },
                                                }
                                  );
    $self->{options}->parse_options();
    my $options_result = $self->{options}->get_options();
    $self->{options}->clean();

    if (defined($options_result->{hostname})) {
        @{$self->{sqldefault}->{dbi}} = ();
        for (my $i = 0; $i < scalar(@{$options_result->{hostname}}); $i++) {
            $self->{sqldefault}->{dbi}[$i] = { data_source => 'Oracle:host=' . $options_result->{hostname}[$i] };
            if (defined($options_result->{port}[$i])) {
                $self->{sqldefault}->{dbi}[$i]->{data_source} .= ';port=' . $options_result->{port}[$i];
            }
            if ((defined($options_result->{sid})) && ($options_result->{sid} ne '')) {
                $self->{sqldefault}->{dbi}[$i]->{data_source} .= ';sid=' . $options_result->{sid};
            }
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

Database SID (SERVICE_NAME).

=back

=cut
