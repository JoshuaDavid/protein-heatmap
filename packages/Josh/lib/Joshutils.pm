package Joshutils;
use strict;
use warnings;
use Exporter qw(import);
use Scalar::Util qw(reftype);

sub head {
    my ($head, @tail) = @_;
    return $head;
}

sub tail {
    my ($head, @tail) = @_;
    return @tail;
}

sub say {
    print @_;
    print "\n";
}

sub trim {
    my ($str) = @_;
    $str =~ s/^\s+|\s+$//g; # Remove whitespace at beginning and end.
    return $str;
}

sub json_encode {
    my ($obj, $indent) = @_;
    return '""' if not defined $obj;
    $indent ||= 0;
    return '"TOO MUCH RECURSION"' if $indent > 10;
    my $encoded = "";
    sub array_enc {
        my ($encoded, $indent, $obj) = @_;
        $encoded .= "\n" . ("\t" x $indent) . '[';
        $indent += 1;
        for my $val (@$obj) {
            $encoded .= "\n" . ("\t" x $indent);
            $encoded .= json_encode($val, $indent);
            $encoded .= ",";
        }
        $indent -= 1;
        $encoded =~ s/,$//g; # Strip trailing comma
        $encoded .= "\n" . ("\t" x $indent) . ']';
    }
    sub hash_enc {
        my ($encoded, $indent, $obj) = @_;
        $encoded .= "\n" . ("\t" x $indent) . '{';
        $indent += 1;
        for my $key (keys %$obj) {
            $encoded .= "\n" . ("\t" x $indent);
            $encoded .= "\"$key\": ";
            $encoded .= json_encode($$obj{$key}, $indent);
            $encoded .= ",";
        }
        $indent -= 1;
        $encoded =~ s/,$//g; # Strip trailing comma
        $encoded .= "\n" . ("\t" x $indent) . '}';
    }
    if     (defined reftype $obj) {
        if     (reftype $obj eq "ARRAY") {
            $encoded .= array_enc($encoded, $indent, $obj);
        } elsif(reftype $obj eq "HASH")  {
            $encoded .= hash_enc($encoded, $indent, $obj);
        }
    }elsif (ref $obj eq "ARRAY") {
        $encoded .= array_enc($encoded, $indent, $obj);
    } elsif(ref $obj eq "HASH")  {
        $encoded .= hash_enc($encoded, $indent, $obj);
    } else {
        if(!($obj & ~$obj)) {
            # Is this thing a number? If so, then it and its bitwise negation
            # will be false. No need to process numbers -- just return them.
            $encoded = $obj;
        } else {
            # It's a string
            my $quoted = $obj;
            $quoted =~ s/\\/\\\\/g; # Escape backslashes
            $quoted =~ s/\"/\\\"/g; # Escape quotes
            $encoded = "\"$quoted\"";
        }
    }
    $encoded = trim($encoded);
    if(length($encoded) == 0) {
        $encoded = '""';
    }
    if($indent == 0) {
        $encoded .= "\n";
    }
    $encoded =~ s/\[\s*\]/\[ \]/g;
    $encoded =~ s/\{\s*\}/\{ \}/g;
    return $encoded;
}

sub file_get_contents {
    my ($filename) = @_;
    open FILE, "<$filename";
    my $content = join "", <FILE>;
    $content =~ s/\r\n/\n/g;
    $content =~ s/\r/\n/g;
    return $content;
}

sub prompt {
    my ($message) = @_;
    say $message;
    my $response = <STDIN>;
    return $response;
}

sub confirm {
    my ($message) = @_;
    say $message;
    my $response = <STDIN>;
    return $response =~ m/^y/i;
}

sub update_on_ratio {
    my ($prior, $odds) = @_;
    return $prior * $odds;
}

# Given a number, return the english string that describes its position in a count
# e.g. 1 returns first, 2 returns second, 987654321 returns 
# nine hundred eighty seven million six hundred fifty four thousand three hundred twenty first
# and so on.
sub nth {
    my ($n, $is_part) = @_;
    my $nths = [ 
        qw(zeroeth first second third fourth fifth sixth seventh eight ninth tenth),
        qw(eleventh twelfth thirteenth fourteenth fifteenth sixteenth seventeenth),
        qw(eighteenth nineteenth)
    ];
    my $ones = [ 
        qw(zero one two three four five six seven eight nine),
        qw(ten eleven twelve thirteen fourteen fifteen sixteen seventeen),
        qw(eighteen nineteen twenty)
    ];
    my $tens = [ qw(zero ten twenty thirty forty fifty sixty seventy eighty ninety) ];
    my $nth = "";
    if ($n >= 1e15 or $n <= 0) {
        return $n . "th";
    }
    if ($n >= 1e12) {
        my $t = $n / 1e12 | 0;
        $nth .= nth($t, 1) . " trillion ";
        $n %= 1e12;
    }
    if ($n >= 1e9) {
        my $b = $n / 1e9 | 0;
        $nth .= nth($b, 1) . " billion ";
        $n %= 1e9;
    }
    if ($n >= 1e6) {
        my $m = $n / 1e6 | 0;
        $nth .= nth($m, 1) . " million ";
        $n %= 1e6;
    }
    if ($n >= 1e3) {
        my $t = $n / 1e3 | 0;
        $nth .= nth($t, 1) . " thousand ";
        $n %= 1e3;
    }
    if ($n >= 100) {
        my $h = $n / 100 | 0;
        $nth .= "$$ones[$h] hundred ";
    }
    if ($n % 100 > 20) {
        my $t = ($n % 100) / 10 | 0;
        $nth .= "$$tens[$t] ";
        my $o = $n % 10;
        if($is_part) {
            $nth .= $$ones[$o] if($o > 0);
        } else {
            $nth .= $$nths[$o] if($o > 0);
        }
    } else {
        my $o = $n % 20;
        if($is_part) {
            $nth .= $$ones[$o] if($o > 0);
        } else {
            $nth .= $$nths[$o] if($o > 0);
        }
    }
    if($is_part) {
        return $nth;
    } else {
        $nth = trim $nth;
        $nth =~ s/y$/ieth/;
        return $nth;
    }
}

no strict;
@EXPORT    = qw(head tail say trim json_encode file_get_contents prompt confirm nth);
1; # We must return a true value here for the module to load.
