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

package database::sybase::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_sql);

sub new {
    my ($class, %options) = @_;
    
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
        'blocked-processes'    => 'database::sybase::mode::blockedprocesses',
        'connected-users'      => 'database::sybase::mode::connectedusers',
        'connection-time'      => 'centreon::common::protocols::sql::mode::connectiontime',
        'databases-size'       => 'database::sybase::mode::databasessize',
        'sql'                  => 'centreon::common::protocols::sql::mode::sql',
    );

    return $self;
}

sub init {
    my ($self, %options) = @_;

    $self->{options}->add_options(
        arguments => {
            'hostname:s@'       => { name => 'hostname' },
            'port:s@'           => { name => 'port' },
            'tds-level:s@'      => { name => 'tds_level' },
            'database:s'        => { name => 'database' },
        }
    );
    $self->{options}->parse_options();
    my $options_result = $self->{options}->get_options();
    $self->{options}->clean();

    if (defined($options_result->{hostname})) {
        @{$self->{sqldefault}->{dbi}} = ();
        for (my $i = 0; $i < scalar(@{$options_result->{hostname}}); $i++) {
            $self->{sqldefault}->{dbi}[$i] = { data_source => 'Sybase:host=' . $options_result->{hostname}[$i] };
            my $port = defined($options_result->{port}[$i]) && $options_result->{port}[$i] ne '' 
                ? $options_result->{port}[$i] : 2638;
            $self->{sqldefault}->{dbi}[$i]->{data_source} .= ';port=' . $port;
            
            my $tds_level = defined($options_result->{tds_level}[$i]) && $options_result->{tds_level}[$i] ne '' 
                ? $options_result->{tds_level}[$i] : 'CS_TDS_50';
            $self->{sqldefault}->{dbi}[$i]->{data_source} .= ';tdsLevel=' . $tds_level;
            
            if ((defined($options_result->{database})) && ($options_result->{database} ne '')) {
                $self->{sqldefault}->{dbi}[$i]->{data_source} .= ';database=' . $options_result->{database};
            }
        }
    }
    $self->SUPER::init(%options);    
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Sybase Server.

=over 8

=item B<--hostname>

Hostname to query.

=item B<--port>

Database Server Port (Default: 2638).

=item B<--tds-level>

TDS protocol level to use (Default: 'CS_TDS_50')

=back

=cut
