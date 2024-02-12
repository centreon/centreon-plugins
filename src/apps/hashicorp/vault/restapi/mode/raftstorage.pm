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

package apps::hashicorp::vault::restapi::mode::raftstorage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'boltdb', type => 1, cb_prefix_output => 'prefix_boltdb_output', message_multiple => 'All Bolt Databases are ok'  }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'commit-time', nlbalel => 'vault.raftstorage.committime.seconds', set => {
                key_values => [ { name => 'commit_time' } ],
                output_template => "commit time : %.2fs",
                perfdatas       => [ { template => '%.2f', unit => 'ms', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{boltdb} = [
        { label => 'spill-time', nlabel => 'vault.raftstorage.spilltime.seconds', set => {
                key_values      => [ { name => 'spill_time' }, { name => 'display' } ],
                output_template => 'spill time: %.2fms',
                perfdatas       => [ { template => '%d', unit => 'ms', min => 0, cast_int => 1, label_extra_instance => 1, instance_use => 'display' } ]
            }
        },
        { label => 'rebalance-time', nlabel => 'vault.raftstorage.rebalance_time.seconds', set => {
                key_values      => [ { name => 'rebalance_time' }, { name => 'display' } ],
                output_template => 'rebalance time: %.2fms',
                perfdatas       => [ { template => '%d', unit => 'ms', min => 0, cast_int => 1, label_extra_instance => 1, instance_use => 'display' } ]
            }
        },
        { label => 'write-time', nlabel => 'vault.raftstorage.write_time.seconds', set => {
                key_values      => [ { name => 'write_time' }, { name => 'display' } ],
                output_template => 'write time: %.2fms',
                perfdatas       => [ { template => '%d', unit => 'ms', min => 0, cast_int => 1, label_extra_instance => 1, instance_use => 'display' } ]
            }
        }
    ];
}

sub prefix_boltdb_output {
    my ($self, %options) = @_;

    return "Database '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub set_options {
    my ($self, %options) = @_;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(url_path => 'metrics');

    foreach (@{$result->{Samples}}) {
        $_->{Name} =~ s/\.|\-/_/g;
        if (defined($_->{Labels}->{database})) {
            $_->{Name} =~ s/vault_raft_storage_bolt_//g;
            $self->{raftstorage}->{boltdb}->{ $_->{Labels}->{database} }->{ $_->{Name} } = {
                rate => $_->{Rate},
                cluster => $_->{Labels}->{cluster}
            }
        } else {
            $self->{raftstorage}->{global}->{ $_->{Name} } = {
                rate => $_->{Rate},
            }
        }

    };

    $self->{global} = {
        commit_time => defined($self->{raftstorage}->{global}->{'vault.raft.commitTime'}) ? $self->{global}->{raftstorage}->{'vault.raft.commitTime'}->{rate} : 0
    };

    foreach my $database (keys %{$self->{raftstorage}->{boltdb}}) {
        $self->{boltdb}->{$database} = {
            display => $database,
            rebalance_time => $self->{raftstorage}->{boltdb}->{$database}->{rebalance_time},
            spill_time => $self->{raftstorage}->{boltdb}->{$database}->{spill_time},
            write_time => $self->{raftstorage}->{boltdb}->{$database}->{write_time}
        }
    };

    if (scalar(keys %{$self->{boltdb}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No Bolt DB found.");
        $self->{output}->option_exit();
    };
}

1;

__END__

=head1 MODE

Check Hashicorp Vault Raft Storage status.

Example:
perl centreon_plugins.pl --plugin=apps::hashicorp::vault::restapi::plugin --mode=raft-storage
--hostname=10.0.0.1 --vault-token='s.aBCD123DEF456GHI789JKL012' --verbose

More information on'https://www.vaultproject.io/api-docs/system/health'.

=over 8

=item B<--warning-*>

Warning threshold where '*' can be:
'commit-time', 'spill-time', 'rebalance-time', 'write-time'

=item B<--critical-*>

Critical threshold where '*' can be:
'commit-time', 'spill-time', 'rebalance-time', 'write-time'

=back

=cut
