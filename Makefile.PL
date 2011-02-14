use inc::Module::Install;

all_from('lib/HTML/Zoom.pm');

requires 'strictures' => 1;

WriteAll;
