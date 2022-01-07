#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package apps::backup::rubrik::restapi::mode::compliance;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_global_output {
    my ($self, %options) = @_;
    
    my $prefix_output;
    
    
    return 'Backup objects ' . $prefix_output . ') ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'incompliance', nlabel => 'backup.objects.incompliance.24h.count', set => {
                key_values => [ { name => 'incompliance' } ],
                output_template => 'in compliance: %s',
                perfdatas => [
                    { template => '%s',  min => 0 }
                ]
            }
        },
        { label => 'noncompliance', nlabel => 'backup.objects.noncompliance.24h.count', set => {
                key_values => [ { name => 'noncompliance' } ],
                output_template => 'non compliance: %s',
                perfdatas => [
                    { template => '%s',  min => 0 }
                ]
            }
        },
        { label => 'percent_incompliance', nlabel => 'backup.objects.incompliance.24h.percent', set => {
                key_values => [ { name => 'incompliancepercent' } ],
                output_template => 'in compliance %%: %s%%',
                perfdatas => [
                    { template => '%s',  min => 0 }
                ]
            }
        },
        { label => 'percent_noncompliance', nlabel => 'backup.objects.noncompliance.24h.percent', set => {
                key_values => [ { name => 'noncompliancepercent' } ],
                output_template => 'non compliance %%: %s%%',
                perfdatas => [
                    { template => '%s',  min => 0 }
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
        'snapshot-range:s'   => { name => 'snapshot_range', default => 'LastSnapshot' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) =@_;
    $self->SUPER::check_options(%options);

    $self->{option_results}->{snapshot_range} = 'LastSnapshot' if ($self->{option_results}->{snapshot_range} eq '');

}

sub manage_selection {
    my ($self, %options) = @_;

     my $reports = $options{custom}->request_api(
         api_version => 'v1',
         endpoint => '/report/compliance_summary_sla',
         get_param => ['snapshot_range=' . $self->{option_results}->{snapshot_range}],
     );
     $self->{global}->{incompliance} = $reports->{'numberOfInComplianceSnapshots'};
     $self->{global}->{incompliancepercent} = $reports->{'percentOfInComplianceSnapshots'};
     $self->{global}->{noncompliance} = $reports->{'numberOfOutOfComplianceSnapshots'};
     $self->{global}->{noncompliancepercent} = $reports->{'percentOfOutOfComplianceSnapshots'};

}

1;

__END__

=head1 MODE

Check backup objects compliance.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='noncompliance'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'incompliance', 'noncompliance', 'percent_incompliance', 'percent_noncompliance'.

=item B<--snapshot-range>

Specified a number of snapshot. Compliance for each object is calculated for the most recent snapshots, up to the specified number.
Can be: LastSnapshot, Last2Snapshots, Last3Snapshots, AllSnapshots (default: LastSnapshot)

=back

=cut
