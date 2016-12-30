#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package cloud::ovh::mode::quota;

use base qw(centreon::plugins::mode);
use lib 'cloud/ovh';
use OvhApi;
use Data::Dumper;
use JSON qw( decode_json );
use strict;
use warnings;


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"               => { name => 'warning', default => '80'},
                                  "critical:s"              => { name => 'critical', default => '90'},
                                  "service:s"               => { name => 'service', },
                                  "applicationKey:s"        => { name => 'applicationKey', },
                                  "applicationSecret:s"     => { name => 'applicationSecret', },
                                  "consumerKey:s"           => { name => 'consumerKey', },
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

    my $service = $self->{option_results}->{service};
    my $applicationKey = $self->{option_results}->{applicationKey};
    my $applicationSecret = $self->{option_results}->{applicationSecret};
    my $consumerKey = $self->{option_results}->{consumerKey};
    my $Api = OvhApi->new(type => OvhApi::OVH_API_EU,
	applicationKey => $applicationKey,
	applicationSecret => $applicationSecret,
	consumerKey => $consumerKey);
    my $Answer = $Api->get(path => '/hosting/web/'.$service);


    if (!$Answer) {
        $self->{output}->output_add(severity => 'unknown',
                                    short_msg => sprintf("No response"));
        $self->{output}->display();
        $self->{output}->exit();
    }

    my $content = $Answer->{response}->{_content};
    my $decoded = decode_json($content);

    my $used = $decoded->{'quotaUsed'}->{'value'};
    my $usedUnit = $decoded->{'quotaUsed'}->{'unit'};

    #convert unit
    if($usedUnit eq "GB") {
       $usedUnit = "MB";
       $used = $used * 1024;
    }

    my $size = $decoded->{'quotaSize'}->{'value'};
    my $sizeUnit = $decoded->{'quotaSize'}->{'unit'};

    #convert unit
    if($sizeUnit eq "GB") {
       $sizeUnit = "MB";
       $size = $size * 1024;
    }

    my $usedPercent = sprintf("%d", $used*100/$size);

    my $exit = $self->{perfdata}->threshold_check(value => $usedPercent,
                                                  threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);


    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Used %d %s (Used: %0.2f %s , Size %0.2f %s)", $usedPercent, "%" , $used, $usedUnit, $size, $sizeUnit));

    $self->{output}->perfdata_add(label => "Used", unit => "%",
                                  value => $usedPercent,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', used => $self->{option_results}->{warning}, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', used => $self->{option_results}->{critical}, cast_int => 1),
                                  min => 0);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check web hosting space

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--service>

OVH service name

=item B<--applicationKey>

OVH API applicationKey

=item B<--applicationSecret>

OVH API applicationSecret

=item B<--consumerKey>

OVH API consumerKey

=back

=cut