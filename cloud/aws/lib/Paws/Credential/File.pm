package Paws::Credential::File {
  use Moose;
  use Config::INI::Reader;

  has profile => (is => 'ro', default => sub { $ENV{ AWS_DEFAULT_PROFILE } or 'default' });

  has credentials_file => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    return $self->path . '/' . $self->file_name;
  });

  has file_name => (is => 'ro', default => sub { 'credentials' });
  has path => (is => 'ro', default => sub { return $ENV{HOME} . '/.aws/' });

  has _ini_contents => (is => 'ro', isa => 'HashRef', lazy => 1, default => sub {
    my $self = shift;
    my $ini_file = $self->credentials_file;
    return {} if (not -e $ini_file);
    my $ini = Config::INI::Reader->read_file($ini_file);
    return $ini;
  });

  has access_key => (is => 'ro', lazy => 1, default => sub {  
    my $self = shift;
    my $ini_section = $self->profile;
    my $ak = $self->_ini_contents->{ $ini_section }->{ aws_access_key_id };
    return $ak;
  });
  has secret_key => (is => 'ro', lazy => 1, default => sub {  
    my $self = shift;
    my $ini_section = $self->profile;
    my $sk = $self->_ini_contents->{ $ini_section }->{ aws_secret_access_key };
    return $sk;
  });
  has session_token => (is => 'ro', lazy => 1, default => sub { 
    my $self = shift;
    my $ini_section = $self->profile;
    my $st = $self->_ini_contents->{ $ini_section }->{ aws_session_token };
    return $st;
  });

  with 'Paws::Credential';

  no Moose;
}

1;



