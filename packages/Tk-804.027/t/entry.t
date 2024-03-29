#!/usr/bin/perl -w
# -*- perl -*-

# This file is a Tcl script to test entry widgets in Tk.  It is
# organized in the standard fashion for Tcl tests.
#
# Copyright (c) 1994 The Regents of the University of California.
# Copyright (c) 1994-1997 Sun Microsystems, Inc.
# Copyright (c) 1998-1999 by Scriptics Corporation.
# All rights reserved.
#
# Translated to Perl/Tk by Slaven Rezic

use strict;

use Tk;
use Tk::Trace;
use Tk::Config ();
my $Xft = $Tk::Config::xlib =~ /-lXft\b/;


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

BEGIN {
        # these fail (sometimes) under 'make test'
        my @fragile = qw(160 161 167 191 193 195);
        @fragile = () ; # unless $ENV{PERL_DL_NONLAZY};
        plan tests => 336,
        todo => \@fragile
      }

my $mw = Tk::MainWindow->new();
$mw->geometry('+10+10');

my $e0 = $mw->Entry;
ok(Tk::Exists($e0), 1);
ok(ref $e0, "Tk::Entry");

my @scrollInfo;
sub scroll {
    (@scrollInfo) = @_;
}

# Create additional widget that's used to hold the selection at times.

my $sel = $mw->Entry;
$sel->insert("end", "This is some sample text");

# Font names

my $big   = $Xft ? '{Adobe Helvetica} -24' : "-adobe-helvetica-medium-r-normal--24-240-75-75-p-*-iso8859-1";
my $fixed = $Xft ? '{Adobe Courier} -12' : "-adobe-courier-medium-r-normal--12-120-75-75-m-*-iso8859-1";

# Create entries in the option database to be sure that geometry options
# like border width have predictable values.

$mw->option("add", "*Entry.borderWidth", 2);
$mw->option("add", "*Entry.highlightThickness", 2);
$mw->option("add", "*Entry.font", $Xft ? '{Adobe Helvetica} -12' : "Helvetica -12");

my $e = $mw->Entry(qw(-bd 2 -relief sunken))->pack;
$mw->update;

my $skip_font_test;
if (!$Xft) { # XXX Is this condition necessary?
    my %fa = $mw->fontActual($e->cget(-font));
    my %expected = (
		    "-weight" => "normal",
		    "-underline" => 0,
		    "-family" => "helvetica",
		    "-slant" => "roman",
		    "-size" => -12,
		    "-overstrike" => 0,
		   );
    while(my($k,$v) = each %expected) {
	if ($v ne $fa{$k}) {
	    $skip_font_test = "font-related tests";
	    last;
	}
    }
}
my $skip_wm_test;
unless (defined($ENV{WINDOWMANAGER}) &&
        $ENV{WINDOWMANAGER} eq '/usr/X11R6/bin/kde') {
    $skip_wm_test = "window manager dependent tests";
}

my $i;

use constant SKIP_CGET    => 5;
use constant SKIP_CONF    => 6;
use constant SKIP_ERROR   => 7;
use constant SKIP_RESTORE => 8;

my @tests = (
    [qw(-background), '#ff0000', '#ff0000', 'non-existent',
	    'unknown color name "non-existent"'],
    [qw(-bd 4 4 badValue), 'bad screen distance "badValue"'],
    [qw(-bg), '#ff0000', '#ff0000', 'non-existent', 'unknown color name "non-existent"'],
    [qw(-borderwidth 1.3 1 badValue), 'bad screen distance "badValue"'],
    [qw(-cursor arrow arrow badValue), 'bad cursor spec "badValue"'],
    [qw(-exportselection yes 1 xyzzy), 'expected boolean value but got "xyzzy"', 0,0,1],
    [qw(-fg), '#110022', '#110022', 'bogus', 'unknown color name "bogus"'],
    [qw(-font -Adobe-Helvetica-Medium-R-Normal--*-120-*-*-*-*-*-*
	-Adobe-Helvetica-Medium-R-Normal--*-120-*-*-*-*-*-*), undef,
        'font "" doesn\'t exist',
        1,0,1],
    [qw(-foreground), '#110022', '#110022', 'bogus', 'unknown color name "bogus"'],
    [qw(-highlightbackground), '#123456', '#123456', 'ugly', 'unknown color name "ugly"'],
    [qw(-highlightcolor), '#123456', '#123456', 'bogus', 'unknown color name "bogus"'],
    [qw(-highlightthickness 6 6 bogus), 'bad screen distance "bogus"'],
    [qw(-highlightthickness -2 0), undef, undef],
    [qw(-insertbackground), '#110022', '#110022', 'bogus', 'unknown color name "bogus"'],
    [qw(-insertborderwidth 1.3 1 2.6x), 'bad screen distance "2.6x"'],
    [qw(-insertofftime 100 100 3.2), 'expected integer but got "3.2"', 0,0,1],
    [qw(-insertontime 100 100 3.2), 'expected integer but got "3.2"', 0,0,1],
    [qw(-justify right right bogus), 'bad justification "bogus": must be left, right, or center'],
    [qw(-relief groove groove 1.5), 'bad relief "1.5": must be flat, groove, raised, ridge, solid, or sunken'],
    [qw(-selectbackground), '#110022', '#110022', 'bogus', 'unknown color name "bogus"'],
    [qw(-selectborderwidth 1.3 1 badValue), 'bad screen distance "badValue"'],
    [qw(-selectforeground), '#654321', '#654321', 'bogus', 'unknown color name "bogus"'],
    [qw(-show * *), undef, undef],
    [qw(-state n normal bogus), 'bad state "bogus": must be disabled, normal, or readonly'],
    [qw(-takefocus), "any string", "any string", undef, undef],
    [qw(-textvariable), \$i, \$i, undef, undef],
    [qw(-width 402 402 3p), "'3p' isn't numeric"],
    [qw(-xscrollcommand), 'Some command', 'Some command', undef, undef, 1,1,1,1],
);

