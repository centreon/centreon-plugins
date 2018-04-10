#
# Copyright 2018 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure      application monitoring for
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
# See the License for the specific language governing permissions     
# limitations under the License.
#
# Author : CHEN JUN , aladdin.china@gmail.com

package apps::kingdee::eas::mode::oracletable;

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
            "urlpath:s"         => { name => 'url_path', default => "/easportal/tools/nagios/checkoracletable.jsp" },
            "datasource:s"      => { name => 'datasource' },
            "tablename:s"       => { name => 'tablename' , default => "T_GL_VOUCHER"},
            "actualrows:s"      => { name => 'actualrows', default => "false" },
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
    $self->{option_results}->{url_path} .= "?ds=" . $self->{option_results}->{datasource} 
                                        . "\&tablename=" . $self->{option_results}->{tablename}
                                        . "\&actual=" . $self->{option_results}->{actualrows};

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
	if ($webcontent !~ /^TABLE_NAME=\w+/i) {
		$self->{output}->output_add(
			severity  => 'UNKNOWN',
			short_msg => "Cannot find oracle table status. \n" . $webcontent
		);
		$self->{output}->option_exit();
	}
		
    my ($num_rows, $actual_num_rows) = (-1, -1);
    $num_rows = $1 if $webcontent =~ /NUM_ROWS=(\d+)/i;
    $actual_num_rows = $1 if $webcontent =~ /ACTUAL_NUM_ROWS=(\d+)/i;

    my $exit;
    if ($actual_num_rows == -1) {
        $exit = $self->{perfdata}->threshold_check(value => $num_rows, threshold => [ 
                                                  { label => 'critical', 'exit_litteral' => 'critical' }, 
                                                  { label => 'warning', exit_litteral => 'warning' } ]
                                                  );
        $self->{output}->output_add(severity => $exit, short_msg => sprintf("NUM_ROWS: %d", $num_rows));

        $self->{output}->perfdata_add(label => "NUM_ROWS", unit => '',
                                  value => sprintf("%d", $num_rows),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  );
    } else {
        $self->{output}->perfdata_add(label => "NUM_ROWS", unit => '', value => sprintf("%d", $num_rows));
        $exit = $self->{perfdata}->threshold_check(value => $actual_num_rows, threshold => [ 
                                                  { label => 'critical', 'exit_litteral' => 'critical' }, 
                                                  { label => 'warning', exit_litteral => 'warning' } ]
                                                  );
        $self->{output}->output_add(severity => $exit, short_msg => sprintf("ACTUAL_NUM_ROWS: %d", $actual_num_rows));
 
        $self->{output}->perfdata_add(label => "ACTUAL_NUM_ROWS", unit => '',
                                  value => sprintf("%d", $actual_num_rows),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  );
    }
    $self->{output}->output_add(severity => $exit, short_msg => $webcontent);
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check oracle table info for specify datasource.

=over 8

=item B<--urlpath>

Set path to get status page. (Default: '/easportal/tools/nagios/checkoracletable.jsp')

=item B<--datasource>

Specify the datasource name.

=item B<--tablename>

Specify the table name , MUST BE uppercase.

=item B<--actualrows>

Specify whether check actual rows of table or not , true or false. 
MAY have performance problem for large table if specify true. 

=item B<--warning>

Warning Threshold for num_rows , or actual_num_rows if actualrows is true.

=item B<--critical>

Critical Threshold for num_rows , or actual_num_rows if actualrows is true.

=back

=cut
