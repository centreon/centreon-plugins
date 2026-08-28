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

package storage::ibm::storwize::ssh::mode::vdiskstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_replication_output {
    my ($self, %options) = @_;

    my $output = sprintf(
        'vdisk %s [volume name: %s]',
        $options{instance_value}->{name},
        $options{instance_value}->{volume_name}
    );

    if (defined($options{instance_value}->{rc_name}) && $options{instance_value}->{rc_name}) {
        $output .= sprintf(
            ' [RC name: %s - %s (primary: %d)]',
            $options{instance_value}->{rc_name},
            $options{instance_value}->{function},
            $options{instance_value}->{primary}
        );
    }

    $output .= " - ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name               =>
            'vdisks',
            type             =>
                1,
            cb_prefix_output =>
                'prefix_replication_output',
            message_multiple =>
                'All vdisk are ok' }
    ];

    $self->{maps_counters}->{vdisks} = [
        {
            label            => 'status',
            type             => 2,
            critical_default => '(%{rc_name} ne "" && %{primary} == 1 || %{rc_name} eq "") && %{status} =~ /offline/i',
            set              => {
                key_values                     =>
                    [ { name => 'status' }, { name => 'primary' }, { name => 'rc_name' } ],
                output_template                =>
                    'status: %s',
                closure_custom_perfdata        =>
                    sub {return 0;},
                closure_custom_threshold_check =>
                    \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-volume-name:s' => { name => 'filter_volume_name' },
        'filter-rc-name:s'     => { name => 'filter_rc_name' },
        'filter-function:s'    => { name => 'filter_function' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $vd_command = 'lsvdisk -delim :';
    my $vd_content = $options{custom}->execute_command(command => $vd_command);
    my $result = $options{custom}->get_hasharray(content => $vd_content, delim => ':');

    my $rel_content = $options{custom}->execute_command(command => 'lsrcrelationship -delim :');
    my $rel_result = $options{custom}->get_hasharray(content => $rel_content, delim => ':');

    $self->{vdisks} = {};
    foreach my $vdisk (@$result) {
        next if (defined($self->{option_results}->{filter_volume_name}) && $self->{option_results}->{filter_volume_name} ne '' &&
            $vdisk->{volume_name} !~ /$self->{option_results}->{filter_volume_name}/);

        next if (defined($self->{option_results}->{filter_rc_name}) && $self->{option_results}->{filter_rc_name} ne '' &&
            $vdisk->{RC_name} !~ /$self->{option_results}->{filter_rc_name}/);

        next if (defined($self->{option_results}->{filter_function}) && $self->{option_results}->{filter_function} ne '' &&
            $vdisk->{function} !~ /$self->{option_results}->{filter_function}/);

        $self->{vdisks}->{ $vdisk->{id} } = {
            name        => $vdisk->{name},
            status      => $vdisk->{status},
            volume_name => $vdisk->{volume_name},
            rc_name     => $vdisk->{RC_name},
            function    => $vdisk->{function},
            primary     => 0
        };

        if (defined($vdisk->{RC_name}) && length($vdisk->{RC_name}) > 0) {
            foreach my $item (@$rel_result) {
                if (defined($item->{primary}) && defined($item->{name})
                    && $item->{name} eq $vdisk->{RC_name}
                    && $vdisk->{function} eq $item->{primary}) {
                    $self->{vdisks}->{ $vdisk->{id} }->{primary} = 1;
                }
            }
        }
    }

    if (scalar(keys %{$self->{vdisks}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No volume found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check vdisk & hyperswap status.

=over 8

=item B<--filter-volume-name>

Filter volume name (can be a regexp).

=item B<--filter-rc-name>

Filter RC name (can be a regexp).

=item B<--filter-function>

Filter function name (can be a regexp).
Can be: master, aux, master_change, aux_change

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '').
You can use the following variables: %{status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL. (default: '(%{rc_name} ne "" && %{primary} == 1 || %{rc_name} eq "") && %{status} =~ /offline/i').
You can use the following variables: %{status}, %{rc_name}, %{primary}

=back

=cut
