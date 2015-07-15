
package Paws::DataPipeline::ReportTaskRunnerHeartbeat {
  use Moose;
  has hostname => (is => 'ro', isa => 'Str');
  has taskrunnerId => (is => 'ro', isa => 'Str', required => 1);
  has workerGroup => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ReportTaskRunnerHeartbeat');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DataPipeline::ReportTaskRunnerHeartbeatOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DataPipeline::ReportTaskRunnerHeartbeat - Arguments for method ReportTaskRunnerHeartbeat on Paws::DataPipeline

=head1 DESCRIPTION

This class represents the parameters used for calling the method ReportTaskRunnerHeartbeat on the 
AWS Data Pipeline service. Use the attributes of this class
as arguments to method ReportTaskRunnerHeartbeat.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ReportTaskRunnerHeartbeat.

As an example:

  $service_obj->ReportTaskRunnerHeartbeat(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 hostname => Str

  

The public DNS name of the task runner.










=head2 B<REQUIRED> taskrunnerId => Str

  

The ID of the task runner. This value should be unique across your AWS
account. In the case of AWS Data Pipeline Task Runner launched on a
resource managed by AWS Data Pipeline, the web service provides a
unique identifier when it launches the application. If you have written
a custom task runner, you should assign a unique identifier for the
task runner.










=head2 workerGroup => Str

  

The type of task the task runner is configured to accept and process.
The worker group is set as a field on objects in the pipeline when they
are created. You can only specify a single value for C<workerGroup>.
There are no wildcard values permitted in C<workerGroup>; the string
must be an exact, case-sensitive, match.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ReportTaskRunnerHeartbeat in L<Paws::DataPipeline>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

