
package Paws::DS::ConnectDirectory {
  use Moose;
  has ConnectSettings => (is => 'ro', isa => 'Paws::DS::DirectoryConnectSettings', required => 1);
  has Description => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str', required => 1);
  has Password => (is => 'ro', isa => 'Str', required => 1);
  has ShortName => (is => 'ro', isa => 'Str');
  has Size => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ConnectDirectory');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DS::ConnectDirectoryResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DS::ConnectDirectory - Arguments for method ConnectDirectory on Paws::DS

=head1 DESCRIPTION

This class represents the parameters used for calling the method ConnectDirectory on the 
AWS Directory Service service. Use the attributes of this class
as arguments to method ConnectDirectory.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ConnectDirectory.

As an example:

  $service_obj->ConnectDirectory(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ConnectSettings => Paws::DS::DirectoryConnectSettings

  

A DirectoryConnectSettings object that contains additional information
for the operation.










=head2 Description => Str

  

A textual description for the directory.










=head2 B<REQUIRED> Name => Str

  

The fully-qualified name of the on-premises directory, such as
C<corp.example.com>.










=head2 B<REQUIRED> Password => Str

  

The password for the on-premises user account.










=head2 ShortName => Str

  

The NetBIOS name of the on-premises directory, such as C<CORP>.










=head2 B<REQUIRED> Size => Str

  

The size of the directory.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ConnectDirectory in L<Paws::DS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

