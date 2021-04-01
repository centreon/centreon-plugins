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

package storage::netapp::ontap::oncommandapi::mode::qtreestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Status is '%s' [path: %s] [volume: %s]",
        $self->{result_values}->{status},
        $self->{result_values}->{qtree_path},
        $self->{result_values}->{volume});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{qtree_path} = $options{new_datas}->{$self->{instance} . '_qtree_path'};
    $self->{result_values}->{volume} = $options{new_datas}->{$self->{instance} . '_volume'};

    return 0;
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Qtree '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'qtrees', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All Qtrees status are ok' },
    ];
    
    $self->{maps_counters}->{qtrees} = [
        { label => 'status', set => {
                key_values => [ { name => 'status' }, { name => 'qtree_path' }, { name => 'volume' }, { name => 'name' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'filter-volume:s'   => { name => 'filter_volume' },
        'warning-status:s'  => { name => 'warning_status' },
        'critical-status:s' => { name => 'critical_status' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get(path => '/qtrees');

    foreach my $qtree (@{$result}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $qtree->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $qtree->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        my $volume = $2 if ($qtree->{qtree_path} =~ /^\/(\S+)\/(\S+)\/(\S+)\s*/);

        if (defined($self->{option_results}->{filter_volume}) && $self->{option_results}->{filter_volume} ne '' &&
            defined($volume) && $volume !~ /$self->{option_results}->{filter_volume}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $qtree->{name} . "': no matching filter volume '" . $volume . "'", debug => 1);
            next;
        }

        $self->{qtrees}->{$qtree->{key}} = {
            name => $qtree->{name},
            status => $qtree->{status},
            qtree_path => $qtree->{qtree_path},
            volume => $volume,
        }
    }

    if (scalar(keys %{$self->{qtrees}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check NetApp Qtrees status.

=over 8

=item B<--filter-*>

Filter qtree.
Can be: 'name', 'volume' (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{status}

=back

=cut
