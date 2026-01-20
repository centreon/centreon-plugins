#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package network::fortinet::fortiauthenticator::restapi::mode::fortitokens;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use POSIX;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => 'tokens.assigned.percentage',
        unit => '%',
        min => 0,
        max => 100,
        value => floor($self->{result_values}->{assigned_prct}),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label})
    );
}

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf("[Tokens] total:%s - assigned:%s(%.2f%%) - available:%s(%.2f%%) - pending:%s(%.2f%%)",
                $self->{result_values}->{total},
                $self->{result_values}->{assigned},
                $self->{result_values}->{assigned_prct},
                $self->{result_values}->{available},
                $self->{result_values}->{available_prct},
                $self->{result_values}->{pending},
                $self->{result_values}->{pending_prct}
   );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{assigned_prct}, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);

    return $exit;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{pending} = $options{new_datas}->{$self->{instance} . '_pending'};
    $self->{result_values}->{assigned} = $options{new_datas}->{$self->{instance} . '_assigned'};
    $self->{result_values}->{available} = $options{new_datas}->{$self->{instance} . '_available'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};

    $self->{result_values}->{assigned_prct} = ($self->{result_values}->{assigned} * 100) / $self->{result_values}->{total};
    $self->{result_values}->{available_prct} = ($self->{result_values}->{available} * 100) / $self->{result_values}->{total};
    $self->{result_values}->{pending_prct} = ($self->{result_values}->{available} * 100) / $self->{result_values}->{total};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'fortitokens', type => 0 }
    ];

    $self->{maps_counters}->{fortitokens} = [
        { label => 'assigned-prct', set => {
                key_values => [ { name => 'assigned' }, { name => 'total' }, { name => 'pending' }, { name => 'available' }],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
		closure_custom_perfdata => $self->can('custom_usage_perfdata'),
		closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    	'filter-type:s' => { name => 'filter_type' }
    });

    return $self;
}

sub manage_selection { 
	my ($self, %options) = @_;
	my $results = $options{custom}->fortiauthentificator_list_tokens();
	my @list_status = ("available", "pending", "assigned");
	
	$self->{fortitokens}->{total} = 0;
	$self->{fortitokens}->{available} = 0;
	$self->{fortitokens}->{assigned} = 0;
	$self->{fortitokens}->{pending} = 0;

	foreach my $token (@{$results}) {
		next if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&  $token->{type} !~ /$self->{option_results}->{filter_type}/);
		
		if ( $token->{serial} ne '' && $token->{status} ne '' && grep {$_ eq $token->{status} } @list_status ) {
			$self->{fortitokens}->{total}++;
			$self->{fortitokens}->{$token->{status}}++;
		}	
	}

	if ( $self->{fortitokens}->{total} == 0) {
        	$self->{output}->add_option_msg(short_msg => "No tokens found.");
        	$self->{output}->option_exit();
    	}
}	


1;

__END__

=head1 MODE

Check Fortitokens.

=over 8

=item B<--warning-assigned-prct>

Warning threshold in percent.

=item B<--critical-assigned-prct>

Critical threshold in percent.

=back

=cut
