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

package apps::kingdee::eas::mode::classloading;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'class-loaded', nlabel => 'java.class.loaded.count', set => {
                key_values => [ { name => 'loadedclass' } ],
                output_template => 'class loaded: %s',
                perfdatas => [
                    { value => 'loadedclass', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'class-unloaded', nlabel => 'java.class.unloaded.count', set => {
                key_values => [ { name => 'unloadedclass', diff => 1 } ],
                output_template => 'class unloaded: %s',
                perfdatas => [
                    { value => 'unloadedclass', template => '%s', min => 0 },
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
        'urlpath:s' => { name => 'url_path', default => "/easportal/tools/nagios/checkclassloading.jsp" },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path});

    if ($webcontent !~ /(LoadedClassCount|UnloadedClassCount)/i) {
        $self->{output}->add_option_msg(short_msg => 'cannot find classloading status.');
        $self->{output}->option_exit();
    }

    $self->{global} = { loadedclass => 0, unloadedclass => 0 };
    $self->{global}->{loadedclass} = $1 if ($webcontent =~ /LoadedClassCount=\s*(\d+)/mi);
    $self->{global}->{unloadedclass} = $1 if ($webcontent =~ /UnloadedClassCount=\s*(\d+)/mi);

    $self->{cache_name} = 'kingdee_' . $self->{mode} . '_' . $options{custom}->get_hostname() . '_' . $options{custom}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check EAS application classLoading status.

=over 8

=item B<--urlpath>

Set path to get status page. (Default: '/easportal/tools/nagios/checkclassloading.jsp')

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'class-loaded', 'class-unloaded'.

=back

=cut
