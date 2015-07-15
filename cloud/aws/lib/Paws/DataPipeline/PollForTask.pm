
package Paws::DataPipeline::PollForTask {
  use Moose;
  has hostname => (is => 'ro', isa => 'Str');
  has instanceIdentity => (is => 'ro', isa => 'Paws::DataPipeline::InstanceIdentity');
  has workerGroup => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PollForTask');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DataPipeline::PollForTaskOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DataPipeline::PollForTask - Arguments for method PollForTask on Paws::DataPipeline

=head1 DESCRIPTION

This class represents the parameters used for calling the method PollForTask on the 
AWS Data Pipeline service. Use the attributes of this class
as arguments to method PollForTask.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to PollForTask.

As an example:

  $service_obj->PollForTask(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 hostname => Str

  

The public DNS name of the calling task runner.










=head2 instanceIdentity => Paws::DataPipeline::InstanceIdentity

  

Identity information for the EC2 instance that is hosting the task
runner. You can get this value from the instance using
C<http://169.254.169.254/latest/meta-data/instance-id>. For more
information, see Instance Metadata in the I<Amazon Elastic Compute
Cloud User Guide.> Passing in this value proves that your task runner
is running on an EC2 instance, and ensures the proper AWS Data Pipeline
service charges are applied to your pipeline.










=head2 B<REQUIRED> workerGroup => Str

  

The type of task the task runner is configured to accept and process.
The worker group is set as a field on objects in the pipeline when they
are created. You can only specify a single value for C<workerGroup> in
the call to C<PollForTask>. There are no wildcard values permitted in
C<workerGroup>; the string must be an exact, case-sensitive, match.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PollForTask in L<Paws::DataPipeline>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

