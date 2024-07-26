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

package storage::hp::primera::restapi::mode::diskusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        "Used: %s of %s (%.2f%%) Free: %s (%.2f%%)",
        $total_used_value . " " . $total_used_unit,
        $total_size_value . " " . $total_size_unit,
        $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit,
        $self->{result_values}->{prct_free}
    );
}

sub custom_global_total_usage_output {
    my ($self, %options) = @_;

    my ($used_human, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_human, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my $msg = "Total Used: $used_human $used_unit / $total_human $total_unit" ;

    return $msg;
}

sub custom_global_total_free_output {
    my ($self, %options) = @_;

    my ($free_human, $free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my $msg = "Total Free: $free_human $free_unit" ;

    return $msg;
}


sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'disk', type => 1, cb_prefix_output => 'prefix_disk_output', message_multiple => 'All disks are ok' },
    ];
    $self->{maps_counters}->{global} = [
        {
            label => 'total-usage',
            nlabel => 'disks.total.space.usage.bytes',
            set => {
                key_values => [ { name => 'used' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_global_total_usage_output'),
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        {
            label => 'total-usage-prct',
            nlabel => 'disks.total.space.usage.percent',
            set => {
                key_values => [ { name => 'used_prct' }],
                output_template => 'Total percentage used: %.2f %%',
                perfdatas => [
                    { template => '%s', uom => '%', min => 0, max => 100 }
                ]
            }
        },
        {
            label => 'total-free',
            nlabel => 'disks.total.space.free.bytes',
            set => {
                key_values => [ { name => 'free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_global_total_free_output'),
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];
    $self->{maps_counters}->{disk} = [
        { label => 'usage', nlabel => 'disk.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'id' }, { name => 'position' }, { name => 'manufacturer' }, { name => 'model' }, { name => 'serial' }  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'id' }
                ]
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'disk.space.free.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'id' }, { name => 'position' }, { name => 'manufacturer' }, { name => 'model' }, { name => 'serial' }  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'id' }
                ]
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'disk.space.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'id' }, { name => 'position' }, { name => 'manufacturer' }, { name => 'model' }, { name => 'serial' }  ],
                output_template => 'Used : %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'id' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-id:s' => { name => 'filter_id' },
        'filter-manufacturer:s' => { name => 'filter_manufacturer' },
        'filter-model:s' => { name => 'filter_model' },
        'filter-serial:s' => { name => 'filter_serial' },
        'filter-position:s' => { name => 'filter_position' },
    });
    
    return $self;
}

sub prefix_disk_output {
    my ($self, %options) = @_;
    
    #return "Disk '" . $options{instance_value}->{display} . "' ";
    return sprintf(
        "Disk #%s (%s/%s, serial: %s) located %s has ",
        $options{instance_value}->{id},
        $options{instance_value}->{manufacturer},
        $options{instance_value}->{model},
        $options{instance_value}->{serial},
        $options{instance_value}->{position}
    );
}

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $options{custom}->request_api(
        endpoint => '/api/v1/disks'
    );
    my $disks = $response->{members};

    $self->{global} = {
        total     => 0,
        free      => 0,
        used      => 0,
        used_prct => 0
    };
    $self->{disk} = {};

    for my $disk (@{$disks}) {

        my $disk_intro = "disk #" . $disk->{id} . " (" . $disk->{manufacturer} . "/" . $disk->{model}
                        . ", serial: " . $disk->{serialNumber} . ") located '" . $disk->{position};

        # skip if filtered by id
        if (defined($self->{option_results}->{filter_id})
                 and $self->{option_results}->{filter_id} ne ''
                 and $disk->{id} !~ /$self->{option_results}->{filter_id}/) {
            $self->{output}->output_add(long_msg => "Skipping $disk_intro because the id does not match the filter.", debug => 1);
            next;
        }
        # skip if filtered by manufacturer
        if (defined($self->{option_results}->{filter_manufacturer})
                 and $self->{option_results}->{filter_manufacturer} ne ''
                 and $disk->{manufacturer} !~ /$self->{option_results}->{filter_manufacturer}/) {
            $self->{output}->output_add(long_msg => "Skipping $disk_intro because the manufacturer does not match the filter.", debug => 1);
            next;
        }
        # skip if filtered by model
        if (defined($self->{option_results}->{filter_model})
                 and $self->{option_results}->{filter_model} ne ''
                 and $disk->{model} !~ /$self->{option_results}->{filter_model}/) {
            $self->{output}->output_add(long_msg => "Skipping $disk_intro because the model does not match the filter.", debug => 1);
            next;
        }
        # skip if filtered by position
        if (defined($self->{option_results}->{filter_position})
                 and $self->{option_results}->{filter_position} ne ''
                 and $disk->{position} !~ /$self->{option_results}->{filter_position}/) {
            $self->{output}->output_add(long_msg => "Skipping $disk_intro because the position does not match the filter.", debug => 1);
            next;
        }
        # skip if filtered by serial
        if (defined($self->{option_results}->{filter_serial})
                 and $self->{option_results}->{filter_serial} ne ''
                 and $disk->{serial} !~ /$self->{option_results}->{filter_serial}/) {
            $self->{output}->output_add(long_msg => "Skipping $disk_intro because the serial does not match the filter.", debug => 1);
            next;
        }

        my $total = $disk->{totalSizeMiB} * 1024 * 1024;
        my $free  = $disk->{freeSizeMiB} * 1024 * 1024;
        my $used  = $total - $free;

        $self->{global}->{total} = $self->{global}->{total} + $total;
        $self->{global}->{free}  = $self->{global}->{free} + $free;
        $self->{global}->{used}  = $self->{global}->{used} + $used;

        $self->{disk}->{$disk->{id}} = {
            id           => $disk->{id},
            total        => $total,
            used         => $used,
            free         => $free,
            prct_used    => $used * 100 / $total,
            prct_free    => $free * 100 / $total,
            manufacturer => $disk->{manufacturer},
            model        => $disk->{model},
            serial       => $disk->{serialNumber},
            position     => $disk->{position}
        };
    }

    $self->{global}->{used_prct} = $self->{global}->{used} * 100 / $self->{global}->{total} if ($self->{global}->{total} > 0);

    if (scalar(keys %{$self->{disk}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No disk found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check disk usage.

=over 8

=item B<--filter-counters>

Define which counters (filtered by regular expression) should be monitored.
Example: --filter-counters='^usage$'

=item B<--filter-id>

Define which disks should be monitored based on their IDs.
This option will be treated as a regular expression.

=item B<--filter-manufacturer>

Define which volumes should be monitored based on the disk manufacturer.
This option will be treated as a regular expression.

=item B<--filter-model>

Define which volumes should be monitored based on the disk model.
This option will be treated as a regular expression.

=item B<--filter-serial>

Define which volumes should be monitored based on the disk serial number.
This option will be treated as a regular expression.

=item B<--filter-position>

Define which volumes should be monitored based on the disk position.
The position is composed of 3 integers, separated by colons:
- Cage number where the physical disk is in.
- Magazine number where the physical disk is in.
- For DC4 cages, disk position within the magazine. For non-DC4 cages, 0.
Example: 7:5:0
This option will be treated as a regular expression.

=item B<--warning-*> B<--critical-*>

Thresholds for disk usage metrics. * may be replaced with:
- For individual disks: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).
- For global statistics: 'total-usage' (B), 'total-free' (B), 'total-usage-prct' (%).

=back

=cut
