use Tk;
use Encode qw(FB_CROAK);
BEGIN
{
 my $enc = Tk::SystemEncoding();
 eval { $enc->encode("\x{AC00}",FB_CROAK) };
 if ($@)
  {
   my $err = "$@";
   print "1..0 # Skipped: locale's '",$enc->name,"' cannot represent Korean.\n";
   CORE::exit(0);
  }
}
use Test::More (tests => 271);
use Tk::widgets qw(Text);
my $mw   = MainWindow->new;
$mw->geometry("+10+10");
my $font = 'Times';
#my $font = 'fixed';
my $t    = $mw->Scrolled(Text => -font => [$font => 12, 'normal'])->pack( -fill => 'both', -expand => 1);
my $file = __FILE__;
$file =~ s/\.t$/.dat/;
open(my $fh,"<:utf8",$file) || die "Cannot open $file:$!";
while (<$fh>)
 {
  # s/[^ -~\s]/?/g;
  $t->insert('end',$_);
  $t->see('end');
  $mw->update;
  ok(1);
 }
close($fh);
$mw->after(2000,[ destroy => $mw ]);
MainLoop;
