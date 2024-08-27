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

package cloud::azure::common::storageaccount::filesharequota;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $value_perf = $self->{result_values}->{used_space};

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total_capacity};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        nlabel => 'fileshare.capacity.usage.bytes',
        unit => 'B',
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{total_capacity}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used_space};
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
    }
    $exit = $self->{perfdata}->threshold_check(
        value => $threshold_value,
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_capacity} );
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_space} );
    my $msg = sprintf(
        "Fileshare '%s' from storage account '%s' used capacity: %s (%.2f%%), total size %s",
        $self->{result_values}->{fileshare},
        $self->{result_values}->{storageaccount},
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_size_value . " " . $total_size_unit
    );
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{storageaccount} = $options{new_datas}->{fileshare_storage_account};
    $self->{result_values}->{fileshare} = $options{new_datas}->{fileshare_fileshare};

    $self->{result_values}->{used_space} = $options{new_datas}->{fileshare_used_space};
    $self->{result_values}->{total_capacity} = $options{new_datas}->{fileshare_total_capacity} * ( 1024 ** 3);
    $self->{result_values}->{prct_used} = ($self->{result_values}->{total_capacity} > 0) ? $self->{result_values}->{used_space} * 100 / $self->{result_values}->{total_capacity} : 0;
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'fileshare', type => 0 }
    ];

    $self->{maps_counters}->{fileshare} = [
        { label => 'capacity-usage', set => {
                key_values => [ { name => 'used_space' }, { name => 'total_capacity' }, { name => 'storage_account' }, { name => 'fileshare' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold')
            }
        }
    ]
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'resource-group:s'  => { name => 'resource_group' },
        'storage-account:s' => { name => 'storage_account' },
        'units:s'           => { name => 'units', default => '%' },
        'fileshare:s'       => { name => 'fileshare' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{api_version} = '2021-09-01';

    if (!defined($self->{option_results}->{resource_group}) || $self->{option_results}->{resource_group} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --resource-group <name>.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{storage_account}) || $self->{option_results}->{storage_account} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --storage-account <name>.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{fileshare}) || $self->{option_results}->{fileshare} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --fileshare <name>");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results;
    $results = $options{custom}->azure_get_file_share_stats(
        resource_group => $self->{option_results}->{resource_group}, storage_account => $self->{option_results}->{storage_account}, 
        fileshare => $self->{option_results}->{fileshare}, api_version => $self->{api_version}
    );

    $self->{fileshare} = {
        storage_account => $self->{option_results}->{storage_account},
        fileshare => $self->{option_results}->{fileshare},
        total_capacity => $results->{properties}->{shareQuota},
        used_space => $results->{properties}->{shareUsageBytes}
    };

    if (scalar(keys %{$self->{fileshare}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
    }
}

1;

__END__

=head1 MODE

Check storage account fileshare capacity usage.

Example:

perl centreon_plugins.pl --plugin=cloud::azure::storage::storageaccount::plugin --mode=file-share-quota --custommode=api 
--client-id='XXX' --subscription='XXX' --tenant='XXX' --client-secret='XXX' --resource-group=MYRESOURCEGROUP1 
--storage-account=MYSTORAGEACCOUNT1 --fileshare=FILESHARE1

=over 8

=item B<--units>

Units of thresholds. Can be : '%', 'B' 

Default: '%'

=item B<--resource-group>

Set resource group from which depends the storage account (required).

=item B<--storage-account>

Set storage account from which the fileshare to monitor is from (required).

=item B<--fileshare>

Set fileshare to monitor (required).

=item B<--warning-capacity-usage>

Warning threshold for fileshare capacity usage.

Threshold is in percentage by default.
To specify it in Bytes please set the units option '--units=B'.

=item B<--critical-capacity-usage>

Critical threshold for fileshare capacity usage.

Threshold is in percentage by default.
To specify it in Bytes please set the units option '--units=B'.

=back

=cut
