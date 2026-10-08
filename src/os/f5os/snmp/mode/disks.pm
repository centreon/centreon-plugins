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

package os::f5os::snmp::mode::disks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::statefile;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;
use Digest::SHA qw(sha256_hex);

sub custom_latency_calc {
    my ($self, %options) = @_;

    my $diff_ops = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{ops}}
        - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{ops}};
    my $diff_latency = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{latency}}
        - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{latency}};

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{latency} = $diff_ops > 0 ? $diff_latency / $diff_ops : 0;

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'disks',
            type => COUNTER_TYPE_INSTANCE,
            prefix_output => "Disk '%{name}' ",
            message_multiple => 'All disks are ok',
            skipped_code => { NO_VALUE() => 1, BUFFER_CREATION() => 1 }
        }
    ];

    $self->{maps_counters}->{disks} = [
        { label => 'space-usage-prct', nlabel => 'disk.space.usage.percentage', set => {
                key_values => [ { name => 'used_prct' }, { name => 'name' } ],
                output_template => 'space used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'read-iops', nlabel => 'disk.io.read.usage.iops', set => {
                key_values => [ { name => 'read_iops', per_second => 1 }, { name => 'name' } ],
                output_template => 'read iops: %.2f',
                perfdatas => [
                    { template => '%.2f', unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'write-iops', nlabel => 'disk.io.write.usage.iops', set => {
                key_values => [ { name => 'write_iops', per_second => 1 }, { name => 'name' } ],
                output_template => 'write iops: %.2f',
                perfdatas => [
                    { template => '%.2f', unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'read-usage', nlabel => 'disk.io.read.usage.bytespersecond', set => {
                key_values => [ { name => 'read_bytes', per_second => 1 }, { name => 'name' } ],
                output_template => 'read: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'write-usage', nlabel => 'disk.io.write.usage.bytespersecond', set => {
                key_values => [ { name => 'write_bytes', per_second => 1 }, { name => 'name' } ],
                output_template => 'write: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'read-latency', nlabel => 'disk.io.read.latency.milliseconds', set => {
                key_values => [ { name => 'read_latency', diff => 1 }, { name => 'read_iops', diff => 1 }, { name => 'name' } ],
                closure_custom_calc => $self->can('custom_latency_calc'),
                closure_custom_calc_extra_options => { latency => 'read_latency', ops => 'read_iops' },
                output_template => 'read latency: %.2f ms',
                output_use => 'latency',
                threshold_use => 'latency',
                perfdatas => [
                    { value => 'latency', template => '%.2f', unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'write-latency', nlabel => 'disk.io.write.latency.milliseconds', set => {
                key_values => [ { name => 'write_latency', diff => 1 }, { name => 'write_iops', diff => 1 }, { name => 'name' } ],
                closure_custom_calc => $self->can('custom_latency_calc'),
                closure_custom_calc_extra_options => { latency => 'write_latency', ops => 'write_iops' },
                output_template => 'write latency: %.2f ms',
                output_use => 'latency',
                threshold_use => 'latency',
                perfdatas => [
                    { value => 'latency', template => '%.2f', unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-name:s'      => { name => 'include_name' },
        'exclude-name:s'      => { name => 'exclude_name' },
        'reload-cache-time:s' => { name => 'reload_cache_time', default => 180 },
        'show-cache'          => { name => 'show_cache' }
    });
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);
    $self->{statefile_cache}->check_options(%options);
}

my $oid_diskInfoEntry = '.1.3.6.1.4.1.12276.1.2.1.2.1.1';
my $mapping_info = {
    model  => { oid => '.1.3.6.1.4.1.12276.1.2.1.2.1.1.3' }, # diskModel
    vendor => { oid => '.1.3.6.1.4.1.12276.1.2.1.2.1.1.4' }, # diskVendor
    serial => { oid => '.1.3.6.1.4.1.12276.1.2.1.2.1.1.6' }, # diskSerialNo
    size   => { oid => '.1.3.6.1.4.1.12276.1.2.1.2.1.1.7' }, # diskSize
    type   => { oid => '.1.3.6.1.4.1.12276.1.2.1.2.1.1.8' }  # diskType
};
my $mapping_stats = {
    used_prct     => { oid => '.1.3.6.1.4.1.12276.1.2.1.2.2.1.3' },  # diskPercentageUsed
    read_iops     => { oid => '.1.3.6.1.4.1.12276.1.2.1.2.2.1.5' },  # diskReadIops
    read_bytes    => { oid => '.1.3.6.1.4.1.12276.1.2.1.2.2.1.7' },  # diskReadBytes
    read_latency  => { oid => '.1.3.6.1.4.1.12276.1.2.1.2.2.1.8' },  # diskReadLatencyMs
    write_iops    => { oid => '.1.3.6.1.4.1.12276.1.2.1.2.2.1.9' },  # diskWriteIops
    write_bytes   => { oid => '.1.3.6.1.4.1.12276.1.2.1.2.2.1.11' }, # diskWriteBytes
    write_latency => { oid => '.1.3.6.1.4.1.12276.1.2.1.2.2.1.12' }  # diskWriteLatencyMs
};

sub reload_cache {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_diskInfoEntry, nothing_quit => 1);

    my $datas = { last_timestamp => time(), disks => {} };
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping_info->{model}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping_info, results => $snmp_result, instance => $instance);
        # instance = <len>.<component chars>.<len>.<disk name chars> (INDEX { index, diskName })
        my @indexes = split(/\./, $instance);
        my $component = $self->{output}->decode(join('', map(chr($_), splice(@indexes, 0, shift(@indexes)))));
        my $disk_name = $self->{output}->decode(join('', map(chr($_), splice(@indexes, 0, shift(@indexes)))));
        $datas->{disks}->{$instance} = {
            name => $component . '-' . $disk_name,
            map(($_ => defined($result->{$_}) ? $self->{output}->decode($result->{$_}) : ''), keys %$mapping_info)
        };
    }

    if (scalar(keys %{$datas->{disks}}) <= 0) {
        $self->{output}->option_exit(short_msg => "Can't construct cache...");
    }

    $self->{statefile_cache}->write(data => $datas);
    return $datas->{disks};
}

sub get_selection {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{statefile_cache}->read(
        statefile => 'f5os_' . $self->{mode} . '_index_' . $options{snmp}->get_hostname() . '_' . $options{snmp}->get_port()
    );
    if (defined($self->{option_results}->{show_cache})) {
        $self->{output}->add_option_msg(long_msg => $self->{statefile_cache}->get_string_content());
        $self->{output}->option_exit();
    }

    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');
    my $disks = $self->{statefile_cache}->get(name => 'disks');
    if ($has_cache_file == 0 || !defined($timestamp_cache) || !defined($disks)
        || (time() - $timestamp_cache) > $self->{option_results}->{reload_cache_time} * 60) {
        $disks = $self->reload_cache(snmp => $options{snmp});
    }

    my $selection = {};
    foreach (keys %$disks) {
        next if is_excluded($disks->{$_}->{name}, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});

        $selection->{$_} = $disks->{$_};
    }

    if (scalar(keys %$selection) <= 0) {
        $self->{output}->option_exit(short_msg => 'No disk found. Can be: filters, cache file.');
    }

    return $selection;
}

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->option_exit(short_msg => 'Need to use SNMP v2c or v3.');
    }

    my $disks = $self->get_selection(snmp => $options{snmp});

    $options{snmp}->load(
        oids            => [ map($_->{oid}, values(%$mapping_stats)) ],
        instances       => [ keys %$disks ],
        instance_regexp => '^(.*)$',
        nothing_quit    => 1
    );
    my $snmp_result = $options{snmp}->get_leef();

    $self->{disks} = {};
    foreach my $instance (keys %$disks) {
        my $result = $options{snmp}->map_instance(mapping => $mapping_stats, results => $snmp_result, instance => $instance);

        $self->{disks}->{$instance} = {
            name => $disks->{$instance}->{name},
            %$result
        };
    }

    $self->{cache_name} = 'f5os_' . $self->{mode} . '_' . $options{snmp}->get_hostname() . '_' . $options{snmp}->get_port() . '_' .
        sha256_hex(join('_', map($self->{option_results}->{$_} // '', qw/filter_counters include_name exclude_name/)));
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name', 'model', 'vendor', 'serial', 'size', 'type']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $disks = $self->get_selection(snmp => $options{snmp});
    foreach (sort { $a->{name} cmp $b->{name} } values %$disks) {
        $self->{output}->add_disco_entry(
            name   => $_->{name},
            model  => $_->{model},
            vendor => $_->{vendor},
            serial => $_->{serial},
            size   => $_->{size},
            type   => $_->{type}
        );
    }
}

1;

__END__

=head1 MODE

Check disks usage and I/O statistics.
This mode also supports service discovery (C<--disco-format>, C<--disco-show>).

=over 8

=item B<--include-name>

Filter disks by name (can be a regexp).

=item B<--exclude-name>

Exclude disks by name (can be a regexp).

=item B<--reload-cache-time>

Time in minutes before reloading the disks cache file (default: 180).

=item B<--show-cache>

Display the content of the disks cache file.

=item B<--warning-space-usage-prct>

Threshold in percentage.

=item B<--critical-space-usage-prct>

Threshold in percentage.

=item B<--warning-read-iops>

Threshold in operations per second.

=item B<--critical-read-iops>

Threshold in operations per second.

=item B<--warning-write-iops>

Threshold in operations per second.

=item B<--critical-write-iops>

Threshold in operations per second.

=item B<--warning-read-usage>

Threshold in bytes per second.

=item B<--critical-read-usage>

Threshold in bytes per second.

=item B<--warning-write-usage>

Threshold in bytes per second.

=item B<--critical-write-usage>

Threshold in bytes per second.

=item B<--warning-read-latency>

Threshold in milliseconds (average latency per read operation).

=item B<--critical-read-latency>

Threshold in milliseconds (average latency per read operation).

=item B<--warning-write-latency>

Threshold in milliseconds (average latency per write operation).

=item B<--critical-write-latency>

Threshold in milliseconds (average latency per write operation).

=back

=cut
