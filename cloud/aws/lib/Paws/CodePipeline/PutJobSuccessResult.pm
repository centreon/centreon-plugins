
package Paws::CodePipeline::PutJobSuccessResult {
  use Moose;
  has continuationToken => (is => 'ro', isa => 'Str');
  has currentRevision => (is => 'ro', isa => 'Paws::CodePipeline::CurrentRevision');
  has executionDetails => (is => 'ro', isa => 'Paws::CodePipeline::ExecutionDetails');
  has jobId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PutJobSuccessResult');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodePipeline::PutJobSuccessResult - Arguments for method PutJobSuccessResult on Paws::CodePipeline

=head1 DESCRIPTION

This class represents the parameters used for calling the method PutJobSuccessResult on the 
AWS CodePipeline service. Use the attributes of this class
as arguments to method PutJobSuccessResult.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to PutJobSuccessResult.

As an example:

  $service_obj->PutJobSuccessResult(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 continuationToken => Str

  

A system-generated token, such as a AWS CodeDeploy deployment ID, that
the successful job used to complete a job asynchronously.










=head2 currentRevision => Paws::CodePipeline::CurrentRevision

  

The ID of the current revision of the artifact successfully worked upon
by the job.










=head2 executionDetails => Paws::CodePipeline::ExecutionDetails

  

The execution details of the successful job, such as the actions taken
by the job worker.










=head2 B<REQUIRED> jobId => Str

  

The unique system-generated ID of the job that succeeded. This is the
same ID returned from PollForJobs.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PutJobSuccessResult in L<Paws::CodePipeline>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

