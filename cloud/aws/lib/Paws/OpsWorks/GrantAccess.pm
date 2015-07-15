
package Paws::OpsWorks::GrantAccess {
  use Moose;
  has InstanceId => (is => 'ro', isa => 'Str', required => 1);
  has ValidForInMinutes => (is => 'ro', isa => 'Int');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GrantAccess');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::OpsWorks::GrantAccessResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::GrantAccess - Arguments for method GrantAccess on Paws::OpsWorks

=head1 DESCRIPTION

This class represents the parameters used for calling the method GrantAccess on the 
AWS OpsWorks service. Use the attributes of this class
as arguments to method GrantAccess.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GrantAccess.

As an example:

  $service_obj->GrantAccess(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> InstanceId => Str

  

The instance's AWS OpsWorks ID.










=head2 ValidForInMinutes => Int

  

The length of time (in minutes) that the grant is valid. When the grant
expires at the end of this period, the user will no longer be able to
use the credentials to log in. If the user is logged in at the time, he
or she automatically will be logged out.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GrantAccess in L<Paws::OpsWorks>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

