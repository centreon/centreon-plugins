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

package cloud::linux::libvirt::local::mode::vmnetwork;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded);
use Digest::SHA qw(sha256_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'interfaces', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_iface_output',
          message_multiple => 'All VM network interfaces are ok', skipped_code => { NO_VALUE() => 1, BUFFER_CREATION() => 1 } }
    ];

    $self->{maps_counters}->{interfaces} = [
        { label => 'traffic-in', nlabel => 'vm.network.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'rx_bytes', per_second => 1 }, { name => 'display' } ],
                output_template => 'traffic in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { value => 'rx_bytes', template => '%.2f',
                      unit => 'b/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'vm.network.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'tx_bytes', per_second => 1 }, { name => 'display' } ],
                output_template => 'traffic out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { value => 'tx_bytes', template => '%.2f',
                      unit => 'b/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'packets-in', nlabel => 'vm.network.packets.in.count', set => {
                key_values => [ { name => 'rx_pkts', per_second => 1 }, { name => 'display' } ],
                output_template => 'packets in: %.2f/s',
                perfdatas => [
                    { value => 'rx_pkts', template => '%.2f',
                      min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'packets-out', nlabel => 'vm.network.packets.out.count', set => {
                key_values => [ { name => 'tx_pkts', per_second => 1 }, { name => 'display' } ],
                output_template => 'packets out: %.2f/s',
                perfdatas => [
                    { value => 'tx_pkts', template => '%.2f',
                      min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'errors-in', nlabel => 'vm.network.errors.in.count', set => {
                key_values => [ { name => 'rx_errs', per_second => 1 }, { name => 'display' } ],
                output_template => 'errors in: %.2f/s',
                perfdatas => [
                    { value => 'rx_errs', template => '%.2f',
                      min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'errors-out', nlabel => 'vm.network.errors.out.count', set => {
                key_values => [ { name => 'tx_errs', per_second => 1 }, { name => 'display' } ],
                output_template => 'errors out: %.2f/s',
                perfdatas => [
                    { value => 'tx_errs', template => '%.2f',
                      min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_iface_output {
    my ($self, %options) = @_;

    return "Interface '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'vm-name:s'           => { name => 'vm_name',           default => '' },
        'interface-name:s'    => { name => 'interface_name',    default => '' },
        'include-name:s'      => { name => 'include_name',      default => '' },
        'exclude-name:s'      => { name => 'exclude_name',      default => '' },
        'include-interface:s' => { name => 'include_interface', default => '' },
        'exclude-interface:s' => { name => 'exclude_interface', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{output}->option_exit(short_msg => '--vm-name cannot be used together with --include-name or --exclude-name.')
        if $self->{option_results}->{vm_name} ne '' && ($self->{option_results}->{include_name} ne '' || $self->{option_results}->{exclude_name} ne '');
    $self->{output}->option_exit(short_msg => '--interface-name cannot be used together with --include-interface or --exclude-interface.')
        if $self->{option_results}->{interface_name} ne '' && ($self->{option_results}->{include_interface} ne '' || $self->{option_results}->{exclude_interface} ne '');
}

sub manage_selection {
    my ($self, %options) = @_;

    my $virsh_args = 'domstats --interface';
    $virsh_args .= $self->{option_results}->{vm_name} ne '' ? ' ' . $self->{option_results}->{vm_name} : ' --list-running';

    # virsh domstats --interface [--list-running | <vm>]
    # Domain: 'vm1'
    #   net.count=1
    #   net.0.name=vnet0
    #   net.0.rx.bytes=12345   net.0.rx.pkts=100   net.0.rx.errs=0
    #   net.0.tx.bytes=5678    net.0.tx.pkts=50    net.0.tx.errs=0
    my $stdout = $options{custom}->execute_command(virsh_args => $virsh_args);

    $self->{interfaces} = {};
    my ($current_vm, %iface_names);

    foreach (split(/\n/, $stdout)) {
        if (/^Domain:\s+'(.+?)'/) {
            $current_vm = $1;
            %iface_names = ();
            undef $current_vm
                if is_excluded($current_vm, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name});
            next
        }
        next unless $current_vm;

        if (/^\s*net\.(\d+)\.name=(\S+)/) {
            $iface_names{$1} = $2;
            next
        }

        if (/^\s*net\.(\d+)\.(rx|tx)\.(bytes|pkts|errs)=(\d+)/) {
            my ($idx, $dir, $metric, $value) = ($1, $2, $3, $4);
            my $iface = $iface_names{$idx} // "if$idx";

            if ($self->{option_results}->{interface_name} ne '') {
                next unless $iface eq $self->{option_results}->{interface_name};
            } else {
                next if is_excluded($iface, $self->{option_results}->{include_interface}, $self->{option_results}->{exclude_interface});
            }

            my $key = "${current_vm}_${iface}";
            $self->{interfaces}->{$key} //= {
                display  => "${current_vm}/${iface}",
                rx_bytes => 0, tx_bytes => 0,
                rx_pkts  => 0, tx_pkts  => 0,
                rx_errs  => 0, tx_errs  => 0
            };
            $self->{interfaces}->{$key}->{"${dir}_${metric}"} = $value;
        }
    }

    $self->{output}->option_exit(short_msg => 'No network interface found.')
        unless %{$self->{interfaces}};

    $self->{cache_name} = 'libvirt_' . $options{custom}->get_identifier() . '_' . $self->{mode} . '_' .
        sha256_hex(
            $self->{option_results}->{vm_name} . '_' .
            $self->{option_results}->{interface_name} . '_' .
            $self->{option_results}->{include_name} . '_' .
            $self->{option_results}->{exclude_name} . '_' .
            $self->{option_results}->{include_interface} . '_' .
            $self->{option_results}->{exclude_interface}
        );
}

1;

__END__

=head1 MODE

Check virtual machines network interface statistics (C<virsh domstats --interface>).

=over 8

=item B<--vm-name>

Check only this specific VM (skips list discovery).
Cannot be used together with --include-name or --exclude-name.

=item B<--include-name>

Filter VMs by name (regexp).

=item B<--exclude-name>

Exclude VMs whose name matches this regexp.

=item B<--interface-name>

Check only this specific network interface (exact match).
Cannot be used together with --include-interface or --exclude-interface.

=item B<--include-interface>

Filter network interfaces by name (regexp).

=item B<--exclude-interface>

Exclude network interfaces whose name matches this regexp.

=item B<--warning-traffic-in>

Warning threshold for inbound traffic (b/s).

=item B<--critical-traffic-in>

Critical threshold for inbound traffic (b/s).

=item B<--warning-traffic-out>

Warning threshold for outbound traffic (b/s).

=item B<--critical-traffic-out>

Critical threshold for outbound traffic (b/s).

=item B<--warning-packets-in>

Warning threshold for inbound packets per second.

=item B<--critical-packets-in>

Critical threshold for inbound packets per second.

=item B<--warning-packets-out>

Warning threshold for outbound packets per second.

=item B<--critical-packets-out>

Critical threshold for outbound packets per second.

=item B<--warning-errors-in>

Warning threshold for inbound errors per second.

=item B<--critical-errors-in>

Critical threshold for inbound errors per second.

=item B<--warning-errors-out>

Warning threshold for outbound errors per second.

=item B<--critical-errors-out>

Critical threshold for outbound errors per second.

=back

=cut
