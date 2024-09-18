use strict;
use warnings;

my $input = $ARGV[0];

open(IN, $input) || die "cannot open $!";

while(<IN>) {
    chomp;
    my @F = split("\t", $_);
    
    if ($F[2] eq 'transcript') {
        my $chr = $F[0];
        my $start = $F[3];
        my $end = $F[4];
        
        my ($transcript_id) = $F[8] =~ /transcript_id "([^"]+)"/;
        
        print $chr . "\t" . $start . "\t" . $end . "\t" . $transcript_id . "\n";
    }
}

close(IN);