foreach my $test (@tests) {
    my $name = $test->[0];
    $e->configure($name, $test->[1]);
    if ($test->[SKIP_CGET]) {
	skip(1,1);
    } else {
	ok($e->cget($name), $test->[2], "Failed to cget $name");
    }
    if ($test->[SKIP_CONF]) {
	skip(1,1);
    } else {
	ok(($e->configure($name))[4], $e->cget($name), "Failed comparing configure and cget values for $name");
    }

    if (defined $test->[4]) {
	if ($test->[SKIP_ERROR]) {
	    skip(1,1);
	} else {
	    eval { $e->configure($name, $test->[3]) };
	    ok($@ =~ /$test->[4]/, 1, "Error message for $name: Got $@, expected $test->[4]");
	}
    }
    if ($test->[SKIP_RESTORE]) {
	skip(1,1);
    } else {
	$e->configure($name, ($e->configure($name))[3]);
    }
}

eval { $e->destroy };
$e = $mw->Entry;
ok(Tk::Exists($e), 1);
ok($e->class, 'Entry');
ok(ref $e, 'Tk::Entry');

eval { $e->destroy; undef $e };
eval { $e = $mw->Entry(-gorp => 'foo') };
ok($@ =~ /unknown option "-gorp"/, 1, $@);
ok(!Tk::Exists($e), 1);
ok(!defined $e, 1);

eval { $e->destroy };
$e = $mw->Entry(-font => $fixed)->pack;
$e->update;

my $cx = $mw->fontMeasure($fixed, 'a');
my $cy = $mw->fontMetrics($fixed, '-linespace');
my $ux = $mw->fontMeasure($fixed, "\x{4e4e}"); # XXX no unicode yet

