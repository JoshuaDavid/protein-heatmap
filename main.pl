use strict;
use warnings;
use Test;
use lib "./packages/JSON-2.90/lib/";
use JSON;
use lib "./packages/Bio-PDB-Structure/lib/";
use Bio::PDB::Structure;
use lib "./packages/Imager/lib";
use Imager;
use Imager::Fill;

my $atoms;
if (defined $ARGV[0]) {
    my $pdbfile = $ARGV[0]; 
} else {
    die "I need a .pdb file\n";
}

my $lightingAngle = { x =>  0, y =>  1, z =>  1 }; # lighting coming from in front and above
my $camera        = { x =>  0, y =>  0, z => -4 };
my $cameraAndle   = { x =>  0, y =>  0, z =>  1 }; # Looking at the origin

