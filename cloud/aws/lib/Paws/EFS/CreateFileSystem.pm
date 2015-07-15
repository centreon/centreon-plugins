
package Paws::EFS::CreateFileSystem {
  use Moose;
  has CreationToken => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateFileSystem');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2015-02-01/file-systems');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'POST');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EFS::FileSystemDescription');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateFileSystemResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EFS::CreateFileSystem - Arguments for method CreateFileSystem on Paws::EFS

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateFileSystem on the 
Amazon Elastic File System service. Use the attributes of this class
as arguments to method CreateFileSystem.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateFileSystem.

As an example:

  $service_obj->CreateFileSystem(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> CreationToken => Str

  

String of up to 64 ASCII characters. Amazon EFS uses this to ensure
idempotent creation.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateFileSystem in L<Paws::EFS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

