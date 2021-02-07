#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package apps::kingdee::eas::mode::oracleversion;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'urlpath:s'    => { name => 'url_path', default => "/easportal/tools/nagios/checkoracleversion.jsp" },
        'datasource:s' => { name => 'datasource' },
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
}

sub run {
    my ($self, %options) = @_;

    my $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path});
	if ($webcontent !~ /^BANNER=/i) {
		$self->{output}->add_option_msg(short_msg => 'Cannot find oracle version info.');
		$self->{output}->option_exit();
	}

    my $banner = '';
    $banner = $1 if ($webcontent =~ /^BANNER=\'(.*?)\'/i);

    $self->{output}->output_add(severity => "ok", short_msg => $banner);
    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check oracle database version.

=over 8

=item B<--urlpath>

Set path to get status page. (Default: '/easportal/tools/nagios/checkoracleversion.jsp')

=item B<--datasource>

Specify the datasource name.

=back

=cut
