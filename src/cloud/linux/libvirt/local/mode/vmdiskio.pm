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

package cloud::linux::libvirt::local::mode::vmdiskio;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded);
use Digest::SHA qw(sha256_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'disks', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_disk_output',
          message_multiple => 'All VM disk I/O are ok', skipped_code => { NO_VALUE() => 1, BUFFER_CREATION() => 1 } }
    ];

    $self->{maps_counters}->{disks} = [
        { label => 'read-usage', nlabel => 'vm.disk.io.read.usage.bytespersecond', set => {
                key_values => [ { name => 'rd_bytes', per_second => 1 }, { name => 'display' } ],
                output_template => 'read: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'rd_bytes', template => '%d',
                      unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write-usage', nlabel => 'vm.disk.io.write.usage.bytespersecond', set => {
                key_values => [ { name => 'wr_bytes', per_second => 1 }, { name => 'display' } ],
                output_template => 'write: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'wr_bytes', template => '%d',
                      unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'read-iops', nlabel => 'vm.disk.io.read.iops', set => {
                key_values => [ { name => 'rd_reqs', per_second => 1 }, { name => 'display' } ],
                output_template => 'read IOPS: %.2f/s',
                perfdatas => [
                    { value => 'rd_reqs', template => '%.2f',
                      min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write-iops', nlabel => 'vm.disk.io.write.iops', set => {
                key_values => [ { name => 'wr_reqs', per_second => 1 }, { name => 'display' } ],
                output_template => 'write IOPS: %.2f/s',
                perfdatas => [
                    { value => 'wr_reqs', template => '%.2f',
                      min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_disk_output {
    my ($self, %options) = @_;

    return "Disk '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'vm-name:s'      => { name => 'vm_name',      default => '' },
        'disk-name:s'    => { name => 'disk_name',    default => '' },
        'include-name:s' => { name => 'include_name', default => '' },
        'exclude-name:s' => { name => 'exclude_name', default => '' },
        'include-disk:s' => { name => 'include_disk', default => '' },
        'exclude-disk:s' => { name => 'exclude_disk', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{output}->option_exit(short_msg => '--vm-name cannot be used together with --include-name or --exclude-name.')
        if $self->{option_results}->{vm_name} ne '' && ($self->{option_results}->{include_name} ne '' || $self->{option_results}->{exclude_name} ne '');
    $self->{output}->option_exit(short_msg => '--disk-name cannot be used together with --include-disk or --exclude-disk.')
        if $self->{option_results}->{disk_name} ne '' && ($self->{option_results}->{include_disk} ne '' || $self->{option_results}->{exclude_disk} ne '');
}

sub manage_selection {
    my ($self, %options) = @_;

    my $virsh_args = 'domstats --block';
    $virsh_args .= $self->{option_results}->{vm_name} ne '' ? ' ' . $self->{option_results}->{vm_name} : ' --list-running';

    # virsh domstats --block [--list-running | <vm>]
    # Domain: 'vm1'
    #   block.count=1
    #   block.0.name=vda
    #   block.0.rd.reqs=1234   block.0.rd.bytes=51200000
    #   block.0.wr.reqs=567    block.0.wr.bytes=25600000
    my $stdout = $options{custom}->execute_command(virsh_args => $virsh_args);

    $self->{disks} = {};
    my ($current_vm, %disk_names);

    foreach (split(/\n/, $stdout)) {
        if (/^Domain:\s+'(.+?)'/) {
            $current_vm = $1;
            %disk_names = ();
            undef $current_vm
                if is_excluded($current_vm, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name});
            next
        }
        next unless $current_vm;

        if (/^\s*block\.(\d+)\.name=(\S+)/) {
            $disk_names{$1} = $2;
            next;
        }

        if (/^\s*block\.(\d+)\.(rd|wr)\.(reqs|bytes)=(\d+)/) {
            my ($idx, $dir, $metric, $value) = ($1, $2, $3, $4);
            my $disk = $disk_names{$idx} // "disk$idx";

            if ($self->{option_results}->{disk_name} ne '') {
                next unless $disk eq $self->{option_results}->{disk_name};
            } else {
                next if is_excluded($disk, $self->{option_results}->{include_disk}, $self->{option_results}->{exclude_disk});
            }

            my $key = "${current_vm}_${disk}";
            $self->{disks}->{$key} //= {
                display   => "${current_vm}/${disk}",
                rd_bytes  => 0, wr_bytes => 0,
                rd_reqs   => 0, wr_reqs  => 0
            };
            $self->{disks}->{$key}->{"${dir}_${metric}"} = $value;
        }
    }

    $self->{output}->option_exit(short_msg => 'No disk found.')
        unless %{$self->{disks}};

    $self->{cache_name} = 'libvirt_' . $options{custom}->get_identifier() . '_' . $self->{mode} . '_' .
        sha256_hex(
            $self->{option_results}->{vm_name} . '_' .
            $self->{option_results}->{disk_name} . '_' .
            ($self->{option_results}->{include_name} // '') . '_' .
            ($self->{option_results}->{exclude_name} // '') . '_' .
            ($self->{option_results}->{include_disk} // '') . '_' .
            ($self->{option_results}->{exclude_disk} // '')
        );
}

1;

__END__

=head1 MODE

Check virtual machines disk I/O statistics (C<virsh domstats --block>).

=over 8

=item B<--vm-name>

Check only this specific VM.
Cannot be used together with --include-name or --exclude-name.

=item B<--include-name>

Filter VMs by name (regexp).

=item B<--exclude-name>

Exclude VMs whose name matches this regexp.

=item B<--disk-name>

Check only this specific disk device (exact match).
Cannot be used together with --include-disk or --exclude-disk.

=item B<--include-disk>

Filter disk devices by name (regexp).

=item B<--exclude-disk>

Exclude disk devices whose name matches this regexp.

=item B<--warning-read-usage>

Warning threshold for disk read throughput (B/s).

=item B<--critical-read-usage>

Critical threshold for disk read throughput (B/s).

=item B<--warning-write-usage>

Warning threshold for disk write throughput (B/s).

=item B<--critical-write-usage>

Critical threshold for disk write throughput (B/s).

=item B<--warning-read-iops>

Warning threshold for read IOPS.

=item B<--critical-read-iops>

Critical threshold for read IOPS.

=item B<--warning-write-iops>

Warning threshold for write IOPS.

=item B<--critical-write-iops>

Critical threshold for write IOPS.

=back

=cut
