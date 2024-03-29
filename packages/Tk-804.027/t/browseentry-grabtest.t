#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: browseentry-grabtest.t,v 1.3 2003/04/21 19:49:24 eserte Exp $
# Author: Slaven Rezic
#

# test whether grabs are correctly saved

use strict;

use Tk;
use Tk::BrowseEntry;

BEGIN {
    if (!eval q{
	use Test;
	1;
    }) {
	print "# tests only work with installed Test module\n";
	print "1..1\n";
	print "ok 1\n";
	exit;
    }
}

BEGIN { plan tests => 1 }

if (!defined $ENV{BATCH}) { $ENV{BATCH} = 1 }

my $mw = tkinit;
$mw->geometry("+10+10");
my $t = $mw->Toplevel;
$t->geometry("+20+20");

$mw->Label(-text => "disabled")->pack;
$mw->Entry->pack;

$t->BrowseEntry->pack;
$t->Button(-text => "OK",
	   -command => sub { $mw->destroy })->pack;
$t->grab;

if ($ENV{BATCH}) {
    $mw->after(500,sub{$mw->destroy});
}

MainLoop;

ok(1);

__END__
