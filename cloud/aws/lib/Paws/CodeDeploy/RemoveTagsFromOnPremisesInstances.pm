
package Paws::CodeDeploy::RemoveTagsFromOnPremisesInstances {
  use Moose;
  has instanceNames => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has tags => (is => 'ro', isa => 'ArrayRef[Paws::CodeDeploy::Tag]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RemoveTagsFromOnPremisesInstances');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodeDeploy::RemoveTagsFromOnPremisesInstances - Arguments for method RemoveTagsFromOnPremisesInstances on Paws::CodeDeploy

=head1 DESCRIPTION

This class represents the parameters used for calling the method RemoveTagsFromOnPremisesInstances on the 
AWS CodeDeploy service. Use the attributes of this class
as arguments to method RemoveTagsFromOnPremisesInstances.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RemoveTagsFromOnPremisesInstances.

As an example:

  $service_obj->RemoveTagsFromOnPremisesInstances(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> instanceNames => ArrayRef[Str]

  

The names of the on-premises instances to remove tags from.










=head2 B<REQUIRED> tags => ArrayRef[Paws::CodeDeploy::Tag]

  

The tag key-value pairs to remove from the on-premises instances.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RemoveTagsFromOnPremisesInstances in L<Paws::CodeDeploy>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

