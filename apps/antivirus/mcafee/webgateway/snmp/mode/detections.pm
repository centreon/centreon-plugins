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

package apps::antivirus::mcafee::webgateway::snmp::mode::detections;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'categories', type => 1, cb_prefix_output => 'prefix_categories_output',
          message_multiple => 'All categories are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'malware-detected', nlabel => 'malwares.detected.persecond', set => {
                key_values => [ { name => 'stMalwareDetected', per_second => 1 } ],
                output_template => 'Malware detected (per sec): %d',
                perfdatas => [
                    { label => 'malware_detected', template => '%d', min => 0, unit => 'detections/s' }
                ]
            }
        }
    ];
    $self->{maps_counters}->{categories} = [
        { label => 'category', nlabel => 'category.malwares.detected.persecond', set => {
                key_values => [ { name => 'stCategoryCount', per_second => 1 }, { name => 'stCategoryName' } ],
                output_template => 'detections (per sec): %d',
                perfdatas => [
                    { label => 'category', template => '%d',
                      min => 0, unit => 'detections/s', label_extra_instance => 1,
                      instance_use => 'stCategoryName' }
                ]
            }
        }
    ];
}

sub prefix_categories_output {
    my ($self, %options) = @_;

    return "Category '" . $options{instance_value}->{stCategoryName} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

my $oid_stMalwareDetected = '.1.3.6.1.4.1.1230.2.7.2.1.2.0';

my $mapping = {
    stCategoryName => { oid => '.1.3.6.1.4.1.1230.2.7.2.1.10.1.1' },
    stCategoryCount => { oid => '.1.3.6.1.4.1.1230.2.7.2.1.10.1.2' },
};
my $oid_stCategoriesEntry = '.1.3.6.1.4.1.1230.2.7.2.1.10.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'mcafee_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $results = $options{snmp}->get_leef(oids => [ $oid_stMalwareDetected ], nothing_quit => 1);
    my $results2 = $options{snmp}->get_table(oid => $oid_stCategoriesEntry, nothing_quit => 1);

    $self->{global} = {
        stMalwareDetected => $results->{$oid_stMalwareDetected},
    };

    $self->{categories} = {};
    foreach my $oid (keys %{$results2}) {
        next if ($oid !~ /^$mapping->{stCategoryName}->{oid}\.(\d+)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results2, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{stCategoryName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{stCategoryName} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{categories}->{ $result->{stCategoryName} } = {
            stCategoryName => $result->{stCategoryName},
            stCategoryCount => $result->{stCategoryCount}
        }
    }

    if (scalar(keys %{$self->{categories}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No categories found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check detections statistics.

=over 8

=item B<--filter-name>

Filter category name (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
(Example: --filter-counters='^(?!(category)$)')

=item B<--warning-*>

Threshold warning.
Can be: 'malware-detected', 'category'

=item B<--critical-*>

Threshold critical.
Can be: 'malware-detected', 'category'

=back

=cut
