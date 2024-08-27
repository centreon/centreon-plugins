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

package os::windows::wsman::mode::filessize;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'warning-one:s'     => { name => 'warning_one' },
        'critical-one:s'    => { name => 'critical_one' },
        'warning-total:s'   => { name => 'warning_total' },
        'critical-total:s'  => { name => 'critical_total' },
        'all-files'         => { name => 'all_files' },
        'filter-filename:s' => { name => 'filter_filename' },
        'folder:s'          => { name => 'folder' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning_one', value => $self->{option_results}->{warning_one})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-one threshold '" . $self->{warning_one} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical_one', value => $self->{option_results}->{critical_one})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-one threshold '" . $self->{critical_one} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning_total', value => $self->{option_results}->{warning_total})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-total threshold '" . $self->{warning_total} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical_total', value => $self->{option_results}->{critical_total})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-total threshold '" . $self->{critical_total} . "'.");
       $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{folder}) || $self->{option_results}->{folder} eq '') {
       $self->{output}->add_option_msg(short_msg => "Need to specify folder option.");
       $self->{output}->option_exit();
    }

    #### Create file path
    $self->{option_results}->{folder} =~ s/\//\\\\/g;
}

sub run {
    my ($self, %options) = @_;

    my ($total_size, $exit_code) = (0);

    $self->{option_results}->{folder} =~ /^(..)(.*)$/;
    my ($drive, $path) = ($1, $2);
    my $WQL = 'Select name,filesize from CIM_DataFile where drive = "' . $drive . '" AND path = "' . $path . '"';

    my $results = $options{wsman}->request(
        uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/*',
        wql_filter => $WQL,
        result_type => 'array'
    );
    #
    #CLASS: CIM_DataFile
    #FileSize|Name
    #1092|C:\Users\Administrator\.bash_history
    #52|C:\Users\Administrator\.gitconfig
    #37|C:\Users\Administrator\.lesshst
    #1038|C:\Users\Administrator\.viminfo
    #20|C:\Users\Administrator\ntuser.ini
    #
    
    $self->{output}->output_add(
        severity => 'OK', 
        short_msg => "All file sizes are ok."
    );
    if (!defined($results) || scalar(@$results) <= 0) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'No file found.'
        );
    }

    foreach (@$results) {
        my $size = $_->{FileSize};
        my $name = centreon::plugins::misc::trim($_->{Name});
        
        next if (defined($self->{option_results}->{filter_filename}) && $self->{option_results}->{filter_filename} ne '' &&
            $name !~ /$self->{option_results}->{filter_filename}/);

        $total_size += $size;
        my $exit_code = $self->{perfdata}->threshold_check(
            value => $size, 
            threshold => [ { label => 'critical_one', exit_litteral => 'critical' }, { label => 'warning_one', exit_litteral => 'warning' } ]
        );
        my ($size_value, $size_unit) = $self->{perfdata}->change_bytes(value => $size);
        $self->{output}->output_add(long_msg => sprintf("%s: %s", $name, $size_value . ' ' . $size_unit));
        if (!$self->{output}->is_status(litteral => 1, value => $exit_code, compare => 'ok')) {
            $self->{output}->output_add(
                severity => $exit_code,
                short_msg => sprintf("'%s' size is %s", $name, $size_value . ' ' . $size_unit)
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'file.size.bytes',
            unit => 'B',
            instances => $name,
            value => $size,
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_one'),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_one'),
            min => 0
        );
    }
 
    # Total Size
    $exit_code = $self->{perfdata}->threshold_check(
        value => $total_size, 
        threshold => [ { label => 'critical_total', exit_litteral => 'critical' }, { label => 'warning_total', exit_litteral => 'warning' } ]
    );
    my ($size_value, $size_unit) = $self->{perfdata}->change_bytes(value => $total_size);
    $self->{output}->output_add(long_msg => sprintf("Total: %s", $size_value . ' ' . $size_unit));
    if (!$self->{output}->is_status(litteral => 1, value => $exit_code, compare => 'ok')) {
        $self->{output}->output_add(
            severity => $exit_code,
            short_msg => sprintf('Total size is %s', $size_value . ' ' . $size_unit)
        );
    }
    $self->{output}->perfdata_add(
        nlabel => 'files.size.bytes',
        unit => 'B',
        value => $total_size,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_total'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_total'),
        min => 0
    );
      
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check size of files/directories.

=over 8

=item B<--folder>

Folder to check (no WQL wildcard allowed).
Example: 'C:/Users/Administrator/'.

=item B<--filter-filename>

Filter files by name.

=item B<--warning-one>

Warning threshold in bytes for each files/directories.

=item B<--critical-one>

Critical threshold in bytes for each files/directories.

=item B<--warning-total>

Warning threshold in bytes for all files/directories.

=item B<--critical-total>

Critical threshold in bytes for all files/directories.

=back

=cut
