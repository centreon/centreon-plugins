
package Paws::CodePipeline::PutThirdPartyJobFailureResult {
  use Moose;
  has clientToken => (is => 'ro', isa => 'Str', required => 1);
  has failureDetails => (is => 'ro', isa => 'Paws::CodePipeline::FailureDetails', required => 1);
  has jobId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PutThirdPartyJobFailureResult');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodePipeline::PutThirdPartyJobFailureResult - Arguments for method PutThirdPartyJobFailureResult on Paws::CodePipeline

=head1 DESCRIPTION

This class represents the parameters used for calling the method PutThirdPartyJobFailureResult on the 
AWS CodePipeline service. Use the attributes of this class
as arguments to method PutThirdPartyJobFailureResult.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to PutThirdPartyJobFailureResult.

As an example:

  $service_obj->PutThirdPartyJobFailureResult(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> clientToken => Str

  

The clientToken portion of the clientId and clientToken pair used to
verify that the calling entity is allowed access to the job and its
details.










=head2 B<REQUIRED> failureDetails => Paws::CodePipeline::FailureDetails

  

=head2 B<REQUIRED> jobId => Str

  

The ID of the job that failed. This is the same ID returned from
PollForThirdPartyJobs.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PutThirdPartyJobFailureResult in L<Paws::CodePipeline>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

