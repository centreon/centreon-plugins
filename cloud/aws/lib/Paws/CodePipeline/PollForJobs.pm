
package Paws::CodePipeline::PollForJobs {
  use Moose;
  has actionTypeId => (is => 'ro', isa => 'Paws::CodePipeline::ActionTypeId', required => 1);
  has maxBatchSize => (is => 'ro', isa => 'Int');
  has queryParam => (is => 'ro', isa => 'Paws::CodePipeline::QueryParamMap');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PollForJobs');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CodePipeline::PollForJobsOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodePipeline::PollForJobs - Arguments for method PollForJobs on Paws::CodePipeline

=head1 DESCRIPTION

This class represents the parameters used for calling the method PollForJobs on the 
AWS CodePipeline service. Use the attributes of this class
as arguments to method PollForJobs.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to PollForJobs.

As an example:

  $service_obj->PollForJobs(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> actionTypeId => Paws::CodePipeline::ActionTypeId

  

=head2 maxBatchSize => Int

  

The maximum number of jobs to return in a poll for jobs call.










=head2 queryParam => Paws::CodePipeline::QueryParamMap

  

A map of property names and values. For an action type with no
queryable properties, this value must be null or an empty map. For an
action type with a queryable property, you must supply that property as
a key in the map. Only jobs whose action configuration matches the
mapped value will be returned.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PollForJobs in L<Paws::CodePipeline>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

