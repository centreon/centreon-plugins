#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package database::mysql::mode::openfiles;

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
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

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
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
    
    if (!($self->{sql}->is_version_minimum(version => '5'))) {
        $self->{output}->add_option_msg(short_msg => "MySQL version '" . $self->{sql}->{version} . "' is not supported (need version >= '5.x').");
        $self->{output}->option_exit();
    }
    
    $self->{sql}->query(query => q{SHOW VARIABLES LIKE 'open_files_limit'});
    my ($dummy, $open_files_limit) = $self->{sql}->fetchrow_array();
    if (!defined($open_files_limit)) {
        $self->{output}->add_option_msg(short_msg => "Cannot get open files limit.");
        $self->{output}->option_exit();
    }
    $self->{sql}->query(query => q{SHOW /*!50000 global */ STATUS LIKE 'Open_files'});
    ($dummy, my $open_files) = $self->{sql}->fetchrow_array();
    if (!defined($open_files)) {
        $self->{output}->add_option_msg(short_msg => "Cannot get open files.");
        $self->{output}->option_exit();
    }

    my $prct_open = int(100 * $open_files / $open_files_limit);
    my $exit_code = $self->{perfdata}->threshold_check(value => $prct_open, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    
    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("%.2f%% of the open files limit reached (%d of max. %d)",
                                $prct_open, $open_files, $open_files_limit));
    $self->{output}->perfdata_add(label => 'open_files',
                                  value => $open_files,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $open_files_limit, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $open_files_limit, cast_int => 1),
                                  min => 0);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check number of open files.

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
