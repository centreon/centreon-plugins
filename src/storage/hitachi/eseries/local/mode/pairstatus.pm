#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package storage::hitachi::eseries::local::mode::pairstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters);
use centreon::plugins::misc qw/is_empty flatten_arrays/;

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'Status (L/R): %s/%s (sync: %s%%/%s%%)',
        $self->{result_values}->{status_l},
        $self->{result_values}->{status_r},
        $self->{result_values}->{perc_l},
        $self->{result_values}->{perc_r}
    );
}

sub prefix_pair_output {
    my ($self, %options) = @_;
    return "Pair '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'pairs', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_pair_output',
          message_multiple => 'All pairs are in sync' }
    ];

    $self->{maps_counters}->{pairs} = [
        { label => 'status', type => COUNTER_KIND_TEXT, critical_default => '%{status_l} ne "PAIR" || %{status_r} ne "PAIR"', set => {
                key_values => [
                    { name => 'status_l' }, { name => 'status_r' },
                    { name => 'perc_l' },   { name => 'perc_r' },
                    { name => 'display' }
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'remote-baie-id:s@' => { name => 'remote_baie_id' },
        'ldev-id:s@'        => { name => 'ldev_id' },
        'group-id:s'        => { name => 'group_id',        default => '' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    my $baie_id = $self->{option_results}->{baie_id};
    # If remote_baie_id starts with + or - then it is added to baie_id to determine the effective array ID to use
    # otherwise it is used as is

    if (ref $self->{option_results}->{remote_baie_id} eq 'ARRAY') {
        foreach my $c_id (reverse @{$self->{option_results}->{remote_baie_id}}) {
            next if $c_id eq '';
            if ($c_id =~ /^[\+-]\d+$/) {
                $baie_id += $c_id;
            } elsif ($c_id =~ /^\d+$/) {
                $baie_id = $c_id;
            } else {
                $self->{output}->option_exit(short_msg => "Please set a valid --remote-baie-id option.");
            }
            last
        }
    }

    $self->{remote_baie_id} = $baie_id;

    $self->{ldev_ids} = flatten_arrays($self->{option_results}->{ldev_id});

    $self->{output}->option_exit(short_msg => "Please set --group-id option.")
        if $self->{option_results}->{group_id} eq '';

    $self->{group_id} = $self->{option_results}->{group_id};
}

sub manage_selection {
    my ($self, %options) = @_;

    # https://docs.hitachivantara.com/r/en-us/command-control-interface/01-87-03/mk-90rd7009/data-and-system-management-commands/pairdisplay
    # pairdisplay -ITC<baie-id+1000> -g <group> -CLI -fxce

    $self->{pairs} = {};
    my ($stdout) = $options{custom}->execute_command(
        command         => 'pairdisplay',
        command_options => '-ITC' . $self->{remote_baie_id} . ' -g ' . $self->{group_id} . ' -CLI -fxce'
    );

    foreach my $line (split /\n/, $stdout) {
        next unless $line =~ /^(\S+)\t(\S+)\s+([LR])\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\S+)\s+\S+\s+(\d+)/;
        my ($grp, $pairvol, $lr, $status, $perc) = ($1, $2, $3, $4, $5);

        if (@{$self->{ldev_ids}}) {
            my $filter = 0;
            my $match = 0;
            foreach my $item (@{$self->{ldev_ids}}) {
                next if is_empty($item);
                $filter = 1;
                if ($item eq $pairvol) {
                    $match = 1;
                    last
                }
            }
            next if $filter && !$match;
        }

        my $key = $grp . '::' . $pairvol;
        $self->{pairs}->{$key} //= {
            display  => "$grp - $pairvol",
            status_l => '-',
            status_r => '-',
            perc_l   => 0,
            perc_r   => 0
        };

        if ($lr eq 'L') {
            $self->{pairs}->{$key}->{status_l} = $status;
            $self->{pairs}->{$key}->{perc_l}   = $perc;
        } else {
            $self->{pairs}->{$key}->{status_r} = $status;
            $self->{pairs}->{$key}->{perc_r}   = $perc;
        }
    }

    $self->{output}->option_exit(short_msg => "No pair found.")
        unless keys %{$self->{pairs}};
}

1;

__END__

=head1 MODE

Check Hitachi E-Series TrueCopy/Universal Replicator pair status.

Command used: C<pairdisplay -ITC<baie-id+1000> -g <group> -CLI -fxce>

=over 8

=item B<--remote-baie-id>

Remote array ID. If starts with + or -, it is added to the local array ID, otherwise used as is (e.g. C<--remote-baie-id='100'> or C<--remote-baie-id='+1000'>).

=item B<--group-id>

C<HORCM> group name to check (required).

=item B<--ldev-id>

Filter pair volumes by C<LDEV ID>. Can be used multiple times (e.g. C<--ldev-id='1' --ldev-id='2' --ldev-id='3'>).

=item B<--warning-status>

Warning threshold for pair status.

=item B<--critical-status>

Critical threshold for pair status (default: C<'%{status_l} ne "PAIR" || %{status_r} ne "PAIR"'>).

=back

=cut
