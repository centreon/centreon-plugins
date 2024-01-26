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

package cloud::microsoft::office365::azuread::mode::directorysizeusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_used_perfdata {
    my ($self, %options) = @_;

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        nlabel => 'azure.ad.directory.usage.count',
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_used_threshold {
    my ($self, %options) = @_;

    my $threshold_value = $self->{result_values}->{used};
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
    }
    my $exit = $self->{perfdata}->threshold_check(
        value => $threshold_value,
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
    return $exit;

}

sub custom_used_output {
    my ($self, %options) = @_;

    return sprintf(
        "Directory size usage : %d/%d (%.2f%%)",
        $self->{result_values}->{used},
        $self->{result_values}->{total},
        $self->{result_values}->{prct_used}
    );
}

sub custom_used_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{prct_used} = ($self->{result_values}->{total} != 0) ? $self->{result_values}->{used} * 100 / $self->{result_values}->{total} : 0;
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'directory', type => 0 }
    ];

    $self->{maps_counters}->{directory} = [
        { label => 'usage', set => {
	    key_values => [ { name => 'used' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_used_calc'),
                closure_custom_output => $self->can('custom_used_output'),
                closure_custom_threshold_check => $self->can('custom_used_threshold'),
                closure_custom_perfdata => $self->can('custom_used_perfdata')
	}
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "units:s"           => { name => 'units', default => '%' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $results = $options{custom}->azuread_get_organization();
    
    $self->{directory} = {
        used => @{$results}[0]->{'directorySizeQuota'}->{'used'},
        total => @{$results}[0]->{'directorySizeQuota'}->{'total'}
    }
}

1;

__END__

=head1 MODE

Check Azure AD directory size usage/quota.

=over 8

=item B<--warning-usage>

Warning threshold.

=item B<--critical-usage>

Critical threshold.

=item B<--units>

Unit of thresholds (default: '%') ('%', 'count').

=back

=cut
