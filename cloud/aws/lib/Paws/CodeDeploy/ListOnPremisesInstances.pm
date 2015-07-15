
package Paws::CodeDeploy::ListOnPremisesInstances {
  use Moose;
  has nextToken => (is => 'ro', isa => 'Str');
  has registrationStatus => (is => 'ro', isa => 'Str');
  has tagFilters => (is => 'ro', isa => 'ArrayRef[Paws::CodeDeploy::TagFilter]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListOnPremisesInstances');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CodeDeploy::ListOnPremisesInstancesOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodeDeploy::ListOnPremisesInstances - Arguments for method ListOnPremisesInstances on Paws::CodeDeploy

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListOnPremisesInstances on the 
AWS CodeDeploy service. Use the attributes of this class
as arguments to method ListOnPremisesInstances.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListOnPremisesInstances.

As an example:

  $service_obj->ListOnPremisesInstances(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 nextToken => Str

  

An identifier that was returned from the previous list on-premises
instances call, which can be used to return the next set of on-premises
instances in the list.










=head2 registrationStatus => Str

  

The on-premises instances registration status:

=over

=item * Deregistered: Include in the resulting list deregistered
on-premises instances.

=item * Registered: Include in the resulting list registered
on-premises instances.

=back










=head2 tagFilters => ArrayRef[Paws::CodeDeploy::TagFilter]

  

The on-premises instance tags that will be used to restrict the
corresponding on-premises instance names that are returned.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListOnPremisesInstances in L<Paws::CodeDeploy>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