eval { $e->bbox };
ok($@ =~ /wrong \# args: should be ".* bbox index"/, 1, $@);

eval { $e->bbox(qw(a b)) };
ok($@ =~ /wrong \# args: should be ".* bbox index"/, 1, $@);

eval { $e->bbox(qw(bogus)) };
ok($@ =~ /bad entry index "bogus"/, 1, $@);

$e->delete(0,"end");
ok(join(",",$e->bbox(0)),"5,5,0,$cy");

$e->delete(0,"end");
$e->insert(0,"abc");
ok(join(",",$e->bbox(3)),join(",",5+2*$cx,5,$cx,$cy));
ok(join(",",$e->bbox("end")), join(",",$e->bbox(3)));

# XXX no unicode yet
#  test entry-3.7 {EntryWidgetCmd procedure, "bbox" widget command} {
#      # Tcl_UtfAtIndex(): utf at end
#      .e delete 0 end
#      .e insert 0 "ab\u4e4e"
#      .e bbox end
#  } "[expr 5+2*$cx] 5 $ux $cy"
#  test entry-3.8 {EntryWidgetCmd procedure, "bbox" widget command} {
#      # Tcl_UtfAtIndex(): utf before index
#      .e delete 0 end
#      .e insert 0 "ab\u4e4ec"
#      .e bbox 3
#  } "[expr 5+2*$cx+$ux] 5 $cx $cy"

$e->delete(0,"end");
ok("5,5,0,$cy",join(",",$e->bbox("end")));

# XXX no unicode yet
#  test entry-3.10 {EntryWidgetCmd procedure, "bbox" widget command} {
#      .e delete 0 end
#      .e insert 0 "abcdefghij\u4e4eklmnop"
#      list [.e bbox 0] [.e bbox 1] [.e bbox 10] [.e bbox end]
#  } [list "5 5 $cx $cy" "[expr 5+$cx] 5 $cx $cy" "[expr 5+10*$cx] 5 $ux $cy" "[expr 5+$ux+15*$cx] 5 $cx $cy"]

eval { $e->cget };
ok($@ =~ /wrong \# args: should be ".* cget option"/, 1, $@);

eval { $e->cget(qw(a b)) };
ok($@ =~ /wrong \# args: should be ".* cget option"/, 1, $@);

eval { $e->cget(-gorp) };
ok($@ =~ /unknown option "-gorp"/, 1, $@);

$e->configure(-bd => 4);
ok($e->cget(-bd), 4);
ok(scalar @{$e->configure}, 36);

eval { $e->configure('-foo') };
ok($@ =~ /unknown option "-foo"/, 1, $@);

$e->configure(-bd => 4);
$e->configure(-bg => '#ffffff');
ok(($e->configure(-bd))[4], 4);

eval { $e->delete };
ok($@ =~ /wrong \# args: should be ".* delete firstIndex \?lastIndex\?"/, 1, $@);

eval { $e->delete(qw(a b c)) };
ok($@ =~ /wrong \# args: should be ".* delete firstIndex \?lastIndex\?"/, 1, $@);

eval { $e->delete("foo") };
ok($@ =~ /bad entry index "foo"/, 1, $@);

eval { $e->delete(0, "bar") };
ok($@ =~ /bad entry index "bar"/, 1, $@);

$e->delete(0, "end");
$e->insert("end", "01234567890");
$e->delete(2, 4);
ok($e->get, "014567890");

$e->delete(0, "end");
$e->insert("end", "01234567890");
$e->delete(6);
ok($e->get, "0123457890");

#  test entry-3.24 {EntryWidgetCmd procedure, "delete" widget command} {
#      # UTF
#      set x {}
#      .e delete 0 end
#      .e insert end "01234\u4e4e67890"
#      .e delete 6
#      lappend x [.e get]
#      .e delete 0 end
#      .e insert end "012345\u4e4e7890"
#      .e delete 6
#      lappend x [.e get]
#      .e delete 0 end
#      .e insert end "0123456\u4e4e890"
#      .e delete 6
#      lappend x [.e get]
#  } [list "01234\u4e4e7890" "0123457890" "012345\u4e4e890"]


$e->delete(0,"end");
$e->insert("end", "01234567890");
$e->delete(6, 5);
ok($e->get, "01234567890");

$e->delete(0,"end");
$e->insert("end", "01234567890");
$e->configure(-state => 'disabled');
$e->delete(2, 8);
$e->configure(-state => 'normal');
ok($e->get, "01234567890");

eval { $e->get("foo") };
ok($@ =~ /wrong \# args: should be ".* get"/, 1, $@);

eval { $e->icursor };
ok($@ =~ /wrong \# args: should be ".* icursor pos"/, 1, $@);

eval { $e->icursor("foo") };
ok($@ =~ /bad entry index "foo"/, 1, $@);

$e->delete(0,"end");
$e->insert("end", "01234567890");
$e->icursor(4);
ok($e->index('insert'), 4);

eval { $e->in };
ok($@ =~ /Can\'t locate(?: file)? auto\/Tk\/Entry\/in\.al/, 1, $@);

eval { $e->index };
ok($@ =~ /wrong \# args: should be ".* index string"/, 1, $@);

eval { $e->index("foo") };
ok($@ =~ /bad entry index "foo"/, 1, $@);

ok($e->index(0), 0);

#  test entry-3.35 {EntryWidgetCmd procedure, "index" widget command} {
#      # UTF
#      .e delete 0 end
#      .e insert 0 abc\u4e4e\u0153def
#      list [.e index 3] [.e index 4] [.e index end]
#  } {3 4 8}

eval { $e->insert(qw(a)) };
ok($@ =~ /wrong \# args: should be ".* insert index text"/, 1, $@);

eval { $e->insert(qw(a b c)) };
ok($@ =~ /wrong \# args: should be ".* insert index text"/, 1, $@);

eval { $e->insert(qw(foo Text)) };
ok($@ =~ /bad entry index "foo"/, 1, $@);

$e->delete(0,"end");
$e->insert("end", "01234567890");
$e->insert(3, "xxx");
ok($e->get, '012xxx34567890');

$e->delete(0,"end");
$e->insert("end", "01234567890");
$e->configure(qw(-state disabled));
$e->insert(qw(3 xxx));
$e->configure(qw(-state normal));
ok($e->get, "01234567890");

eval { $e->insert(qw(a b c)) };
ok($@ =~ /wrong \# args: should be ".* insert index text"/, 1, $@);

eval { $e->scan(qw(a)) };
ok($@ =~ /wrong \# args: should be ".* scan mark\|dragto x"/, 1, $@);

eval { $e->scan(qw(a b c)) };
ok($@ =~ /wrong \# args: should be ".* scan mark\|dragto x"/, 1, $@);

eval { $e->scan(qw(foobar 20)) };
ok($@ =~ /bad scan option "foobar": must be mark or dragto/, 1, $@);

eval { $e->scan(qw(mark 20.1)) };
ok($@, '');

# This test is non-portable because character sizes vary.

$e->delete(qw(0 end));
$e->update;
$e->insert(end => "This is quite a long string, in fact a ");
$e->insert(end => "very very long string");
$e->scan(qw(mark 30));
$e->scan(qw(dragto 28));
ok($e->index('@0'), 2);

eval {$e->select };
ok($@ =~ /Can\'t locate(?: file)? auto\/Tk\/Entry\/select\.al/, 1, $@);

eval {$e->selection };
ok($@ =~ /wrong \# args: should be ".* selection option \?index\?"/, 1, $@);

eval {$e->selection('foo') };
ok($@ =~ /bad selection option "foo": must be adjust, clear, from, present, range, or to/, 1, $@);

eval { $e->selection("clear", "gorp") };
ok($@ =~ /wrong \# args: should be ".* selection clear"/, 1, $@);

$e->delete(0, "end");
$e->insert("end", "01234567890");
$e->selection("from", 1);
$e->selection("to", 4);
$e->update;
$e->selection("clear");
eval { $mw->SelectionGet };
ok($@ =~ /PRIMARY selection doesn\'t exist or form "(UTF8_)?STRING" not defined/, 1, $@);
ok($mw->SelectionOwner, $e);

eval { $e->selection("present", "foo") };
ok($@ =~ /wrong \# args: should be ".* selection present"/, 1, $@);

$e->delete(0, "end");
$e->insert("end", "01234567890");
$e->selectionFrom(3);
$e->selectionTo(6);
ok($e->selectionPresent,1);

$e->delete(0, "end");
$e->insert("end", "01234567890");
$e->selectionFrom(3);
$e->selectionTo(6);
$e->configure(-exportselection => 0);
ok($e->selection('present'), 1);

$e->configure(-exportselection => 1);

$e->delete(0, "end");
$e->insert("end", "01234567890");
$e->selectionFrom(3);
$e->selectionTo(6);
$e->delete(0,"end");
ok($e->selectionPresent, 0);

eval { $e->selectionAdjust("x") };
ok($@ =~ /bad entry index "x"/, 1, $@);

eval { $e->selection(qw(adjust 2 3)) };
ok($@ =~ /wrong \# args: should be ".* selection adjust index"/, 1, $@);

$e->delete(0, "end");
$e->insert("end", "01234567890");
$e->selectionFrom(1);
$e->selection(qw(to 5));
$e->update;
$e->selectionAdjust(4);
ok($mw->SelectionGet, "123");

$e->delete(0, "end");
$e->insert("end", "01234567890");
$e->selectionFrom(1);
$e->selection(qw(to 5));
$e->update;
$e->selectionAdjust(2);
ok($mw->SelectionGet, "234");

eval { $e->selectionFrom(qw(2 3)) };
ok($@ =~ /wrong \# args: should be ".* selection from index"/, 1, $@);

eval { $e->selection(qw(range 2)) };
ok($@ =~ /wrong \# args: should be ".* selection range start end"/, 1, $@);

eval { $e->selection(qw(range 2 3 4)) };
ok($@ =~ /wrong \# args: should be ".* selection range start end"/, 1, $@);

$e->delete(0, "end");
$e->insert("end", "01234567890");
$e->selectionFrom(1);
$e->selection(qw(to 5));
$e->selection(qw(range 4 4 ));
eval { $e->index("sel.first") };
ok($@ =~ /selection isn\'t in widget/, 1, $@);

$e->delete(0, "end");
$e->insert("end", "0123456789");
$e->selectionFrom(3);
$e->selection(qw(to 7));
$e->selection(qw(range 2 9));
ok($e->index("sel.first"), 2);
ok($e->index("sel.last"), 9);
ok($e->index("anchor"), 3);

$e->delete(qw(0 end));
$e->insert(end => "This is quite a long text string, so long that it ");
$e->insert(end => "runs off the end of the window quite a bit.");

eval { $e->selectionTo(2,3) };
ok($@ =~ /wrong \# args: should be ".* selection to index"/, 1, $@);

$e->xview(5);
ok(join(",", map { substr($_, 0, 8) } $e->xview), "0.053763,0.268817");

eval { $e->xview(qw(gorp)) };
ok($@ =~ /bad entry index "gorp"/, 1, $@);

$e->xview(0);
$e->icursor(10);
$e->xview('insert');
ok(join(",", map { substr($_, 0, 7) } $e->xview), "0.10752,0.32258");

eval { $e->xviewMoveto(qw(foo bar)) };
ok($@ =~ /wrong \# args: should be ".* xview moveto fraction"/, 1, $@);

eval { $e->xview(qw(moveto foo)) };
ok($@ =~ /\'foo\' isn\'t numeric/, 1, $@);

$e->xviewMoveto(0.5);
ok(join(",", map { substr($_, 0, 7) } $e->xview), "0.50537,0.72043");

eval { $e->xviewScroll(24) };
ok($@ =~ /wrong \# args: should be ".* xview scroll number units\|pages"/, 1, $@);

eval { $e->xviewScroll(qw(gorp units)) };
ok($@ =~ /\'gorp\' isn\'t numeric/, 1, $@);

$e->xviewMoveto(0);
$e->xview(qw(scroll 1 pages));
ok(join(",", map { substr($_, 0, 7) } $e->xview), "0.19354,0.40860");

$e->xview(qw(moveto .9));
$e->update;
$e->xview(qw(scroll -2 p));
ok(join(",", map { substr($_, 0, 7) } $e->xview), "0.39784,0.61290");

$e->xview(30);
$e->update;
$e->xview(qw(scroll 2 units));
ok($e->index('@0'), 32);

$e->xview(30);
$e->update;
$e->xview(qw(scroll -1 units));
ok($e->index('@0'), 29);

eval { $e->xviewScroll(23,"foobars") };
ok($@ =~ /bad argument "foobars": must be units or pages/, 1, $@);

eval { $e->xview(qw(eat 23 hamburgers)) };
ok($@ =~ /unknown option "eat": must be moveto or scroll/, 1, $@);

$e->xview(0);
$e->update;
$e->xview(-4);
ok($e->index('@0'), 0);

$e->xview(300);
ok($e->index('@0'), 73);

#  .e insert 10 \u4e4e
#  test entry-3.81 {EntryWidgetCmd procedure, "xview" widget command} {
#      # UTF
#      # If Tcl_NumUtfChars wasn't used, wrong answer would be:
#      # 0.106383 0.117021 0.117021

#      set x {}
#      .e xview moveto .1
#      lappend x [lindex [.e xview] 0]
#      .e xview moveto .11
#      lappend x [lindex [.e xview] 0]
#      .e xview moveto .12
#      lappend x [lindex [.e xview] 0]
#  } {0.0957447 0.106383 0.117021}

eval { $e->gorp };
ok($@ =~ /Can\'t locate(?: file)? auto\/Tk\/Entry\/gorp\.al/, 1, $@);

# The test below doesn't actually check anything directly, but if run
# with Purify or some other memory-allocation-checking program it will
# ensure that resources get properly freed.

eval { $e->destroy };
my $x;
$e = $mw->Entry(-textvariable => \$x, -show => '*')->pack;
$e->insert('end', "Sample text");
$e->update;
$e->destroy;

my $f = $mw->Frame(qw(-width 200 -height 50 -relief raised -bd 2))
    ->pack(-side => "right");

#eval { $e->destroy };
$x = 12345;
$e = $mw->Entry(-textvariable => \$x);
ok($e->get, "12345");

eval { $e->destroy };
$x = "12345";
$e = $mw->Entry(-textvariable => \$x);
my $y = "abcde";
$e->configure(-textvariable => \$y);
$x = 54321;
ok($e->get, "abcde");

eval { $e->destroy };
undef $x;
$e = $mw->Entry;
$e->configure(-textvariable => \$x);
$e->insert(0, "Some text");
ok($x, "Some text");

eval { $e->destroy };
undef $x;
$e = $mw->Entry;
$e->insert(0, "Some text");
$e->configure(-textvariable => \$x);
#ok($x, "Some text"); # XXX does not work with Perl/Tk!

sub override {
    $x = 12345;
}

## XXX traceVariable does not work?
eval { $e->destroy };
undef $x;
$mw->traceVariable(\$x, 'w' => \&override);
$e = $mw->Entry;
$e->configure(-textvariable => \$x);
$e->insert('0', "Some text");
my @result = ($x,$e->get);
undef $x;
ok($result[0], "12345");
ok($result[1], "12345");

eval { $e->destroy };
$e = $mw->Entry(-exportselection => 0)->pack;
$e->insert(qw(end 0123456789));
$sel->selectionFrom(0);
$sel->selectionTo(10);
ok($mw->SelectionGet, "This is so");
$e->selectionFrom(1);
$e->selectionTo(5);
ok($mw->SelectionGet, "This is so");
$e->configure(-exportselection => 1);
ok($mw->SelectionGet, "1234");

eval { $e->destroy };
$e = $mw->Entry->pack;
$e->insert(qw(end 0123456789));
$e->selectionFrom(1);
$e->selectionTo(5);
$e->configure(-exportselection => 0);
eval { $mw->SelectionGet };
ok($@ =~ /PRIMARY selection doesn\'t exist or form "(UTF8_)?STRING" not defined/, 1, $@);
ok($e->index("sel.first"), 1);
ok($e->index("sel.last"), 5);

eval { $e->destroy };
$e = $mw->Entry(-font => $fixed, qw(-width 4 -xscrollcommand), \&scroll)->pack;
$e->insert(qw(end 01234567890));
$e->update;
$e->configure(qw(-width 5));
ok(join(",", map { substr($_, 0, 8) } @scrollInfo), "0,0.363636");

eval { $e->destroy };

$e = $mw->Entry(-width => 0)->pack;
$e->insert(end => "0123");
$e->update;
$e->configure(-font => $big);
$e->update;
skip($skip_wm_test, $e->geometry, qr/62x3\d\+0\+0/);

eval { $e->destroy };
$e = $mw->Entry(-font => $fixed, -bd => 2, -relief => "raised")->pack;
$e->insert(end => "0123");
$e->update;
ok($e->index('@10'), 0);
ok($e->index('@11'), 0);
ok($e->index('@12'), 1);
ok($e->index('@13'), 1);

eval { $e->destroy };
$e = $mw->Entry(-font => $fixed, -bd => 2, -relief => "flat")->pack;
$e->insert(end => "0123");
$e->update;
ok($e->index('@10'), 0);
ok($e->index('@11'), 0);
ok($e->index('@12'), 1);
ok($e->index('@13'), 1);

# If "0" in selected font had 0 width, caused divide-by-zero error.

eval { $e->destroy };
$e = $mw->Entry(-font => '{open look glyph}')->pack;
$e->scan('dragto', 30);
$e->update;

# No tests for DisplayEntry.

eval { $e->destroy };
$e = $mw->Entry(-font => $fixed, -bd => 2, -relief => "raised", -width => 20, -highlightthickness => 3)->pack;
$e->insert("end", "012\t45");
$e->update;
ok($e->index('@61'), 3);
ok($e->index('@62'), 4);

eval { $e->destroy };
$e = $mw->Entry(-font => $fixed, qw(-bd 2 -relief raised -width 20 -justify center -highlightthickness 3))->pack;
$e->insert("end", "012\t45");
$e->update;
ok($e->index('@96'), 3);
ok($e->index('@97'), 4);

eval { $e->destroy };
$e = $mw->Entry(-font => $fixed, qw(-bd 2 -relief raised -width 20 -justify right -highlightthickness 3))->pack;
$e->insert("end", "012\t45");
$e->update;
ok($e->index('@131'), 3);
ok($e->index('@132'), 4);

eval { $e->destroy };
$e = $mw->Entry(-font => $fixed, qw(-bd 2 -relief raised -width 5))->pack;
$e->insert(qw(end 01234567890));
$e->update;
$e->xview(6);
ok($e->index('@0'), 6);

eval { $e->destroy };
$e = $mw->Entry(-font => $fixed, qw(-bd 2 -relief raised -width 5))->pack;
$e->insert(qw(end 01234567890));
$e->update;
$e->xview(7);
ok($e->index('@0'), 6);

eval { $e->destroy };
$e = $mw->Entry(-font => $fixed, qw(-bd 2 -relief raised -width 10))->pack;
$e->insert(qw(end), "01234\t67890");
$e->update;
$e->xview(3);
ok($e->index('@39'), 5);
ok($e->index('@40'), 6);

eval { $e->destroy };
$e = $mw->Entry(-font => $big, qw(-bd 3 -relief raised -width 5))->pack;
$e->insert(qw(end), "01234567");
$e->update;
skip($skip_font_test, $e->reqwidth, 77);
skip($skip_font_test, $e->reqheight, 39);

eval { $e->destroy };
$e = $mw->Entry(-font => $big, qw(-bd 3 -relief raised -width 0))->pack;
$e->insert(qw(end), "01234567");
$e->update;
skip($skip_font_test, $e->reqwidth, 116);
skip($skip_font_test, $e->reqheight, 39);

eval { $e->destroy };
$e = $mw->Entry(-font => $big, qw(-bd 3 -relief raised -width 0 -highlightthickness 2))->pack;
$e->update;
skip($skip_font_test, $e->reqwidth, 25);
skip($skip_font_test, $e->reqheight, 39);

eval { $e->destroy };
$e = $mw->Entry(qw(-bd 1 -relief raised -width 0 -show .))->pack;
$e->insert(0, "12345");
$e->update;
skip($skip_font_test, $e->reqwidth, 23);
$e->configure(-show => 'X');
skip($skip_font_test, $e->reqwidth, 53);
#$e->configure(-show => '');
#skip($skip_font_test, $e->reqwidth, 43);

eval { $e->destroy };
$e = $mw->Entry(qw(-bd 1 -relief raised -width 0 -show .),
		-font => 'helvetica 12')->pack;
$e->insert(0, "12345");
$e->update;
skip($skip_font_test, $e->reqwidth, 8+5*$mw->fontMeasure("helvetica 12", "."));
$e->configure(-show => 'X');
skip($skip_font_test, $e->reqwidth, 8+5*$mw->fontMeasure("helvetica 12", "X"));
#$e->configure(-show => '');
#ok($e->reqwidth, 8+$mw->fontMeasure("helvetica 12", "12345"));

eval { $e->destroy };
my $contents;
$e = $mw->Entry(qw(-width 10 -font), $fixed, -textvariable => \$contents,
		-xscrollcommand => \&scroll)->pack;
$e->focus;
$e->delete(0, "end");
$e->insert(0, "abcde");
$e->insert(2, "XXX");
$e->update;
ok($e->get, "abXXXcde");
ok($contents, "abXXXcde");
ok(join(" ", @scrollInfo), "0 1");

$e->delete(0, "end");
$e->insert(0, "abcde");
$e->insert(500, "XXX");
$e->update;
ok($e->get, "abcdeXXX");
ok($contents, "abcdeXXX");
ok(join(" ", @scrollInfo), "0 1");

$e->delete(0, "end");
$e->insert(0, "0123456789");
$e->selectionFrom(2);
$e->selectionTo(6);
$e->insert(2, "XXX");
ok($e->index("sel.first"), 5);
ok($e->index("sel.last"), 9);
$e->selectionTo(8);
ok($e->index("sel.first"), 5);
ok($e->index("sel.last"), 8);

$e->delete(0, "end");
$e->insert(0, "0123456789");
$e->selectionFrom(2);
$e->selectionTo(6);
$e->insert(3, "XXX");
ok($e->index("sel.first"), 2);
ok($e->index("sel.last"), 9);
$e->selectionTo(8);
ok($e->index("sel.first"), 2);
ok($e->index("sel.last"), 8);

$e->delete(0, "end");
$e->insert(0, "0123456789");
$e->selectionFrom(2);
$e->selectionTo(6);
$e->insert(5, "XXX");
ok($e->index("sel.first"), 2);
ok($e->index("sel.last"), 9);
$e->selectionTo(8);
ok($e->index("sel.first"), 2);
ok($e->index("sel.last"), 8);

$e->delete(0, "end");
$e->insert(0, "0123456789");
$e->selectionFrom(2);
$e->selectionTo(6);
$e->insert(6, "XXX");
ok($e->index("sel.first"), 2);
ok($e->index("sel.last"), 6);
$e->selectionTo(5);
ok($e->index("sel.first"), 2);
ok($e->index("sel.last"), 5);

$e->delete(0, "end");
$e->insert(0, "0123456789");
$e->icursor(4);
$e->insert(4, "XXX");
ok($e->index("insert"), 7);

$e->delete(0, "end");
$e->insert(0, "0123456789");
$e->icursor(4);
$e->insert(5, "XXX");
ok($e->index("insert"), 4);

$e->delete(0, "end");
$e->insert(0, "This is a very long string");
$e->update;
$e->xview(4);
$e->insert(qw(3 XXX));
ok($e->index('@0'), 7);

$e->delete(0, "end");
$e->insert(0, "This is a very long string");
$e->update;
$e->xview(4);
$e->insert(qw(4 XXX));
ok($e->index('@0'), 4);

$e->delete(0, "end");
$e->insert(0, "xyzzy");
$e->update;
$e->insert(2, "00");
## XXX ok($e->reqwidth, 59);

$e->delete(qw(0 end));
$e->insert(qw(0 abcde));
$e->delete(qw(2 4));
$e->update;
ok($e->get, "abe");
ok($contents, "abe");
ok($scrollInfo[0], 0);
ok($scrollInfo[1], 1);

$e->delete(qw(0 end));
$e->insert(qw(0 abcde));
$e->delete(qw(-2 2));
$e->update;
ok($e->get, "cde");
ok($contents, "cde");
ok($scrollInfo[0], 0);
ok($scrollInfo[1], 1);

$e->delete(qw(0 end));
$e->insert(qw(0 abcde));
$e->delete(qw(3 1000));
$e->update;
ok($e->get, "abc");
ok($contents, "abc");
ok($scrollInfo[0], 0);
ok($scrollInfo[1], 1);

$e->delete(qw(0 end));
$e->insert(qw(0 0123456789abcde));
$e->selection(qw(from 3));
$e->selection(qw(to 8));
$e->delete(qw(1 3));
$e->update;
ok($e->index("sel.first"), 1);
ok($e->index("sel.last"), 6);
$e->selectionTo(5);
ok($e->index("sel.first"), 1);
ok($e->index("sel.last"), 5);

$e->delete(qw(0 end));
$e->insert(qw(0 0123456789abcde));
$e->selection(qw(from 3));
$e->selection(qw(to 8));
$e->delete(qw(1 4));
$e->update;
ok($e->index("sel.first"), 1);
ok($e->index("sel.last"), 5);
$e->selectionTo(4);
ok($e->index("sel.first"), 1);
ok($e->index("sel.last"), 4);

$e->delete(qw(0 end));
$e->insert(qw(0 0123456789abcde));
$e->selection(qw(from 3));
$e->selection(qw(to 8));
$e->delete(qw(1 7));
$e->update;
ok($e->index("sel.first"), 1);
ok($e->index("sel.last"), 2);
$e->selectionTo(5);
ok($e->index("sel.first"), 1);
ok($e->index("sel.last"), 5);

$e->delete(qw(0 end));
$e->insert(qw(0 0123456789abcde));
$e->selection(qw(from 3));
$e->selection(qw(to 8));
$e->delete(qw(1 8));
eval { $e->index("sel.first") };
ok($@ =~ /selection isn\'t in widget/, 1, $@);

$e->delete(qw(0 end));
$e->insert(qw(0 0123456789abcde));
$e->selection(qw(from 3));
$e->selection(qw(to 8));
$e->delete(qw(3 7));
$e->update;
ok($e->index("sel.first"), 3);
ok($e->index("sel.last"), 4);
$e->selectionTo(8);
ok($e->index("sel.first"), 3);
ok($e->index("sel.last"), 8);

$e->delete(qw(0 end));
$e->insert(qw(0 0123456789abcde));
$e->selection(qw(from 3));
$e->selection(qw(to 8));
$e->delete(qw(3 8));
eval { $e->index("sel.first") };
ok($@ =~ /selection isn\'t in widget/, 1, $@);

$e->delete(qw(0 end));
$e->insert(qw(0 0123456789abcde));
$e->selection(qw(from 8));
$e->selection(qw(to 3));
$e->delete(qw(5 8));
$e->update;
ok($e->index("sel.first"), 3);
ok($e->index("sel.last"), 5);
$e->selectionTo(8);
ok($e->index("sel.first"), 5);
ok($e->index("sel.last"), 8);

$e->delete(qw(0 end));
$e->insert(qw(0 0123456789abcde));
$e->selection(qw(from 8));
$e->selection(qw(to 3));
$e->delete(qw(8 10));
$e->update;
ok($e->index("sel.first"), 3);
ok($e->index("sel.last"), 8);
$e->selectionTo(4);
ok($e->index("sel.first"), 4);
ok($e->index("sel.last"), 8);

$e->delete(qw(0 end));
$e->insert(qw(0 0123456789abcde));
$e->icursor(4);
$e->delete(qw(1 4));
ok($e->index("insert"), 1);

$e->delete(qw(0 end));
$e->insert(qw(0 0123456789abcde));
$e->icursor(4);
$e->delete(qw(1 5));
ok($e->index("insert"), 1);

$e->delete(qw(0 end));
$e->insert(qw(0 0123456789abcde));
$e->icursor(4);
$e->delete(qw(4 6));
ok($e->index("insert"), 4);

$e->delete(qw(0 end));
$e->insert(qw(0), "This is a very long string");
$e->xview(4);
$e->delete(qw(1 4));
ok($e->index('@0'), 1);

$e->delete(qw(0 end));
$e->insert(qw(0), "This is a very long string");
$e->xview(4);
$e->delete(qw(1 5));
ok($e->index("\@0"), 1);

$e->delete(qw(0 end));
$e->insert(qw(0), "This is a very long string");
$e->xview(4);
$e->delete(qw(4 6));
ok($e->index("\@0"), 4);

$e->configure(qw(-width 0));

$e->delete(qw(0 end));
$e->insert(0, "xyzzy");
$e->update;
$e->delete(qw(2 4));
ok($e->reqwidth, 31);

eval { $e->destroy };

sub _override2 {
    $x = "12345";
}
undef $x;
$mw->traceVariable(\$x, 'w', \&_override2);
$e = $mw->Entry(-textvariable => \$x);
$e->insert(0, "foo");
ok($x, 12345);
ok($e->get, 12345);
undef $x;

Tk::catch {$e->destroy};
$e = $mw->Entry->pack;
$e->configure(-width => 0);

$x = "abcde";
$y = "ab";
$e->configure(-textvariable => \$x);
$e->update;
$e->configure(-textvariable => \$y);
$e->update;
ok($e->get, "ab");
ok($e->reqwidth, 24);

$mw->traceVdelete(\$x); # XXX why?

Tk::catch {$e->destroy};
$e = $mw->Entry(-textvariable => \$x);
$e->insert(0, "abcdefghjklmnopqrstu");
$e->selection(qw(range 4 10));
$x = "a";
eval { $e->index("sel.first") };
ok($@ =~ /selection isn\'t in widget/, 1, $@);

Tk::catch {$e->destroy};
$e = $mw->Entry(-textvariable => \$x);
$e->insert(0, "abcdefghjklmnopqrstu");
$e->selection(qw(range 4 10));
$x = "abcdefg";
ok($e->index("sel.first"), 4);
ok($e->index("sel.last"), 7);

Tk::catch {$e->destroy};
$e = $mw->Entry(-textvariable => \$x);
$e->insert(0, "abcdefghjklmnopqrstu");
$e->selection(qw(range 4 10));
$x = "abcdefghijklmn";
ok($e->index("sel.first"), 4);
ok($e->index("sel.last"), 10);

Tk::catch {$e->destroy};
$e = $mw->Entry(-textvariable => \$x)->pack;
$e->insert(0, "abcdefghjklmnopqrstu");
$e->xview(10);
$e->update;
$x = "abcdefg";
$e->update;
ok($e->index('@0'), 0);

Tk::catch {$e->destroy};
$e = $mw->Entry(-font => $fixed, -width => 10, -textvariable => \$x)->pack;
$e->insert(0, "abcdefghjklmnopqrstu");
$e->xview(10);
$e->update;
$x = "1234567890123456789012";
$e->update;
ok($e->index('@0'), 10);

Tk::catch {$e->destroy};
$e = $mw->Entry(-font => $fixed, -width => 10, -textvariable => \$x)->pack;
$e->insert(0, "abcdefghjklmnopqrstu");
$e->icursor(5);
$x = "123";
ok($e->index("insert"), 3);

Tk::catch {$e->destroy};
$e = $mw->Entry(-font => $fixed, -width => 10, -textvariable => \$x)->pack;
$e->insert(0, "abcdefghjklmnopqrstuvwxyz");
$e->icursor(5);
$x = "123456";
ok($e->index("insert"), 5);

Tk::catch {$e->destroy};
$e = $mw->Entry;
$e->insert(0, "abcdefg");
$e->destroy;
$mw->update;

$_->destroy for ($mw->children);
my $e1 = $mw->Entry(-fg => '#112233');
ok(($mw->children)[0], $e1);
$e1->destroy;
ok(scalar($mw->children), undef); # XXX why not 0?

$e = $mw->Entry(-font => $fixed, qw(-width 5 -bd 2 -relief sunken))->pack;
$e->insert(qw(0 012345678901234567890));
$e->xview(4);
$e->update;
ok($e->index("end"), 21);

eval { $e->index("abogus") };
ok($@ =~ /bad entry index "abogus"/, 1, $@);

$e->selection(qw(from 1));
$e->selection(qw(to 6));
ok($e->index(qw(anchor)), 1);

$e->selection(qw(from 4));
$e->selection(qw(to 1));
ok($e->index(qw(anchor)), 4);

$e->selection(qw(from 3));
$e->selection(qw(to 15));
$e->selection(qw(adjust 4));
ok($e->index(qw(anchor)), 15);

eval { $e->index("ebogus") };
ok($@ =~ /bad entry index "ebogus"/, 1, $@);

$e->icursor(2);
ok($e->index('insert'), 2);

eval { $e->index("ibogus") };
ok($@ =~ /bad entry index "ibogus"/, 1, $@);

$e->selectionFrom(1);
$e->selectionTo(6);
ok($e->index("sel.first"), 1);
ok($e->index("sel.last"), 6);

$mw->SelectionClear($e);

if ($^O ne 'MSWin32') {
    # On unix, when selection is cleared, entry widget's internal
    # selection range is reset.

    eval { $e->index("sel.first") };
    skip("Test only for MSWin32", $@ =~ /selection isn\'t in widget/, 1, $@) for (1..2);

} else {
    # On mac and pc, when selection is cleared, entry widget remembers
    # last selected range.  When selection ownership is restored to
    # entry, the old range will be rehighlighted.

    ok($e->getSelected, '12345');
    ok($e->index("sel.first"), 1);
}

if ($^O ne 'MSWin32') {
    eval { $e->index("sbogus") };
    ok($@ =~ /selection isn\'t in widget/, 1, $@);
} else {
    eval { $e->index("sbogus") };
    ok($@ =~ /bad entry index "sbogus"/, 1, $@);
}

eval { $e->index('@xyz') };
ok($@ =~ /bad entry index "\@xyz"/, 1, $@);

ok($e->index('@4'), 4);
ok($e->index('@11'), 4);
ok($e->index('@12'), 5);
ok($e->index('@' . ($e->width-6)), 8);
ok($e->index('@' . ($e->width-5)), 9);
ok($e->index('@1000'), 9);

eval { $e->index('1xyz') };
ok($@ =~ /bad entry index "1xyz"/, 1, $@);

ok($e->index(-10), 0);
ok($e->index(12), 12);
ok($e->index(49), 21);

Tk::catch { $e->destroy };
$e = $mw->Entry(-show => ".");
$e->insert(qw(0 XXXYZZY));
$e->pack;
$e->update;
skip($skip_font_test, $e->index('@7'), 0);
skip($skip_font_test, $e->index('@8'), 1);

# XXX Still need to write tests for EntryScanTo and EntrySelectTo.

$x = "";
for my $i (1 .. 500) {
    $x .= "This is line $i, out of 500\n";
}

Tk::catch { $e->destroy };
$e = $mw->Entry;
$e->insert(end => "This is a test string");
$e->selection(qw(from 1));
$e->selection(qw(to 18));
ok($mw->SelectionGet, "his is a test str");

Tk::catch { $e->destroy };
$e = $mw->Entry(-show => "*");
$e->insert(end => "This is a test string");
$e->selection(qw(from 1));
$e->selection(qw(to 18));
ok($mw->SelectionGet, "*****************");

Tk::catch { $e->destroy };
$e = $mw->Entry;
$e->insert("end", $x);
$e->selectionFrom(0);
$e->selectionTo("end");
ok($mw->SelectionGet, $x);

Tk::catch { $e->destroy };
$e = $mw->Entry;
$e->insert(0, "Text");
$e->selectionFrom(0);
$e->selectionTo(4);
ok($mw->SelectionGet, "Text");
$mw->SelectionClear;
$e->selectionFrom(0);
$e->selectionTo(4);
ok($mw->SelectionGet, "Text");

# No tests for EventuallyRedraw.

Tk::catch {$e->destroy};
$e = $mw->Entry(qw(-width 10 -xscrollcommand), \&scroll)->pack;
$e->update;

$e->delete(qw(0 end));
$e->insert(qw(0 .............................));
skip($skip_font_test || $skip_wm_test, join(" ", map { substr($_, 0, 8) } $e->xview), "0 0.827586");

$e->delete(qw(0 end));
$e->insert(qw(0 XXXXXXXXXXXXXXXXXXXXXXXXXXXXX));
my $Xw = join(" ", map { substr($_, 0, 8) } $e->xview);

$e->configure(-show => 'X');
$e->delete(qw(0 end));
$e->insert(qw(0 .............................));
ok(join(" ", map { substr($_, 0, 8) } $e->xview), $Xw);

$e->configure(-show => '.');
$e->delete(qw(0 end));
$e->insert(qw(0 XXXXXXXXXXXXXXXXXXXXXXXXXXXXX));
skip($skip_font_test || $skip_wm_test, join(" ", map { substr($_, 0, 8) } $e->xview), "0 0.827586");

$e->configure(-show => "");
$e->delete(qw(0 end));
ok(($e->xview)[$_], $_) for (0 .. 1);

Tk::catch {$e->destroy};
$e = $mw->Entry(qw(-width 10 -xscrollcommand), \&scroll, -font => $fixed)->pack;
$e->update;

$e->delete(qw(0 end));
$e->insert(qw(0 123));
$e->update;
ok(join(" ",@scrollInfo),"0 1");

$e->delete(qw(0 end));
$e->insert(qw(0 0123456789abcdef));
$e->xview(3);
$e->update;
skip($skip_font_test || $skip_wm_test, join(" ",@scrollInfo),"0.1875 0.8125");

$e->delete(qw(0 end));
$e->insert(qw(0 abcdefghijklmnopqrs));
$e->xview(6);
$e->update;
skip($skip_font_test || $skip_wm_test, join(" ",map { sprintf "%8f", $_ } @scrollInfo),"0.315789 0.842105");

Tk::catch {$e->destroy};
my $err;
eval {
    sub Tk::Error { $err = $_[1] }
    $e = $mw->Entry(qw(-width 5 -xscrollcommand thisisnotacommand))->pack;
    $e->update;
};
ok($err =~ /Undefined subroutine &main::thisisnotacommand/);

#      pack .e
#      update
#      rename bgerror {}
#      list $x $errorInfo
#  } {{invalid command name "thisisnotacommand"} {invalid command name "thisisnotacommand"
#      while executing
#  "thisisnotacommand 0 1"
#      (horizontal scrolling command executed by entry)}}

## XXX no interp hidden with Perl/Tk?
#set l [interp hidden]
#eval destroy [winfo children .]
#  test entry-18.1 {Entry widget vs hiding} {
#      catch {destroy .e}
#      entry .e
#      interp hide {} .e
#      destroy .e
#      list [winfo children .] [interp hidden]
#  } [list {} $l]

######################################################################
# Additional tests

$e->validate; # check whether validate method is defined
ok(1);

__END__

