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

package apps::virtualization::vates::vm::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc qw(json_encode is_excluded is_not_empty is_empty);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'prettify'              => { name => 'prettify' },
        'filter-power-states:s' => { name => 'filter_power_states' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    my $disco_stats;
    $disco_stats->{start_time} = time();
    my $vms = $options{custom}->request_api_get(endpoint => "vms", get_param => ["fields=*"]);

    $disco_stats->{results} = [];
    foreach my $vm (@{$vms}) {
        my $vm_disco = {};
        next if is_excluded($vm->{power_state}, $self->{option_results}->{filter_power_states} );

        # change the keys to match the host discovery provider's attributes
        $vm_disco->{vm_name} = delete $vm->{name_label};
        $vm_disco->{vm_uuid} = delete $vm->{uuid};
        $vm_disco->{name_description} = delete $vm->{name_description};
        # main_ip_address is a scalar with one of the ip address, ip_addresses is the array of ip address.
        # if mainIpAddress is empty, next loop will try to fill it from "addresses" hash.
        $vm_disco->{main_ip_address} = $vm->{mainIpAddress} // "";
        $vm_disco->{high_availability} = $vm->{high_availability} // "";

        # found "VM" value in my tests, probably useful to separate KVM/containers/lxc
        $vm_disco->{type} = delete $vm->{type};
        # indicate the current power state of the vm (Running, Halted, etc...)
        $vm_disco->{power_state} = $vm->{power_state};
        # if the VM is Running and if the tools are available, the guest tool can provide informations
        $vm_disco->{os_name} = "";
        $vm_disco->{os_distro} = "";
        $vm_disco->{os_uname} = "";
        if (is_not_empty($vm->{os_version}) && ref($vm->{os_version} eq "HASH")) {
            $vm_disco->{os_name} = $vm->{os_version}->{name} // '';
            $vm_disco->{os_distro} = $vm->{os_version}->{distro} // '';
            $vm_disco->{os_uname} = $vm->{os_version}->{uname} // '';
        }
        # Example : { "0/ipv4/0": "192.168.122.2", "0/ipv6/0": "fe80::c4eb:d6ff:fec6:41f3" },
        $vm_disco->{ip_addresses} = {};
        if (is_not_empty($vm->{addresses}) and ref $vm->{addresses} eq "HASH") {
            $vm_disco->{ip_addresses} = $vm->{addresses};
            while ( my ($k, $v) = each %{$vm->{addresses}} ) {

                if ($v eq "127.0.0.1" or $v eq "localhost") {
                    next;
                }
                if (is_empty($vm_disco->{main_ip_address})) {
                    $vm_disco->{main_ip_address} = $v;
                    next;
                }
                # we priorise ipv4 over ipv6,
                if ($k =~ /v4/){
                    $vm_disco->{main_ip_address} = $v;
                    next;
                }
            }

        }

        # there can be empty tag in the api answer, this allows to trim empty tags.
        $vm_disco->{tags} = [];
        for my $tag (@{$vm->{tags}}){
            if (is_not_empty($tag)) {
                push(@{$vm_disco->{tags}}, $tag);
            }
        }

        push(@{$disco_stats->{results}}, $vm_disco);
    }
    # Record the metadata
    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = scalar( @{$disco_stats->{results}});

    my $encoded_data = json_encode(
        $disco_stats,
        prettify => $self->{option_results}->{prettify},
        errstr   => '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}',
        output   => $self->{output}
    );

    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
}

1;

__END__

=head1 MODE

Discover Vates Xen Orchestra virtual machines.

=over 8

=item B<--filter-power-states>

Filter virtual machines by power state (can be a regexp). Only matching VMs are included.

=item B<--prettify>

Prettify JSON output.

=back

=cut
