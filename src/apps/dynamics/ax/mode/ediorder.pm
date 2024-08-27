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

package apps::dynamics::ax::mode::ediorder;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Order ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 }}
    ];

    $self->{maps_counters}->{global} = [
        { label => 'order-warning', nlabel => 'order.warning.count', set => {
                key_values => [ { name => '2' } ],
                output_template => 'warning: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'order-critical', nlabel => 'order.critical.count', set => {
                key_values => [ { name => '3' } ],
                output_template => 'critical: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
             }
         }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'timeframe:s'       => { name => 'timeframe', default => 14400 },
        'filter-module:s'   => { name => 'filter_module' },
        'filter-company:s'  => { name => 'filter_company' },
        'filter-portname:s' => { name => 'filter_portname' }
    });

    return $self;
}


sub manage_selection {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    my $query = "
        SELECT
            [AIFEXCEPTIONMAP].[MESSAGEID],
            [SYSEXCEPTIONTABLE].[EXCEPTION],
            [SYSEXCEPTIONTABLE].[DESCRIPTION],
            [SYSEXCEPTIONTABLE].[MODULE],
            convert(char(19), [SYSEXCEPTIONTABLE].[CREATEDDATETIME], 120) CREATEDDATETIME,
            [AIFEXCEPTIONMAP].[PORTNAME],
            [AIFMESSAGELOG].[COMPANY]
        FROM [MicrosoftDynamicsAX].[dbo].[SYSEXCEPTIONTABLE]
            Inner join [MicrosoftDynamicsAX].[dbo].[AIFEXCEPTIONMAP] on SYSEXCEPTIONTABLE.RECID = AIFEXCEPTIONMAP.EXCEPTIONID
            Inner join [MicrosoftDynamicsAX].[dbo].[AIFDOCUMENTLOG] on AIFEXCEPTIONMAP.MESSAGEID = AIFDOCUMENTLOG.MESSAGEID
            Inner join [MicrosoftDynamicsAX].[dbo].[AIFMESSAGELOG] on AIFDOCUMENTLOG.MESSAGEID = AIFMESSAGELOG.MESSAGEID
        WHERE [SYSEXCEPTIONTABLE].[CREATEDDATETIME] > (DATEADD(SECOND,-" . $self->{option_results}->{timeframe} . ",SYSDATETIME()))";

    if(defined($self->{option_results}->{filter_module}) && $self->{option_results}->{filter_module} ne '') {
        $query = $query . " AND [SYSEXCEPTIONTABLE].[MODULE] LIKE '$self->{option_results}->{filter_module}'";
    }
    if(defined($self->{option_results}->{filter_company}) && $self->{option_results}->{filter_company} ne '') {
        $query = $query . " AND [AIFMESSAGELOG].[COMPANY] LIKE '$self->{option_results}->{filter_company}'";
    }
    if(defined($self->{option_results}->{filter_portname}) && $self->{option_results}->{filter_portname} ne '') {
        $query = $query . " AND [AIFEXCEPTIONMAP].[PORTNAME] LIKE '$self->{option_results}->{filter_portname}'";
    }
    $query = $query . " ORDER BY [AIFEXCEPTIONMAP].[MESSAGEID] ";
    $self->{sql}->connect();
    $self->{sql}->query(query => $query );

    $self->{global} = { 2 => 0, 3 => 0 };
    my $messageId = '';
    my $desc_num = 1;
    while (my $row = $self->{sql}->fetchrow_hashref()) {
        if ($messageId eq $row->{MESSAGEID}){
            $desc_num++;
            $self->{output}->output_add(
                long_msg => sprintf('    [description %d: %s]',
                    $desc_num,
                    $row->{DESCRIPTION}
                )
            );
            next
        }
        $desc_num = 1;
        $messageId = $row->{MESSAGEID};
        $self->{global}->{ $row->{EXCEPTION} }++;
        $self->{output}->output_add(
            long_msg => sprintf(
                'Exception: %d [company: %s] [module: %s] [date: %s] [portname: %s] [id: %s]',
                $row->{EXCEPTION},
                $row->{COMPANY},
                $row->{MODULE},
                $row->{CREATEDDATETIME},
                $row->{PORTNAME},
                $row->{MESSAGEID}
            )
        );
        $self->{output}->output_add(
            long_msg => sprintf(
                '    [description %d: %s]',
                $desc_num,
                $row->{DESCRIPTION}
            )
        );
    }
}

1;

__END__

=head1 MODE

Check EDI Orders execptions.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'order-critical', 'order-warning'.

=item B<--timeframe>

Set the timeframe to query in seconds (default: 14400).

=item B<--filter-module>

Filter on module.

=item B<--filter-company>

Filter on company.

=item B<--filter-portname>

Filter on portname. 

=back

=cut
