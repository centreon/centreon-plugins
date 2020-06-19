#...
# Authors: Guillaume Carpentier <guillaume.carpentier@externes.justice.gouv.fr>

package apps::automation::ansible::tower::restapi::mode::jobs;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    $self->{object_type} = 'job';

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            "job:s" => { name => 'job'},
        });
    }

    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);
    $self->{mode} = $options{mode};

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    if (!defined($self->{option_results}->{job}) || $self->{option_results}->{job} !~ /^[0-9]+$/ ) {
        $self->{output}->add_option_msg(short_msg => "Need to specify job id (numeric value) option.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    my %status;
    my @short_messages;
    my $path = '/api/v2/jobs/' . $self->{option_results}->{job};
    my $result = $options{custom}->request_api(
                    url_path => $path,
                    method => 'GET',
                    status_code => 200);
    my $job_name = $result->{name};

    # An other approach to find play logs with no match
    #$path = '/api/v2/jobs/' . $self->{option_results}->{job} . '/job_events/';
    #my $event = $options{custom}->request_api(
    #                 url_path => $path,
    #                 method => 'GET',
    #                 status_code => 200);
    # Contains events hash or 0 if none found.
    #my @filtered_events = grep { $_->{event} =~ /^playbook_on_no_hosts_matched$/ } @{$event->{results}};

    # Compute exit code
    $options{custom}->escalate_status(status => $options{custom}->get_job_status_severity(status => $result->{status}));
    push @short_messages, 'Job \'' . $job_name . '\' was ' . $result->{status};

    # Handle the OK state when no hosts matched.
    if ($options{custom}->get_status() =~ /^OK$/ ) {
        # Simpler job_host_summaries contains the hosts that ran the play.
        $path = '/api/v2/jobs/' . $self->{option_results}->{job} . '/job_host_summaries/';
        my $summary_event = $options{custom}->request_api(
                        url_path => $path,
                        method => 'GET',
                        status_code => 200);

        # No hosts match is relevant only when result is false-positive
        if ($summary_event->{count} == 0) {
            $options{custom}->escalate_status(status => 'CRITICAL');
            push @short_messages, 'But no hosts matched !'
        }
    }
    # Add job uri detail
    push @short_messages, '(' . $self->{option_results}->{proto} . '://' . $self->{option_results}->{hostname} . $result->{url} . ')';

    $options{custom}->plugin_exit(short_message => join('. ', @short_messages));
}

1;

__END__

=head1 MODE

Lauch a Job template and check its result.

=over 8

=item B<--job-template>

Id of the job template.

=back

=cut