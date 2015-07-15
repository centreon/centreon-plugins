
package Paws::RDS::CreateOptionGroup {
  use Moose;
  has EngineName => (is => 'ro', isa => 'Str', required => 1);
  has MajorEngineVersion => (is => 'ro', isa => 'Str', required => 1);
  has OptionGroupDescription => (is => 'ro', isa => 'Str', required => 1);
  has OptionGroupName => (is => 'ro', isa => 'Str', required => 1);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::RDS::Tag]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateOptionGroup');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RDS::CreateOptionGroupResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateOptionGroupResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::CreateOptionGroup - Arguments for method CreateOptionGroup on Paws::RDS

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateOptionGroup on the 
Amazon Relational Database Service service. Use the attributes of this class
as arguments to method CreateOptionGroup.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateOptionGroup.

As an example:

  $service_obj->CreateOptionGroup(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> EngineName => Str

  

Specifies the name of the engine that this option group should be
associated with.










=head2 B<REQUIRED> MajorEngineVersion => Str

  

Specifies the major version of the engine that this option group should
be associated with.










=head2 B<REQUIRED> OptionGroupDescription => Str

  

The description of the option group.










=head2 B<REQUIRED> OptionGroupName => Str

  

Specifies the name of the option group to be created.

Constraints:

=over

=item * Must be 1 to 255 alphanumeric characters or hyphens

=item * First character must be a letter

=item * Cannot end with a hyphen or contain two consecutive hyphens

=back

Example: C<myoptiongroup>










=head2 Tags => ArrayRef[Paws::RDS::Tag]

  



=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateOptionGroup in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

