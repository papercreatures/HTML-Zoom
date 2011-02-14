use strict;
use warnings FATAL => 'all';
use 5.008001;
use ExtUtils::MakeMaker;

(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'HTML-Zoom',
  VERSION_FROM => 'lib/HTML/Zoom.pm',
  PREREQ_PM => { strictures => 1, 'Test::More' => '0.88' },
  test => { TESTS => 't/*.t t/*/*.t' },
);
