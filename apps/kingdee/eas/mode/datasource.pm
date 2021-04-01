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

package apps::kingdee::eas::mode::datasource;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'datasource', type => 1, cb_prefix_output => 'prefix_datasource_output', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{datasource} = [
        { label => 'pool-size-initial', nlabel => 'datasource.pool.size.initial.count', display_ok => 0, set => {
                key_values => [ { name => 'init_pool_size' } ],
                output_template => 'pool initial size: %s',
                perfdatas => [
                    { value => 'init_pool_size', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'pool-size-max', nlabel => 'datasource.pool.size.max.count', display_ok => 0, set => {
                key_values => [ { name => 'max_pool_size' } ],
                output_template => 'pool max size: %s',
                perfdatas => [
                    { value => 'max_pool_size', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'idle-timeout', nlabel => 'datasource.idle.timeout.count', display_ok => 0, set => {
                key_values => [ { name => 'idle_timeout' } ],
                output_template => 'idle timeout: %s',
                perfdatas => [
                    { value => 'idle_timeout', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'connections-active', nlabel => 'datasource.connections.active.count', set => {
                key_values => [ { name => 'active_conn_count' } ],
                output_template => 'connections active: %s',
                perfdatas => [
                    { value => 'active_conn_count', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'connections-current', nlabel => 'datasource.connections.current.count', display_ok => 0, set => {
                key_values => [ { name => 'cur_conn_count' } ],
                output_template => 'connections current: %s',
                perfdatas => [
                    { value => 'cur_conn_count', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'connections-max', nlabel => 'datasource.connections.max.count', display_ok => 0, set => {
                key_values => [ { name => 'max_conn_count' } ],
                output_template => 'connections max: %s',
                perfdatas => [
                    { value => 'max_conn_count', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'connections-created', nlabel => 'datasource.connections.created.count', display_ok => 0, set => {
                key_values => [ { name => 'create_count', diff => 1 } ],
                output_template => 'connections created: %s',
                perfdatas => [
                    { value => 'create_count', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'connections-closed', nlabel => 'datasource.connections.closed.count', display_ok => 0, set => {
                key_values => [ { name => 'close_count', diff => 1 } ],
                output_template => 'connections closed: %s',
                perfdatas => [
                    { value => 'close_count', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub prefix_datasource_output {
    my ($self, %options) = @_;

    return "Datasource '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'urlpath:s'    => { name => 'url_path', default => "/easportal/tools/nagios/checkdatasources.jsp" },
        'datasource:s' => { name => 'datasource' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{datasource}) || $self->{option_results}->{datasource} eq "") {
        $self->{output}->add_option_msg(short_msg => "Missing datasource name.");
        $self->{output}->option_exit();
    }
    $self->{option_results}->{url_path} .= "?ds=" . $self->{option_results}->{datasource};
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path});

    if ($webcontent !~ /^Name=/i) {
        $self->{output}->add_option_msg(short_msg => "Cannot find datasource '" .  $self->{option_results}->{datasource} . "' status.");
        $self->{output}->option_exit();
    }

    $self->{datasource}->{$self->{option_results}->{datasource}} = { display => $self->{option_results}->{datasource} };

    $self->{datasource}->{$self->{option_results}->{datasource}}->{init_pool_size} = $1 if ($webcontent =~ /InitialPoolSize=(\d+)\s/i);
    $self->{datasource}->{$self->{option_results}->{datasource}}->{max_pool_size} = $1 if ($webcontent =~ /MaxPoolSize=(\d+)\s/i);
    $self->{datasource}->{$self->{option_results}->{datasource}}->{idle_timeout} = $1 if ($webcontent =~ /IdleTimeout=(\d+)\s/i);
    $self->{datasource}->{$self->{option_results}->{datasource}}->{cur_conn_count} = $1 if ($webcontent =~ /CurrentConnectionCount=(\d+)\s/i);
    $self->{datasource}->{$self->{option_results}->{datasource}}->{cur_avail_conn_count} = $1 if ($webcontent =~ /CurrentAvailableConnectionCount=(\d+)\s/i);
    $self->{datasource}->{$self->{option_results}->{datasource}}->{max_conn_count} = $1 if ($webcontent =~ /MaxConnectionCount=(\d+)\s/i);
    $self->{datasource}->{$self->{option_results}->{datasource}}->{create_count} = $1 if ($webcontent =~ /CreateCount=(\d+)\s/i);
    $self->{datasource}->{$self->{option_results}->{datasource}}->{close_count} = $1 if ($webcontent =~ /CloseCount=(\d+)\s/i);

    $self->{datasource}->{$self->{option_results}->{datasource}}->{active_conn_count} = $self->{datasource}->{$self->{option_results}->{datasource}}->{cur_conn_count} - $self->{datasource}->{$self->{option_results}->{datasource}}->{cur_avail_conn_count};

    $self->{cache_name} = 'kingdee_' . $self->{mode} . '_' . $options{custom}->get_hostname() . '_' . $options{custom}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{datasource}) ? md5_hex($self->{option_results}->{datasource}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check EAS application datasource status.

=over 8

=item B<--urlpath>

Specify path to get status page. (Default: '/easportal/tools/nagios/checkdatasources.jsp')

=item B<--datasource>

Specify the datasource name.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'pool-size-initial', 'pool-size-max',
'idle-timeout', 'connections-active', 'connections-current',
'connections-max', 'connections-created', 'connections-closed'.

=back

=cut
