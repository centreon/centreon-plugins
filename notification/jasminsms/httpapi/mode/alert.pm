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

package notification::jasminsms::httpapi::mode::alert;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Encode;

my $map_dlr_level = {
    'sms-c' => 1, terminal => 2, both => 3
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'from:s'       => { name => 'from'},
        'to:s'         => { name => 'to' },
        'message:s'    => { name => 'message' },
        'coding:s'     => { name => 'coding', default => 8 },
        'dlr-url:s'    => { name => 'dlr_url' },
        'dlr-level:s'  => { name => 'dlr_level' },
        'dlr-method:s' => { name => 'dlr_method' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::init(%options);
    if (!defined($self->{option_results}->{to}) || $self->{option_results}->{to} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Please set --to option');
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{coding}) || $self->{option_results}->{coding} eq '') {
        $self->{option_results}->{coding} = 8;
    }
    $self->{option_results}->{coding} = $1 if ($self->{option_results}->{coding} =~ /(\d+)/);
    if ($self->{option_results}->{coding} < -1 || $self->{option_results}->{coding} > 14) {
        $self->{output}->add_option_msg(short_msg => "Please set correct --coding option [-1,14]");
        $self->{output}->option_exit(); 
    }

    if (!defined($self->{option_results}->{message})) {
        $self->{output}->add_option_msg(short_msg => 'Please set --message option');
        $self->{output}->option_exit();
    }

    $self->{dlr_enabled} = 'no';
    my $dlr_options = { dlr_url => 1, dlr_level => 1, dlr_method => 1 };
    foreach (('dlr_url', 'dlr_level', 'dlr_method')) {
        if (defined($self->{option_results}->{$_}) && $self->{option_results}->{$_} ne '') {
            if (/level/ && !defined($map_dlr_level->{ $self->{option_results}->{$_} })) {
                $self->{output}->add_option_msg(short_msg => 'Wrong --dlr-level option');
                $self->{output}->option_exit();
            } elsif (/method/ && $self->{option_results}->{$_} !~ /^GET|POST$/) {
                $self->{output}->add_option_msg(short_msg => 'Wrong --dlr-method option');
                $self->{output}->option_exit();
            }
            $self->{dlr_enabled} = 'yes';
            delete $dlr_options->{$_};
        }
    }
    if (scalar(keys %$dlr_options) =~ /1|2/) {
        $self->{output}->add_option_msg(short_msg => 'Please set ' . join(' ', (map { s/_/-/g; $_ } keys(%$dlr_options))) . ' option(s)');
        $self->{output}->option_exit();
    }
}

my $map_coding = {
    3 => 'ISO-8859-1',
    6 => 'ISO-8859-5',
    7 => 'ISO-8859-8',
    8 => 'UCS-2BE'
};

sub encoding_message {
    my ($self, %options) = @_;

    if ($self->{option_results}->{coding} != -1) {
        $self->{option_results}->{message} = $self->{output}->decode($self->{option_results}->{message});
        if (defined($map_coding->{ $self->{option_results}->{coding} })) {
            $self->{option_results}->{message} = Encode::encode(
                $map_coding->{ $self->{option_results}->{coding} },
                $self->{option_results}->{message}
            );
        }
    }

    $self->{option_results}->{message} = unpack('H*', $self->{option_results}->{message});
}

sub run {
    my ($self, %options) = @_;

    $self->encoding_message();
    my $response = $options{custom}->send_sms(
        to => $self->{option_results}->{to},
        from => $self->{option_results}->{from},
        message => $self->{option_results}->{message},
        coding => $self->{option_results}->{coding},
        dlr => $self->{dlr_enabled},
        dlr_url => $self->{option_results}->{dlr_url},
        dlr_level => $self->{dlr_enabled} eq 'yes' ? $map_dlr_level->{ $self->{option_results}->{dlr_level} } : undef,
        dlr_method => $self->{option_results}->{dlr_method}
    );

    if ($response =~ /Error/) {
        $self->{output}->add_option_msg(short_msg => $response);
        $self->{output}->option_exit();
    }

    $self->{output}->output_add(short_msg => $response);
    $self->{output}->display(force_ignore_perfdata => 1);
    $self->{output}->exit();
}


1;

__END__

=head1 MODE

Send SMS with Jasmin SMS HTTP API (https://docs.jasminsms.com/en/latest/apis/ja-http/index.html)

=over 8

=item B<--from>

Specify sender linked to account.

=item B<--to>

Specify receiver phone number (format 00336xxxx for French Number).

=item B<--message>

Specify the message to send.

=item B<--coding>

Sets the Data Coding Scheme bits (Default: 8 (UCS2)).
Set value to -1 for disable encoding management.

=item B<--dlr-url>

Sets DLR-URL.

=item B<--dlr-level>

Sets DLR level (can be: 'sms-c', 'terminal', 'both').

=item B<--dlr-method>

Sets DLR method (can be: 'GET', 'POST').

=back

=cut
