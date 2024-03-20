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

package centreon::common::monitoring::logs::custom::cifs;

use base qw(centreon::common::protocols::cifs::custom::libcifs);

use strict;
use warnings;
use centreon::plugins::misc;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, nohelp => 1);
    bless $self, $class;

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'file:s' => { name => 'file' }
        });
    }

    $options{options}->add_help(package => __PACKAGE__, sections => 'CIFS OPTIONS', once => 1);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub get_uuid {
    my ($self, %options) = @_;

    return md5_hex(
        ((defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') ? $self->{option_results}->{hostname} : 'none') . '_' .
        ((defined($self->{option_results}->{file}) && $self->{option_results}->{file} ne '') ? $self->{option_results}->{file} : 'none')
    );
}

sub read {
    my ($self, %options) = @_;

    my ($rv, $message, $data) =  $self->read_file(file => $self->{option_results}->{file});
    return $data;
}

1;

__END__

=head1 NAME

Logs CIFS

=head1 SYNOPSIS

Logs CIFS custom mode

=head1 CIFS OPTIONS

=over 8

=item B<--file>

Path to the file to read logs from.

=back

=head1 DESCRIPTION

B<custom>.

=cut
