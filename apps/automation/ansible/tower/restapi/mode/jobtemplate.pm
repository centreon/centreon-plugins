#...
# Authors: Guillaume Carpentier <guillaume.carpentier@externes.justice.gouv.fr>

package apps::automation::ansible::tower::restapi::mode::jobtemplate;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    $self->{object_type} = 'job-template';

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            "job-template:s" => { name => 'job_template'},
            "extra-vars:s" => { name => 'extra_vars', default => undef},
            "job-tags:s" => { name => 'job_tags'},
            "limit:s" => { name => 'limit'},
            "inventory:s" => { name => 'inventory'},
            "credential:s" => { name => 'credential'},
            "max-retries:s" => { name => 'max_retries', default => 20},
            "retry-interval:s" => { name => 'retry_interval', default => 10},
        });
    }            
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);
    $self->{mode} = $options{mode};

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    if (!defined($self->{option_results}->{job_template}) || $self->{option_results}->{job_template} !~ /^[0-9]+$/ ) {
        $self->{output}->add_option_msg(short_msg => "Need to specify job_template id (numeric value) option.");
        $self->{output}->option_exit();
    }
    if ($self->{option_results}->{retry_interval} !~ /^[0-9]+$/ &&
        int($self->{option_results}->{retry_interval}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Need to specify retry_interval (numeric value > 0) option.");
        $self->{output}->option_exit();
    }
    if ($self->{option_results}->{max_retries} !~ /^[0-9]+$/ &&
        int($self->{option_results}->{max_retries}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Need to specify max_retries (numeric value > 0) option.");
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{extra_vars}) &&
        $self->{option_results}->{extra_vars} !~ /^[\w_\.]+=[\w_\.]+(?:,[\w_\.]+=[\w_\.]+)*$/) {
        $self->{output}->add_option_msg(short_msg => "Extra vars should be written like this 'k1=v1,k2=v2...'");
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{credential}) &&
        $self->{option_results}->{credential} !~ /^[0-9]+$/) {
        $self->{output}->add_option_msg(short_msg => "Option 'credential' must be an integer");
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{inventory}) &&
        $self->{option_results}->{inventory} !~ /^[0-9]+$/) {
        $self->{output}->add_option_msg(short_msg => "Option 'inventory' must be an integer");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    my %status;
    my $path = '/api/v2/job_templates/' . $self->{option_results}->{job_template} . '/launch/';

    my $json_request = {};

    # https://docs.ansible.com/ansible-tower/3.2.6/html/towerapi/launch_jobtemplate.html
    $json_request->{inventory} = ($self->{option_results}->{inventory} + 0) if defined($self->{option_results}->{inventory});
    $json_request->{credential} = ($self->{option_results}->{credential} + 0) if defined($self->{option_results}->{credential});
    $json_request->{limit} = $self->{option_results}->{limit} if defined($self->{option_results}->{limit});
    $json_request->{job_tags} = $self->{option_results}->{job_tags} if defined($self->{option_results}->{job_tags});
    $json_request->{extra_vars} = $options{custom}->str_to_hash(str => $self->{option_results}->{extra_vars});

    my @short_messages;
    my $encoded = {};
    eval {
        $encoded = encode_json($json_request);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot encode json request");
        $self->{output}->option_exit();
    }

    my $result = $options{custom}->request_api(
                                    method => 'POST',
                                    url_path => $path,
                                    query_form_post => $encoded,
                                    status_code => 201);
    my $job_template_name = $result->{name};

    my ($job_completed, $retry_idx, $job_result);
    $retry_idx = 0;
    while ( !defined($job_completed) &&
            $retry_idx < $self->{option_results}->{max_retries}) {
        sleep ($self->{option_results}->{retry_interval}) if ($retry_idx > 0);
        $job_result = $options{custom}->request_api(
                        url_path => $result->{url});
        # Will be defined when finished
        $job_completed = $job_result->{finished};
        $retry_idx++;
    }

    $options{custom}->escalate_status(status => $options{custom}->get_job_status_severity(status => $job_result->{status}));
    push @short_messages, 'Job \'' . $job_template_name . '\' was ' . $job_result->{status};

    # Handle the OK state when no hosts matched.
    if ($options{custom}->get_status() =~ /^OK$/ ) {
        # Get job_host_summaries containing the hosts that ran the play.
        my $summary_event = $options{custom}->request_api(
                        url_path => $result->{url} . 'job_host_summaries/',
                        method => 'GET',
                        status_code => 200);

        # 'No hosts match' is kind of false-positive
        if ($summary_event->{count} == 0) {
            $options{custom}->escalate_status(status => 'CRITICAL');
            push @short_messages, ' But no hosts matched !'
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

=item B<--max-retries>

Number of retries to get job result once launched.
Default : 20

=item B<--retry-interval>

Number of seconds between retries.
Default : 10 seconds

=item B<--extra-vars>

Extra vars passed to job template with k1=v1,k2=v2.
Keys and values must match [\w_\.]+
Only works for job templates with extra-vars enabled (prompt on launch checked).

=item B<--job-tags>

A string that represents a comma-separated list of tags in the playbook to run.
Only works for job templates with job tags enabled (prompt on launch checked).

=item B<--limit>

A string that represents a comma-separated list of hosts or groups to operate on.
Only works for job templates with limit enabled (prompt on launch checked).

=item B<--inventory>

A integer value for the foreign key of an inventory to use in this job run.
Only works for job templates with inventory enabled (prompt on launch checked).

=item B<--credential>

A integer value for the foreign key of a credential to use in this job run.
Only works for job templates with credential enabled (prompt on launch checked).

=back

=cut
