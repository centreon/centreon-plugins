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
# Author : CHEN JUN , aladdin.china@gmail.com

package apps::kingdee::eas::mode::ibmjvmgc;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 }  },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'collection', nlabel => 'gc.collection.count', set => {
                key_values => [ { name => 'collection_count', diff => 1 } ],
                output_template => 'gc collection count: %s',
                perfdatas => [
                    { value => 'collection_count', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'collection-time', nlabel => 'gc.collection.time.milliseconds', set => {
                key_values => [ { name => 'collection_time', diff => 1 } ],
                output_template => 'gc collection time: %s ms',
                perfdatas => [
                    { value => 'collection_time', template => '%s', min => 0, unit => 'ms' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'urlpath:s' => { name => 'url_path', default => "/easportal/tools/nagios/checkgc_j9gen.jsp" },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
        
    my $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path});

    if ($webcontent !~ /CollectionCount=\d+/mi) {
        $self->{output}->add_option_msg(short_msg => 'Cannot find ibm jdk j9 gc status');
        $self->{output}->option_exit();
    }

    my ($collectioncount, $collectiontime) = (0, 0);

    $self->{global} = {};
    if ($webcontent =~ /CollectionCount=(\d+)\sCollectionTime=(\d+)/mi) {
        $self->{global}->{collection_count} = $1;
        $self->{global}->{collection_time} = $2;
    }
 
    $self->{cache_name} = 'kingdee_' . $self->{mode} . '_' . $options{custom}->get_hostname() . '_' . $options{custom}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check EAS application jvm gc status.

=over 8

=item B<--urlpath>

Set path to get status page. (Default: '/easportal/tools/nagios/checkgc_j9.jsp')

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'collection', 'collection-time'.

=back

=cut
