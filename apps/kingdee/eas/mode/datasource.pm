#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
            {
            "urlpath:s"         => { name => 'url_path', default => "/easportal/tools/nagios/checkdatasources.jsp" },
            "datasource:s"      => { name => 'datasource' },
            "warning:s"         => { name => 'warning' },
            "critical:s"        => { name => 'critical' },
            });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{datasource}) || $self->{option_results}->{datasource} eq "") {
        $self->{output}->add_option_msg(short_msg => "Missing datasource name.");
        $self->{output}->option_exit();
    }
    $self->{option_results}->{url_path} .= "?ds=" . $self->{option_results}->{datasource};

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    
    my $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path});

    if ($webcontent !~ /^Name=/i) {
        $self->{output}->output_add(
            severity  => 'UNKNOWN',
            short_msg => "Cannot find datasource \'" .  $self->{option_results}->{datasource} . "\' status."
        );
    }

    my $init_pool_size = -1;
    my $max_pool_size = -1;
    my $idle_timeout = -1;
    my $cur_conn_count = -1;
    my $cur_avail_conn_count = -1;
    my $max_conn_count = -1;
    my $create_count = -1;
    my $close_count = -1; 

    $init_pool_size = $1 if $webcontent =~ /InitialPoolSize=(\d+)\s/i;
    $max_pool_size = $1 if $webcontent =~ /MaxPoolSize=(\d+)\s/i;
    $idle_timeout = $1 if $webcontent =~ /IdleTimeout=(\d+)\s/i;
    $cur_conn_count = $1 if $webcontent =~ /CurrentConnectionCount=(\d+)\s/i;
    $cur_avail_conn_count = $1 if $webcontent =~ /CurrentAvailableConnectionCount=(\d+)\s/i;
    $max_conn_count = $1 if $webcontent =~ /MaxConnectionCount=(\d+)\s/i;
    $create_count = $1 if $webcontent =~ /CreateCount=(\d+)\s/i;
    $close_count = $1 if $webcontent =~ /CloseCount=(\d+)\s/i;

    my $active_conn_count = $cur_conn_count - $cur_avail_conn_count;

    $self->{output}->output_add(severity => "ok", short_msg => sprintf("InitialPoolSize: %d", $init_pool_size));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("MaxPoolSize: %d", $max_pool_size));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("IdleTimeout: %d", $idle_timeout));
    
    my $exit = $self->{perfdata}->threshold_check(value => $active_conn_count, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit, short_msg => sprintf("ActiveConnectionCount: %d", $active_conn_count));

    $self->{output}->output_add(severity => "ok", short_msg => sprintf("CurrentConnectionCount: %d", $cur_conn_count));
    #$self->{output}->output_add(severity => "ok", short_msg => sprintf("CurrentAvailableConnectionCount: %d", $cur_avail_conn_count));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("MaxConnectionCount: %d", $max_conn_count));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("CreateCount: %d", $create_count));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("CloseCount: %d", $close_count));

    $self->{output}->perfdata_add(label => "InitPoolSize", unit => '',
                                  value => sprintf("%d", $init_pool_size),
                                  );
    $self->{output}->perfdata_add(label => "MaxPoolSize", unit => '',
                                  value => sprintf("%d", $max_pool_size),
                                  );
    $self->{output}->perfdata_add(label => "IdleTimeout", unit => '',
                                  value => sprintf("%d", $idle_timeout),
                                  );

    $self->{output}->perfdata_add(label => "ActiveConnectionCount", unit => '',
                                  value => sprintf("%d", $active_conn_count),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  );
    $self->{output}->perfdata_add(label => "CurrentConnectionCount", unit => '',
                                  value => sprintf("%d", $cur_conn_count),
                                  );
    #$self->{output}->perfdata_add(label => "CurrentAvailableConnectionCount", unit => '',
    #                              value => sprintf("%d", $cur_avail_conn_count),
    #                              );
    $self->{output}->perfdata_add(label => "MaxConnectionCount", unit => '',
                                  value => sprintf("%d", $max_conn_count),
                                  );
    $self->{output}->perfdata_add(label => "c[CreateCount]", unit => '',
                                  value => sprintf("%d", $create_count),
                                  );
    $self->{output}->perfdata_add(label => "c[CloseCount]", unit => '',
                                  value => sprintf("%d", $close_count),
                                  );

    $self->{output}->display();
    $self->{output}->exit();
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

=item B<--warning>

Warning Threshold for active connection count.

=item B<--critical>

Critical Threshold for active connection count.

=back

=cut
