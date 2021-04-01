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

package apps::biztalk::sql::mode::rlocationdisabled;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning' },
                                  "critical:s"              => { name => 'critical' },
                                  "filter-location:s"       => { name => 'filter_location' },
                                  "filter-application:s"    => { name => 'filter_application' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical}. "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    my $query = q{
        SELECT RL.Name, RL.Disabled, APP.nvcName 
        FROM BizTalkMgmtDb.dbo.adm_ReceiveLocation AS RL WITH(NOLOCK) 
            INNER JOIN BizTalkMgmtDb.dbo.bts_receiveport AS RP WITH(NOLOCK) 
                ON RL.ReceivePortId = RP.nID 
            INNER JOIN BizTalkMgmtDb.dbo.bts_application AS APP WITH(NOLOCK) 
                ON RP.nApplicationID = APP.nID WHERE RL.[Disabled] = -1
    };
    $self->{sql}->connect();
    $self->{sql}->query(query => $query);

    my $count = 0;
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        if (defined($self->{option_results}->{filter_location}) && $self->{option_results}->{filter_location} ne '' &&
            $row->{Name} !~ /$self->{option_results}->{filter_location}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $row->{Name} . "': no matching filter location.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_application}) && $self->{option_results}->{filter_application} ne '' &&
            $row->{nvcName} !~ /$self->{option_results}->{filter_application}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $row->{nvcName} . "': no matching filter application.", debug => 1);
            next;
        }
        $self->{output}->output_add(long_msg => "'" . $row->{Name} . "' of application '" . $row->{nvcName} . "'");
        $count++;
    }
    
    my $exit = $self->{perfdata}->threshold_check(value => $count, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("%d receive locations are disabled", $count));
    $self->{output}->perfdata_add(label => 'count',
                                  value => $count,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check the number of biztalk received locations disabled.
The mode should be used with mssql plugin and dyn-mode option.

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--filter-location>

Filter by location (regexp can be used).

=item B<--filter-application>

Filter by application (regexp can be used).

=back

=cut
