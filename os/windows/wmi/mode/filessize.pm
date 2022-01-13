#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package os::windows::wmi::mode::filessize;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'warning:s'       => { name => 'warning' },
        'critical:s'      => { name => 'critical' },
        'filter-plugin:s' => { name => 'filter_plugin' },
        'file:s'          => { name => 'file' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{critical} . "'.");
       $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{file}) || $self->{option_results}->{file} eq '') {
       $self->{output}->add_option_msg(short_msg => "Need to specify files option.");
       $self->{output}->option_exit();
    }

    $self->{option_results}->{file} =~ s/\//\\\\/g;
}

sub run {
    my ($self, %options) = @_;

    my $WQL = 'Select name,filesize from CIM_DataFile where name = "' . $self->{option_results}->{file} . '"';

    my ($result, $exit_code) = $options{custom}->execute_command(
        query => $WQL,
        no_quit => 1
    );
    $result =~ s/\|/;/g;

    #
    #CLASS: CIM_DataFile
    #FileSize;Name
    #786432;C:\\Users\\Administrator\\NTUSER.DAT
    #

    if(!defined($result) || $result eq '') {
        $self->{output}->output_add(
        severity => 'UNKNOWN',
        short_msg => 'No file found.'
        );
    }

    while ($result =~ /^(\d+);(.*?)$/msg) {
        my ($size, $name) = ($1, centreon::plugins::misc::trim($2));
        
        next if (defined($self->{option_results}->{filter_plugin}) && $self->{option_results}->{filter_plugin} ne '' &&
                 $name !~ /$self->{option_results}->{filter_plugin}/);
        
        my $exit_code = $self->{perfdata}->threshold_check(
            value => $size, 
            threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]
        );
        my ($size_value, $size_unit) = $self->{perfdata}->change_bytes(value => $size);
        $self->{output}->output_add(long_msg => sprintf("%s: %s", $name, $size_value . ' ' . $size_unit));
            $self->{output}->output_add(
                severity => $exit_code,
                short_msg => sprintf("File '%s' size is %s", $name, $size_value . ' ' . $size_unit)
            );
        $self->{output}->perfdata_add(
            label => $name, unit => 'B',
            value => $size,
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
            min => 0
        );
    }
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check size of file.

=over 8

=item B<--file>

File to check. (No WQL wildcard allowed).

=item B<--warning>

Threshold warning in bytes for file.

=item B<--critical>

Threshold critical in bytes for file.

=item B<--filter-plugin>

Filter file in the plugin.
Perl Regexp can be used.

=back

=cut
