
package Paws::IAM::DetachGroupPolicy {
  use Moose;
  has GroupName => (is => 'ro', isa => 'Str', required => 1);
  has PolicyArn => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DetachGroupPolicy');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::DetachGroupPolicy - Arguments for method DetachGroupPolicy on Paws::IAM

=head1 DESCRIPTION

This class represents the parameters used for calling the method DetachGroupPolicy on the 
AWS Identity and Access Management service. Use the attributes of this class
as arguments to method DetachGroupPolicy.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DetachGroupPolicy.

As an example:

  $service_obj->DetachGroupPolicy(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> GroupName => Str

  

The name (friendly name, not ARN) of the group to detach the policy
from.










=head2 B<REQUIRED> PolicyArn => Str

  



=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DetachGroupPolicy in L<Paws::IAM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

