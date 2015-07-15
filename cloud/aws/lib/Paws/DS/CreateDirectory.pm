
package Paws::DS::CreateDirectory {
  use Moose;
  has Description => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str', required => 1);
  has Password => (is => 'ro', isa => 'Str', required => 1);
  has ShortName => (is => 'ro', isa => 'Str');
  has Size => (is => 'ro', isa => 'Str', required => 1);
  has VpcSettings => (is => 'ro', isa => 'Paws::DS::DirectoryVpcSettings');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateDirectory');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DS::CreateDirectoryResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DS::CreateDirectory - Arguments for method CreateDirectory on Paws::DS

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateDirectory on the 
AWS Directory Service service. Use the attributes of this class
as arguments to method CreateDirectory.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateDirectory.

As an example:

  $service_obj->CreateDirectory(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Description => Str

  

A textual description for the directory.










=head2 B<REQUIRED> Name => Str

  

The fully qualified name for the directory, such as
C<corp.example.com>.










=head2 B<REQUIRED> Password => Str

  

The password for the directory administrator. The directory creation
process creates a directory administrator account with the username
C<Administrator> and this password.










=head2 ShortName => Str

  

The short name of the directory, such as C<CORP>.










=head2 B<REQUIRED> Size => Str

  

The size of the directory.










=head2 VpcSettings => Paws::DS::DirectoryVpcSettings

  

A DirectoryVpcSettings object that contains additional information for
the operation.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateDirectory in L<Paws::DS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

