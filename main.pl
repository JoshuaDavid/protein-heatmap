use strict;
use warnings;
use Cwd qw(abs_path getcwd);
# $fp is the path to the current script's directory -- the folder hierarchy is
# stable relative to $fp, so this script will work when called from anywhere.
my $fp;
BEGIN { 
    $fp = __FILE__;
    if ($fp =~ m/\//g) {
        $fp =~ s/\/[^\/]*$/\//g;
    } else {
        $fp = '.';
    }
}
use lib "$fp/packages/Josh/lib";
use Joshutils;
use lib "$fp/packages/JSON-2.90/lib";
use JSON;
use lib "$fp/packages/Bio-PDB-Structure/lib";
use Bio::PDB::Structure;
use lib "$fp/packages/Imager/lib";
use Imager;
use Imager::Fill;
use lib "$fp/packages/Tk/lib";
use Tk;
use Tk::Canvas;

my $progress = 0;

sub max {
    my @args = @_;
    return undef unless length @args;
    my $max = -'inf';
    for my $arg (@args) {
        if($arg > $max) {
            $max = $arg;
        }
    }
    return $max;
}
sub min {
    my @args = @_;
    my $min = undef;
    for my $arg (@args) {
        if($arg < $min) {
            $min = $arg;
        }
    }
    return $min;
}
sub getBounds {
    my ($molecule) = @_;
    my $bounds = {
        xmin => 0+"Infinity", xmax => 0-"Infinity",
        ymin => 0+"Infinity", ymax => 0-"Infinity",
        zmin => 0+"Infinity", zmax => 0-"Infinity" 
    };
    foreach my $atom (@$molecule) {
        $$bounds{'xmin'} = $$atom{'X'} if $$atom{'X'} < $$bounds{'xmin'};
        $$bounds{'xmax'} = $$atom{'X'} if $$atom{'X'} > $$bounds{'xmax'};
        $$bounds{'ymin'} = $$atom{'Y'} if $$atom{'Y'} < $$bounds{'ymin'};
        $$bounds{'ymax'} = $$atom{'Y'} if $$atom{'Y'} > $$bounds{'ymax'};
        $$bounds{'zmin'} = $$atom{'Z'} if $$atom{'Z'} < $$bounds{'zmin'};
        $$bounds{'zmax'} = $$atom{'Z'} if $$atom{'Z'} > $$bounds{'zmax'};
    }
    return $bounds;
}
sub cubeSphereIntersect {
    # Cube x, y, z, size, Sphere x, y, z, radius
    my ($cx, $cy, $cz, $cs, $sx, $sy, $sz, $sr) = @_;
    #say "Cube   x: $cx y: $cy z: $cz size:   $cs";
    #say "Sphere x: $sx y: $sy z: $sz radius: $sr";
    my $d2 = $sr ** 2;
    #say "d ** 2 == $d2";
    if   ($sx < $cx)       { $d2 -= ($sx - $cx      ) ** 2; }
    elsif($sx > $cx + $cs) { $d2 -= ($sx - $cx - $cs) ** 2; }
    #say "d ** 2 == $d2";
    if   ($sy < $cy)       { $d2 -= ($sy - $cy      ) ** 2; }
    elsif($sy > $cy + $cs) { $d2 -= ($sy - $cy - $cs) ** 2; }
    #say "d ** 2 == $d2";
    if   ($sz < $cz)       { $d2 -= ($sz - $cz      ) ** 2; }
    elsif($sz > $cz + $cs) { $d2 -= ($sz - $cz - $cs) ** 2; }
    #say "d ** 2 == $d2";
    #die $d2 if(rand() < 0.000025);
    return $d2 >= 0;
}
sub makeCanvas {
    my $window = MainWindow->new();
    $window->minsize(500, 500);
    $window->title($ARGV[0]);
    my $canvas = $window->Canvas(-background => "black", -width => 500, -height => 500);
    $canvas->pack();
    return $canvas;
}
sub addCircle {
    my ($canvas, $x, $y, $r, $color) = @_;
    $canvas->createOval($x - $r, $y - $r, $x + $r, $y + $r, 
        -fill => $color, -width => 0);
}
sub addCube {
    my ($canvas, $x, $y, $z, $scale, $brightness) = @_;
    $brightness &= 255; # Cap at 255
    sub px {
        my ($x, $y, $z, $scale) = @_;
        $x = int($x);
        $y = int($y);
        $z = int($z);
        my ($px, $py);
        $px = $x * $scale + $z * $scale / 2;
        $py = $y * $scale + $z * $scale / 2;
        return ($px, $py);
    }
    my $lc = sprintf('%.2x', int 2 / 4 * $brightness); # Left color
    my $tc = sprintf('%.2x', int 3 / 4 * $brightness); # Top color
    my $fc = sprintf('%.2x', int 4 / 4 * $brightness); # Front color
    # Top face
    $canvas->createPolygon(px($x+0,$y+0,$z+0,$scale), px($x+1,$y+0,$z+0,$scale),
                           px($x+1,$y+0,$z+1,$scale), px($x+0,$y+0,$z+1,$scale),
                           -fill => "#$tc$tc$tc", -width => 0);
    # Left face
    $canvas->createPolygon(px($x+0,$y+0,$z+0,$scale), px($x+0,$y+0,$z+1,$scale),
                           px($x+0,$y+1,$z+1,$scale), px($x+0,$y+1,$z+0,$scale),
                           -fill => "#$lc$lc$lc", -width => 0);
    # Front face
    $canvas->createPolygon(px($x+0,$y+0,$z+1,$scale), px($x+1,$y+0,$z+1,$scale),
                           px($x+1,$y+1,$z+1,$scale), px($x+0,$y+1,$z+1,$scale),
                           -fill => "#$fc$fc$fc", -width => 0);
}
# Get the radius of the atom in angstroms from the atomic symbol (e.g. H, C, Li)
sub radius_of {
    my ($atom) = @_;
    my $radii = {
        'H'  => 0.37, 'Li' => 1.52, 'Na' => 1.86, 'K'  => 2.27, 'Rb' => 2.47,
        'Be' => 1.13, 'Mg' => 1.60, 'Ca' => 1.97, 'Sr' => 2.15, 'Sc' => 1.61,
        'Y'  => 1.78, 'Ti' => 1.45, 'Zr' => 1.59, 'V'  => 1.31, 'Nb' => 1.43,
        'Cr' => 1.25, 'Mo' => 1.36, 'Mn' => 1.37, 'Tc' => 1.35, 'Fe' => 1.24,
        'Ru' => 1.32, 'Co' => 1.25, 'Rh' => 1.34, 'Ni' => 1.25, 'Pd' => 1.38,
        'Cu' => 1.28, 'Ag' => 1.44, 'Zn' => 1.34, 'Cd' => 1.49, 'B'  => 0.88,
        'Al' => 1.43, 'Ga' => 1.22, 'In' => 1.63, 'C'  => 0.77, 'Si' => 1.17,
        'Ge' => 1.22, 'Sn' => 1.40, 'N'  => 0.75, 'P'  => 1.10, 'As' => 1.21,
        'Sb' => 1.41, 'O'  => 0.73, 'S'  => 1.04, 'Se' => 1.17, 'Te' => 1.43,
        'F'  => 0.71, 'Cl' => 0.99, 'Br' => 1.14, 'I'  => 1.33, 'He' => 0.32,
        'Ne' => 0.69, 'Ar' => 0.97, 'Kr' => 1.10, 'Xe' => 1.30 
    };
    my $radius = $$radii{$atom->name} || 1;
    return $radius;
}
sub color_of {
    my ($atom) = @_;
    my $atom_colors = {
        'O' => 'red',
        'N' => 'blue',
        'C' => 'black',
        'H' => 'white',
        'S' => 'yellow',
        'P' => 'purple'
    };
    my $color = $$atom_colors{$atom->name};
    return $color;
}
sub xy_of {
    my ($atom, $bounds, $scale) = @_;
    my $x = $atom->x - $$bounds{xmin};
    my $y = $atom->y - $$bounds{ymin};
    $x *= $scale;
    $y *= $scale;
    return {x => $x, y => $y};
}
sub probe_bounds {
    my ($molecule, $probesize) = @_;
    my $bounds = getBounds($molecule);
    my $width  = 0 | $$bounds{'xmax'} - $$bounds{'xmin'};
    my $height = 0 | $$bounds{'ymax'} - $$bounds{'ymin'};
    my $depth  = 0 | $$bounds{'zmax'} - $$bounds{'zmin'};
    my $size   = max($width, $height, $depth);
    # 0 = outside
    # >0 = inside
    my $voxels = [];
    for my $z (0 .. $depth + $probesize + 5) {
        #$$voxels[$z] = [];
        for my $y (0 .. $height + $probesize + 5) {
            #$$voxels[$z][y] = [];
            for my $x (0 .. $width + $probesize + 5) {
                $$voxels[$z][$y][$x] = 0; # Outside
                $$voxels[$z][$y][$x] = 0; # Outside
            }
        }
    }
    my $c = 0;
    for(my $probe = 0; $probe <= $probesize; $probe += $probesize / 2) {
        $c++;
        for my $atom (@$molecule) {
            my $x = int ($$atom{X} - $$bounds{'xmin'});
            my $y = int ($$atom{Y} - $$bounds{'ymin'});
            my $z = int ($$atom{Z} - $$bounds{'zmin'});
            my $r = $probe + radius_of $atom;
            for(my $ox = -$r; $ox <= $r; $ox++) {
                for(my $oy = -$r; $oy <= $r; $oy++) {
                    for(my $oz = -$r; $oz <= $r; $oz++) {
                        if($x + $ox > 0 and $y + $oy > 0 and $z + $oz > 0) {
                            if($$voxels[$z+$oz][$y+$oy][$x+$ox] > 0) {
                            } elsif (cubeSphereIntersect($x+$ox,$y+$oy,$z+$oz,1,$x,$y,$z,$r)) {
                                $$voxels[$z+$oz][$y+$oy][$x+$ox] = $c;
                            }
                        }
                    }
                }
            }
        }
        say "$progress / 7 done";
        $progress++;
        last if($probesize == 0);
    }
    return $voxels;
}
sub show_atoms {
    my ($canvas, $molecule) = @_;
    my $bounds = getBounds($molecule);
    my $scale = 2.5;
    for my $atom (sort { $a->z <=> $b->z } @$molecule) {
        my $color  = color_of  $atom;
        my $radius = radius_of $atom;
        my $xy  = xy_of ($atom, $bounds, 2);
        addCircle($canvas, $$xy{x} * $scale, $$xy{y} * $scale, 0 | 1 + 2 * $radius * $scale, $color);
    }
    MainLoop();
}
sub show_spaceFill {
    my ($window, $molecule, $probesize, $scale) = @_;
    for(my $probe = 0; $probe <= $probesize; $probe += $probesize / 2) {
        my $voxels = probe_bounds($molecule, $probe);
        my $canvas = $window->Canvas(-background => "black", -width => 250, -height => 250);
        $canvas->createText(250, 250, -anchor=>'se', -fill => 'white', -text=>"Probe size: $probe");
        $canvas->pack();
        my $z = 0;
        for my $plane (@$voxels) {
            my $y = 0;
            for my $line (@$plane) {
                my $x = 0;
                for my $voxel (@$line) {
                    if($voxel) {
                        addCube($canvas, $x, $y, $z, $scale, 0x55 * $voxel);
                    }
                    $x++;
                }
                $y++;
            }
            $z++;
        }
        last if($probesize == 0);
    }
    MainLoop();
}

my $molecule = Bio::PDB::Structure::Molecule->new;
if (defined $ARGV[0]) {
    $molecule->read($ARGV[0]);
} else {
    die "I need a .pdb file\n";
}
my $probesize = prompt "What probe size do you want to use?";
my $window = MainWindow->new();
say "You probably want to get a cup of coffee. This will take a while.";
$window->minsize(500, 500);
$window->title($ARGV[0]);
my $scale = 2;
show_spaceFill($window, $molecule, $probesize, $scale);
