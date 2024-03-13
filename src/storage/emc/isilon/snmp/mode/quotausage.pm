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

package storage::emc::isilon::snmp::mode::quotausage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my ($label, $nlabel) = ('used', $self->{nlabel});
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        ($label, $nlabel) = ('free', 'storage.space.free.bytes');
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label, unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        nlabel => $nlabel,
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
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

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        'Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_size'};
    my $reserved_value = 0;
    if (defined($self->{instance_mode}->{option_results}->{space_reservation})) {
        $reserved_value = $self->{instance_mode}->{option_results}->{space_reservation} * $self->{result_values}->{total} / 100;
    }

    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used} - $reserved_value;
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / ($self->{result_values}->{total} - $reserved_value);
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    
    # limit to 100. Better output.
    if ($self->{result_values}->{prct_used} > 100) {
        $self->{result_values}->{free} = 0;
        $self->{result_values}->{prct_used} = 100;
        $self->{result_values}->{prct_free} = 0;
    }

    return 0;
}

sub prefix_quotas_output {
    my ($self, %options) = @_;

    return "Quota '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'quotas', type => 1, cb_prefix_output => 'prefix_quotas_output', message_multiple => 'All quotas are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'count', nlabel => 'storage.partitions.count', display_ok => 0, set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Partitions count: %d',
                perfdatas => [
                    { label => 'count', template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{quotas} = [
        { label => 'usage', nlabel => 'storage.space.usage.bytes', set => {
                key_values => [ { name => 'display' }, { name => 'used' }, { name => 'size' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold')
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'       => { name => 'filter_name' },
        'units:s'             => { name => 'units', default => '%' },
        'free'                => { name => 'free' },
        'reload-cache-time:s' => { name => 'reload_cache_time', default => 180 },
        'show-cache'          => { name => 'show_cache' },
    });

    $self->{storage_id_selected} = [];
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{statefile_cache}->check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->get_selection(snmp => $options{snmp});

    my $oid_quotaHardThreshold = '.1.3.6.1.4.1.12124.1.12.1.1.7';
    my $oid_quotaUsage = '.1.3.6.1.4.1.12124.1.12.1.1.13';

    $options{snmp}->load(
        oids => [ $oid_quotaHardThreshold, $oid_quotaUsage ], 
        instances => $self->{storage_id_selected},
        instance_regexp => '^(.*)$',
        nothing_quit => 1
    );
    my $result = $options{snmp}->get_leef();

    $self->{global}->{count} = 0;
    $self->{quotas} = {};
    foreach (sort @{$self->{storage_id_selected}}) {
        my $name_quota = $self->{statefile_cache}->get(name => $_);

        my $size = $result->{$oid_quotaHardThreshold . '.' . $_};
        my $used = $result->{$oid_quotaUsage . '.' . $_};

        if ($size <= 0) { # no hard threshold
            $self->{output}->output_add(
                long_msg => sprintf(
                    "skipping storage '%s': total size is <= 0 (%s)", 
                    $name_quota,
                    $size
                ),
                debug => 1
            );
            next;
        }

        $self->{quotas}->{$_} = {
            display => $name_quota,
            size => $size,
            used => $used,
        };
        $self->{global}->{count}++;
    }

    if (scalar(keys %{$self->{quotas}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'Issue with quotas information (see details)');
        $self->{output}->option_exit();
    }
}

sub reload_cache {
    my ($self, %options) = @_;
    my $datas = {};

    $datas->{last_timestamp} = time();
    $datas->{all_ids} = [];
    
    my $oid_quotaType = '.1.3.6.1.4.1.12124.1.12.1.1.2';
    my $oid_quotaPath = '.1.3.6.1.4.1.12124.1.12.1.1.5';
    
    my $result = $options{snmp}->get_multiple_table(
        oids => [ { oid => $oid_quotaType }, { oid => $oid_quotaPath } ],
        nothing_quit => 1
    );
    
    foreach my $oid (keys %{$result->{$oid_quotaType}}) {
        $oid =~ /^$oid_quotaType\.(.*)$/;
        my $instance = $1;
        next if ($result->{$oid_quotaType}->{$oid_quotaType . '.' . $instance} ne "4"); # directory
        my $name = $result->{$oid_quotaPath}->{$oid_quotaPath . '.' . $instance};

        push @{$datas->{all_ids}}, $1;
        $datas->{$1} = $name;
    }
    
    if (scalar(@{$datas->{all_ids}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Can't construct cache...");
        $self->{output}->option_exit();
    }

    $self->{statefile_cache}->write(data => $datas);
}

sub get_selection {
    my ($self, %options) = @_;

    # init cache file
    my $has_cache_file = $self->{statefile_cache}->read(statefile => 'cache_isilon_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode});
    if (defined($self->{option_results}->{show_cache})) {
        $self->{output}->add_option_msg(long_msg => $self->{statefile_cache}->get_string_content());
        $self->{output}->option_exit();
    }

    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');
    if ($has_cache_file == 0 || !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($self->{option_results}->{reload_cache_time}) * 60))) {
        $self->reload_cache(snmp => $options{snmp});
        $self->{statefile_cache}->read();
    }

    my $all_ids = $self->{statefile_cache}->get(name => 'all_ids');

    foreach my $i (@{$all_ids}) {
        my $name = $self->{statefile_cache}->get(name => $i);
        next if (!defined($name));
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/);

        push @{$self->{storage_id_selected}}, $i;
    }

    if (scalar(@{$self->{storage_id_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No storage found. Can be: filters, cache file.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check quotas usage (only check directory quotas with enforced hard threshold).

=over 8

=item B<--filter-name>

Filter quotas based on name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage', 'count'.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--reload-cache-time>

Time in minutes before reloading cache file (default: 180).

=item B<--show-cache>

Display cache storage data.

=back

=cut
