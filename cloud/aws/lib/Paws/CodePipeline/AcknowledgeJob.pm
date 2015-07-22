
package Paws::CodePipeline::AcknowledgeJob {
  use Moose;
  has jobId => (is => 'ro', isa => 'Str', required => 1);
  has nonce => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'AcknowledgeJob');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CodePipeline::AcknowledgeJobOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodePipeline::AcknowledgeJob - Arguments for method AcknowledgeJob on Paws::CodePipeline

=head1 DESCRIPTION

This class represents the parameters used for calling the method AcknowledgeJob on the 
AWS CodePipeline service. Use the attributes of this class
as arguments to method AcknowledgeJob.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to AcknowledgeJob.

As an example:

  $service_obj->AcknowledgeJob(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> jobId => Str

  

The unique system-generated ID of the job for which you want to confirm
receipt.










=head2 B<REQUIRED> nonce => Str

  

A system-generated random number that AWS CodePipeline uses to ensure
that the job is being worked on by only one job worker. This number
must be returned in the response.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method AcknowledgeJob in L<Paws::CodePipeline>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

