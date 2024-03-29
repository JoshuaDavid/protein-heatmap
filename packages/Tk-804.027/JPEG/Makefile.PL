use Tk::MMutil;
use Tk::Config ();
use File::Copy;
my $l = $Config::Config{'lib_ext'};

# use ExtUtils::MakeMaker '6.05';

my @local_jpeg = (
    'INC'          => '-Ijpeg',
    'MYEXTLIB'     => "jpeg/libjpeg$l",
);

use Tk::MMtry;

if ($Tk::MMtry::VERSION ge '4.007' && try_run("jpeg/has_jpeg.c",['-I/usr/local/include'],['-ljpeg']))
 {
  push(@args, LIBS => ['-ljpeg'],
              INC  => '-I/usr/local/include',
              DEFINE => '-DHAVE_JPEGLIB_H',
      );
  warn "Using system's -ljpeg\n";
  unlink("jpeg/Makefile.PL");
 }
else
 {
  push(@args, MYEXTLIB  => "jpeg/libjpeg$l",
              'INC'     => '-Ijpeg');
  copy("jpeg/Makefile.maybe","jpeg/Makefile.PL");
  warn "Building jpeg/libjpeg$l\n";
 }

Tk::MMutil::TkExtMakefile(@args,
    'NAME'         => 'Tk::JPEG',
    'EXE_FILES'    => ['tkjpeg'],
    'PMLIBDIRS'    => [],
    'PREREQ_PM'    => { # Tk => 800.015,
                        ExtUtils::MakeMaker => 6.05 },
    'OBJECT'       => '$(O_FILES)',
    'VERSION_FROM' => 'JPEG.pm',
    'XS_VERSION'   => $Tk::Config::VERSION,
    'dist'         => { COMPRESS => 'gzip -f9', SUFFIX => '.gz' },
    'clean'        => { FILES => 'jpeg/Makefile jpeg/Makefile.PL jpeg/config.status jpeg/jconfig.h' }

   );

package MY;


sub postamble {
  if (-f "jpeg/Makefile.PL")
   {
    return
'
$(MYEXTLIB)  : FORCE
	cd jpeg && $(MAKE) libjpeg'.$l.'
';

   }
}



