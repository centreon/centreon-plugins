# Path to your package. '::' instead of '/', and no .pm at the end.
package apps::myawesomeapp::api::mode::appmetrics;

# Don't forget these ;)
use strict;
use warnings;
# We want to connect to an HTTP server, let's use the common module
use centreon::plugins::http;
# Use the counter module. It will save you a lot of work and will manage a lot of things for you.
# Consider this as mandatory when writing a new mode. 
use base qw(centreon::plugins::templates::counter);
# Import some functions that will make your life easier when dealing with string values
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
# We will have to process some JSON, no need to reinvent the wheel, load the lib you installed in a previous section
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    # All options/properties of this mode, always add the force_new_perfdata => 1 to enable new metric/performance data naming.
    # It also where you can specify that the plugin uses a cache file for example
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    # This is where you can specify options/arguments your plugin supports.
    # All options here stick to what the centreon::plugins::http module needs to establish a connection
    # You don't have to specify all options from the http module, only the one that the user may want to tweak for its needs
    $options{options}->add_options(arguments => {
        # One the left it's the option name that will be used in the command line. The ':s' at the end is to 
        # define that this options takes a value.  
        # On the right, it's the code name for this option, optionnaly you can define a default value so the user 
        # doesn't have to set it
         'hostname:s'           => { name => 'hostname' },
         'port:s'               => { name => 'port', default => 443 },
         'proto:s'              => { name => 'proto', default => 'https' },
         'timeout:s'            => { name => 'timeout' },
        # These options are here to defined conditions about which status the plugin will return regarding HTTP response code
         'unknown-status:s'     => { name => 'unknown_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
         'warning-status:s'     => { name => 'warning_status' },
         'critical-status:s'    => { name => 'critical_status', default => '' }
    });

    # This is to create a local copy of a centreon::plugins::http that we will manipulate
    # %options basically overwrite default http value with key/value pairs from options above to instantiate the http module
    # Ref https://github.com/centreon/centreon-plugins/blob/520a1f8c10cd434c6dedd1e342285eecff8b9d1b/centreon/plugins/http.pm#L59
    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    # Check if the user provided a value for --hostname option. If not, display a message and exit
    if (!defined($self->{option_results}->{hostname}) || $self->{option_results}->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Please set hostname option');
        $self->{output}->option_exit();
    }
    # Set parameters for http module, note that the $self->{option_results} is a hash containing 
    # all your options key/value pairs.
    $self->{http}->set_options(%{$self->{option_results}});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        # health and queries are global metric, they don't refer to a specific instance. 
        # In other words, you cannot get several values for health or queries
        # That's why the type is 0.
        { name => 'health', type => 0, cb_prefix_output => 'prefix_health_output' },
        { name => 'queries', type => 0, cb_prefix_output => 'prefix_queries_output' },
        # app_metrics groups connections and errors and each will receive value for both instances (my-awesome-frontend and my-awesome-db)
        # the type => 1 explicits that
        # as above, you can define a callback (cb) function to manage the output prefix. This function is called 
        # each time a value is passed to the counter and can be shared across multiple counters.
        { name => 'app_metrics', type => 1, cb_prefix_output => 'prefix_app_output' }
    ];

    $self->{maps_counters}->{health} = [
        # This counter is specific because it deals with a string value
        {
            label => 'health',
            # All properties below (before set) are related to the catalog_status_ng catalog function imported at the top of our mode
            type => 2,
            # These properties allow you to define default thresholds for each status but not mandatory.
            warning_default => '%{health} eq "yellow"', 
            critical_default => '%{health} eq "red"', 
            # To simplify, manage things related to how get value in the counter, what to display and specific threshold 
            # check because of the type of the data (string)
            set => {
                key_values => [ { name => 'health' } ],
                output_template => 'status: %s',
                # Force ignoring perfdata as the collected data is a string
                closure_custom_perfdata => sub { return 0; },
                # Use imported function to check thresholds and define return code
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
    $self->{maps_counters}->{queries} = [
        # The label defines options name, a --warning-select and --critical-select will be added to the mode
        # The nlabel is the name of your performance data / metric that will show up in your graph
        { 
            label => 'select', 
            nlabel => 'myawesomeapp.db.queries.select.count', 
            set => {
            # Key value name is the name we will use to pass the data to this counter. You can have several ones.
                key_values => [ { name => 'select' } ],
                # Output template describe how the value will display
                output_template => 'select: %s',
                # Perfdata array allow you to define relevant metrics properties (min, max) and its sprintf template format
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'update', nlabel => 'myawesomeapp.db.queries.update.count', set => {
                key_values => [ { name => 'update' } ],
                output_template => 'update: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'delete', nlabel => 'myawesomeapp.db.queries.delete.count', set => {
                key_values => [ { name => 'delete' } ],
                output_template => 'delete: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];
    $self->{maps_counters}->{app_metrics} = [
        # The app_metrics has two different labels, connection and errors.
        { label => 'connections', nlabel => 'myawesomeapp.connections.count', set => {
                # pay attention the extra display key_value. It will receive the instance value. (my-awesome-db, my-awesome-frontend).
                # the display key_value isn't mandatory but we show it here for education purpose
                key_values => [ { name => 'connections' }, { name => 'display' } ],
                output_template => 'connections: %s',
                perfdatas => [
                    # we add the label_extra_instance option to have one perfdata per instance
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'errors', nlabel => 'myawesomeapp.errors.count', set => {
                key_values => [ { name => 'errors' }, { name => 'display' } ],
                output_template => 'errors: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_health_output {
    my ($self, %options) = @_;

    return 'My-awesome-app ';
}

sub prefix_queries_output {
    my ($self, %options) = @_;

    return 'Queries: ';
}

sub prefix_app_output {
    my ($self, %options) = @_;

    return "'" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    # We have already loaded all things required for the http module
    # Use the request method from the imported module to run the GET request against the URL path of our API
    my ($content) = $self->{http}->request(url_path => '/v3/da8d5aa7-abb4-4a5f-a31c-6700dd34a656');
    # Uncomment the line below when you reached this part of the tutorial.
    # print $content;

    # Declare a scalar deserialize the JSON content string into a perl data structure
    my $decoded_content;
    eval {
        $decoded_content = JSON::XS->new->decode($content);
    };
    # Catch the error that may arise in case the data received is not JSON
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot encode JSON result");
        $self->{output}->option_exit();    
    }
    # Uncomment the lines below when you reached this part of the tutorial.
    # use Data::Dumper; 
    # print Dumper($decoded_content);
    # print "My App health is '" . $decoded_content->{health} . "'\n";

    # Here is where the counter magic happens.
    
    # $self->{health} is your counter definition (see $self->{maps_counters}->{<name>})
    # Here, we map the obtained string $decoded_content->{health} with the health key_value of the counter
    $self->{health} = { 
        health => $decoded_content->{health}
    };

    # $self->{queries} is your counter definition (see $self->{maps_counters}->{<name>}) 
    # Here, we map the obtained values from the db_queries nodes with the key_value defined in the counter
    $self->{queries} = {
        select => $decoded_content->{db_queries}->{select},
        update => $decoded_content->{db_queries}->{update},
        delete => $decoded_content->{db_queries}->{delete}
    };

    # Initialize an empty app_metrics counter.
    $self->{app_metrics} = {};
    # Loop in the connections array of hashes
    foreach my $entry (@{ $decoded_content->{connections} }) {
        # Same logic than type => 0 counters but an extra key $entry->{component} to associate the value 
        # with a specific instance
        $self->{app_metrics}->{ $entry->{component} }->{display} = $entry->{component};
        $self->{app_metrics}->{ $entry->{component} }->{connections} = $entry->{value};
    };

    # Exactly the same thing with errors
    foreach my $entry (@{ $decoded_content->{errors} }) {
        # Don't need to redefine the display key, just assign a value to the error key_value
        $self->{app_metrics}->{ $entry->{component} }->{errors} = $entry->{value};
    };

}

1;

__END__

=head1 MODE

Check my-awesome-app metrics exposed through its API

=over 8

=item B<--warning/critical-health>

Warning and critical threshold for application health string. 

Defaults values are: --warning-health='%{health} eq "yellow"' --critical-health='%{health} eq "red"'

=item B<--warning/critical-select>

Warning and critical threshold for select queries

=item B<--warning/critical-update>

Warning and critical threshold for update queries

=item B<--warning/critical-delete>

Warning and critical threshold for delete queries

=item B<--warning/critical-connections>

Warning and critical threshold for connections

=item B<--warning/critical-errors>

Warning and critical threshold for errors

=back