package apps::proxmox::mg::restapi::custom::api;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments =>  {
            'hostname:s'          => { name => 'hostname' },
            'port:s'              => { name => 'port'},
            'proto:s'             => { name => 'proto' },
            'api-username:s'      => { name => 'api_username' },
            'api-password:s'      => { name => 'api_password' },
            'realm:s'             => { name => 'realm' },
            'timeout:s'           => { name => 'timeout' },
            'reload-cache-time:s' => { name => 'reload_cache_time', default => 7200 }
        });
    }

    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 8006;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{realm} = (defined($self->{option_results}->{realm})) ? $self->{option_results}->{realm} : 'pmg';

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }
    if ($self->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-username option.");
        $self->{output}->option_exit();
    }
    if ($self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-password option.");
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}


sub get_port {
    my ($self, %options) = @_;

    return $self->{option_results}->{port};
}

sub get_hostnames {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
    $self->{option_results}->{unknown_status} = '%{http_code} < 200 or %{http_code} >= 300';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/x-www-form-urlencoded');
    if (defined($self->{ticket})) {
        $self->{http}->add_header(key => 'Cookie', value => 'PMGAuthCookie=' . $self->{ticket});
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_ticket {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'proxmox_mg_api_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{option_results}->{api_username}));
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $ticket = $options{statefile}->get(name => 'ticket');

    if ($has_cache_file == 0 || !defined($ticket) || (($expires_on - time()) < 10)) {
        my $post_data = 'username=' . $self->{api_username} .
            '&password=' . $self->{api_password} .
            '&realm=' . $self->{realm};

        $self->settings();

        my $content = $self->{http}->request(
            method => 'POST', query_form_post => $post_data,
            url_path => '/api2/json/access/ticket'
        );

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->output_add(long_msg => $content, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
            $self->{output}->option_exit();
        }
        if (!defined($decoded->{data}->{ticket})) {
            $self->{output}->output_add(long_msg => $content, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Error retrieving ticket");
            $self->{output}->option_exit();
        }

        $ticket = $decoded->{data}->{ticket};
        my $datas = { last_timestamp => time(), ticket => $ticket, expires_on => time() + 7200 };
        $options{statefile}->write(data => $datas);
    }

    return $ticket;
}

sub request_api {
    my ($self, %options) = @_;

    if (!defined($self->{ticket})) {
        $self->{ticket} = $self->get_ticket(statefile => $self->{cache});
    }

    $self->settings();

    my $content = $self->{http}->request(%options);

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }
    if (!defined($decoded->{data})) {
        $self->{output}->add_option_msg(short_msg => "Error while retrieving data (add --debug option for detailed message)");
        $self->{output}->option_exit();
    }

    return $decoded->{data};
}

sub get_version {
    my ($self, %options) = @_;

    my $content = $self->request_api(method => 'GET', url_path =>'/api2/json/version');
    return $content->{version};
}

sub internal_api_recent {
  my ($self, %options) = @_;

  my $recent = $self->request_api(method => 'GET', url_path =>'/api2/json/statistics/recent?timespan=120&hours=1');
  return $recent;
}

sub api_recent_count {
  my ($self, %options) = @_;

  my $counts = {};
  my $list_count = $self->internal_api_recent();
  foreach my $count (@{$list_count}) {
      $counts->{$count->{index}} = {
        Count_in => $count->{count_in},
        Count_out => $count->{count_out},
   };
  }
  return $counts;
}

sub api_recent_spam {
  my ($self, %options) = @_;

  my $spams = {};
  my $list_spam = $self->internal_api_recent();
  foreach my $spam (@{$list_spam}) {
      $spams->{$spam->{index}} = {
        Spam_in => $spam->{spam_in},
        Spam_out => $spam->{spam_out},
   };
  }
  return $spams;
}

sub api_recent_virus {
  my ($self, %options) = @_;

  my $virus = {};
  my $list_virus = $self->internal_api_recent();
  foreach my $viru (@{$list_virus}) {
      $virus->{$viru->{index}} = {
        Virus_in => $viru->{virus_in},
        Virus_out => $viru->{virus_out},
   };
  }
  return $virus;
}

1;

__END__

=head1 NAME

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

=item B<--port>

=item B<--proto>

=item B<--api-username>

=item B<--api-password>

=item B<--realm>

=item B<--timeout>

=back

=cut
