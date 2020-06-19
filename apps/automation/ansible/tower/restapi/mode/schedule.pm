#...
# Authors: Guillaume Carpentier <guillaume.carpentier@externes.justice.gouv.fr>

package apps::automation::ansible::tower::restapi::mode::schedule;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Date::Parse;
use Date::Manip;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    $self->{object_type} = 'schedule';

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            "schedule:s" => { name => 'schedule'},
            "freshness:s" => { name => 'freshness', default => 2 },
        });
    }

    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);
    $self->{mode} = $options{mode};

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    if (!defined($self->{option_results}->{schedule}) || $self->{option_results}->{schedule} !~ /^[0-9]+$/ ) {
        $self->{output}->add_option_msg(short_msg => "Need to specify schedule id (numeric value) option.");
        $self->{output}->option_exit();
    }
    if ($self->{option_results}->{freshness} !~ /^[0-9]+$/ || $self->{option_results}->{freshness} == 0) {
        $self->{output}->add_option_msg(short_msg => "Need to specify freshness (>0) option.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    my %status;
    my $path = '/api/v2/schedules/' . $self->{option_results}->{schedule};
    my $result = $options{custom}->request_api(
                    url_path => $path,
                    method => 'GET',
                    status_code => 200);
    my $schedule_name = $result->{name};
    my @short_messages;

    if (! $result->{enabled}) {
        $options{custom}->escalate_status(status => 'CRITICAL');
        $options{custom}->plugin_exit(short_message => $schedule_name . ' is disabled.');
    }

    # Get all jobs starting with the latest for the schedule. If we checked first the job-template/ or jobs/
    # we could have some jobs launched manually
    $path = '/api/v2/schedules/' . $self->{option_results}->{schedule} . '/jobs/?order_by=-id&page_size=1';
    my $last_jobs = $options{custom}->request_api(
                        url_path => $path,
                        method => 'GET');
    if (scalar $last_jobs->{results} == 0) {
        $options{custom}->escalate_status(status => 'CRITICAL');
        $options{custom}->plugin_exit(short_message => 'No job found for ' . $schedule_name);
    }

    my $last_job = $last_jobs->{results}[0];
    my $last_job_uri;
    # Get finished date and compute freshness for ie : 2020-06-11T09:20:41.809341Z
    # Remove microseconds - not parsed with Time::Piece
    if (defined($last_job->{finished})) {
        my $finished = ParseDate($last_job->{finished});
        my $now = localtime;
        my $err;
        my $diff = DateCalc($finished, $now, \$err);
        if (Delta_Format($diff, 0, '%st')/3600 > $self->{option_results}->{freshness} ) {
            $options{custom}->escalate_status(status => 'CRITICAL');
            push @short_messages, 'Last job is too old, finished : ' . UnixDate($finished,  '%d/%m/%Y %H:%M');
        }
        $last_job_uri = $self->{option_results}->{proto} . '://' . $self->{option_results}->{hostname} . $last_job->{url};
    }
    
    # Get exit code from status
    $options{custom}->escalate_status(status => $options{custom}->get_job_status_severity(status => $last_job->{status}));
    push @short_messages, 'Job \'' . $last_job->{name} . '\' was ' . $last_job->{status};

    # Handle the OK state when no hosts matched.
    if ($options{custom}->get_status() =~ /^OK$/ ) {
        $path = '/api/v2/jobs/' . $last_job->{id} . '/job_host_summaries/';
        my $summary_event = $options{custom}->request_api(
                        url_path => $path,
                        method => 'GET',
                        status_code => 200);

        # No hosts matched. Only when result is false-positive
        if ($summary_event->{count} == 0) {
            $options{custom}->escalate_status(status => 'CRITICAL');
            push @short_messages, 'But no hosts matched !'
        }
    }

    # Add url detail at the end
    push @short_messages, '(' . $last_job_uri . ')' if ($last_job_uri !~ /^$/);
    $options{custom}->plugin_exit(short_message => join('. ', @short_messages));
}

1;

__END__

=head1 MODE

Check last job from given scheduled job template.

=over 8

=item B<--schedule>

Id of scheduled job-template

=item B<--freshness>

Max age of the latest job (in hours)
Default: 2

=back

=cut