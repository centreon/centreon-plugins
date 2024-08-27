use 5.008005;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'Filesys::SmbClient',
    VERSION_FROM   => 'SmbClient.pm',
    PREREQ_PM      => { 'Test::More' => 0 },
    ABSTRACT_FROM  => 'SmbClient.pm',
    AUTHOR         => 'Quentin Garnier',
    LIBS           => ['-lsmbclient'],
    DEFINE         => '',
    INC            => '-I.',
    OBJECT         => 'libauthSamba.o SmbClient.o',
);
