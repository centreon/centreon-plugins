
package Paws::IAM::ListGroupPolicies {
  use Moose;
  has GroupName => (is => 'ro', isa => 'Str', required => 1);
  has Marker => (is => 'ro', isa => 'Str');
  has MaxItems => (is => 'ro', isa => 'Int');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListGroupPolicies');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::IAM::ListGroupPoliciesResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ListGroupPoliciesResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::ListGroupPolicies - Arguments for method ListGroupPolicies on Paws::IAM

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListGroupPolicies on the 
AWS Identity and Access Management service. Use the attributes of this class
as arguments to method ListGroupPolicies.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListGroupPolicies.

As an example:

  $service_obj->ListGroupPolicies(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> GroupName => Str

  

The name of the group to list policies for.










=head2 Marker => Str

  

Use this parameter only when paginating results and only after you have
received a response where the results are truncated. Set it to the
value of the C<Marker> element in the response you just received.










=head2 MaxItems => Int

  

Use this only when paginating results to indicate the maximum number of
items you want in the response. If there are additional items beyond
the maximum you specify, the C<IsTruncated> response element is
C<true>.

This parameter is optional. If you do not include it, it defaults to
100.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListGroupPolicies in L<Paws::IAM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

