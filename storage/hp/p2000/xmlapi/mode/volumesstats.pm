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

package storage::hp::p2000::xmlapi::mode::volumesstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_write_cache_calc {
    my ($self, %options) = @_;
    my $diff_hits = ($options{new_datas}->{$self->{instance} . '_write-cache-hits'} - $options{old_datas}->{$self->{instance} . '_write-cache-hits'});
    my $total = $diff_hits
                + ($options{new_datas}->{$self->{instance} . '_write-cache-misses'} - $options{old_datas}->{$self->{instance} . '_write-cache-misses'});
    
    if ($total == 0) {
        $self->{error_msg} = "skipped";
        return -2;
    }
    
    $self->{result_values}->{'write-cache-hits_prct'} = $diff_hits * 100 / $total;
    return 0;
}

sub custom_read_cache_calc {
    my ($self, %options) = @_;
    my $diff_hits = ($options{new_datas}->{$self->{instance} . '_read-cache-hits'} - $options{old_datas}->{$self->{instance} . '_read-cache-hits'});
    my $total = $diff_hits
                + ($options{new_datas}->{$self->{instance} . '_read-cache-misses'} - $options{old_datas}->{$self->{instance} . '_read-cache-misses'});
    
    if ($total == 0) {
        $self->{error_msg} = "skipped";
        return -2;
    }
    
    $self->{result_values}->{'read-cache-hits_prct'} = $diff_hits * 100 / $total;
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'volume', type => 1, cb_prefix_output => 'prefix_volume_output', message_multiple => 'All volumes statistics are ok', skipped_code => { -2 => 1, -10 => 1 } }
    ];
    
    $self->{maps_counters}->{volume} = [
        { label => 'read', nlabel => 'volume.io.read.usage.bytespersecond', set => {
                key_values => [ { name => 'data-read-numeric', per_second => 1 } ],
                output_template => 'Read I/O : %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write', nlabel => 'volume.io.write.usage.bytespersecond', set => {
                key_values => [ { name => 'data-written-numeric', per_second => 1 } ],
                output_template => 'Write I/O : %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'read-cache-hits', nlabel => 'volume.cache.read.hits.percentage', set => {
                key_values => [ { name => 'read-cache-hits', diff => 1 }, { name => 'read-cache-misses', diff => 1 } ],
                closure_custom_calc => $self->can('custom_read_cache_calc'),
                output_template => 'Read Cache Hits : %.2f %%',
                output_use => 'read-cache-hits_prct',  threshold_use => 'read-cache-hits_prct',
                perfdatas => [
                    { value => 'read-cache-hits_prct', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write-cache-hits', nlabel => 'volume.cache.write.hits.percentage', set => {
                key_values => [ { name => 'write-cache-hits', diff => 1 }, { name => 'write-cache-misses', diff => 1 } ],
                closure_custom_calc => $self->can('custom_write_cache_calc'),
                output_template => 'Write Cache Hits : %.2f %%',
                output_use => 'write-cache-hits_prct', threshold_use => 'write-cache-hits_prct',
                perfdatas => [
                    { value => 'write-cache-hits_prct', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'iops', nlabel => 'volume.io.usage.iops', set => {
                key_values => [ { name => 'iops' } ],
                output_template => 'IOPs : %s',
                perfdatas => [
                    { unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'name:s' => { name => 'name' },
        'regexp' => { name => 'use_regexp' },
    });

    return $self;
}

sub prefix_volume_output {
    my ($self, %options) = @_;
    
    return "Volume '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($result) = $options{custom}->get_infos(
        cmd => 'show volume-statistics', 
        base_type => 'volume-statistics',
        key => 'volume-name',
        properties_name => '^data-read-numeric|data-written-numeric|write-cache-hits|write-cache-misses|read-cache-hits|read-cache-misses|iops$'
    );

    $self->{volume} = {};
    foreach my $name (keys %$result) {
        if (defined($self->{option_results}->{name}) && $self->{option_results}->{name} ne '') {
            if ((!defined($self->{option_results}->{use_regexp}) && $name ne $self->{option_results}->{name}) |
                (defined($self->{option_results}->{use_regexp}) && $name !~ /$self->{option_results}->{name}/)
            ) {
                $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching volume name.", debug => 1);
                next;
            }
        }
        
        $self->{volume}->{$name} = { display => $name, %{$result->{$name}} };
    }

    if (scalar(keys %{$self->{volume}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No volume found.');
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = 'hp_p2000_' . $options{custom}->{hostname}  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check volume statistics.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'read', 'write', 'iops', 'write-cache-hits', 'read-cache-hits'.

=item B<--critical-*>

Threshold critical.
Can be: 'read', 'write', 'iops', 'write-cache-hits', 'read-cache-hits'.

=item B<--name>

Set the volume name.

=item B<--regexp>

Allows to use regexp to filter volume name (with option --name).

=back

=cut
