#!/usr/bin/perl
use strict;
use warnings;
use List::Util qw(max min);

# Get command-line arguments
my ($gtf_file, $coding_exon_file, $coding_intron_file, $coding_5putr_file, $coding_3putr_file, $noncoding_exon_file, $noncoding_intron_file) = @ARGV;

# Open input and output files
open(IN, "<", $gtf_file) or die "Could not open $gtf_file: $!";
open(CODING_EXON, ">", $coding_exon_file) or die "Could not open $coding_exon_file: $!";
open(CODING_INTRON, ">", $coding_intron_file) or die "Could not open $coding_intron_file: $!";
open(CODING_5PUTR, ">", $coding_5putr_file) or die "Could not open $coding_5putr_file: $!";
open(CODING_3PUTR, ">", $coding_3putr_file) or die "Could not open $coding_3putr_file: $!";
open(NONCODING_EXON, ">", $noncoding_exon_file) or die "Could not open $noncoding_exon_file: $!";
open(NONCODING_INTRON, ">", $noncoding_intron_file) or die "Could not open $noncoding_intron_file: $!";

my ($current_transcript, $current_chr, $current_strand, $current_tx_start, $current_tx_end);
my (@exon_starts, @exon_ends);

# Process the GTF file line by line
while (<IN>) {
    chomp;
    next if /^#/; # Skip comment lines

    my @fields = split("\t", $_);
    my $feature_type = $fields[2];
    my $attributes = $fields[8];

    # Extract gene_id and transcript_id
    my ($gene_id) = $attributes =~ /gene_id "([^"]+)"/;
    my ($transcript_id) = $attributes =~ /transcript_id "([^"]+)"/;
    my $output_line = "$fields[0]\t$fields[3]\t$fields[4]\t$gene_id($transcript_id)\n";

    if ($feature_type eq "transcript") {
        # Print introns for previous transcript
        if (@exon_starts) {
            for (my $i = 1; $i < @exon_starts; $i++) {
                my $intron_start = $exon_ends[$i - 1];
                my $intron_end = $exon_starts[$i];
                if ($current_transcript =~ /^NM_/) {
                    print CODING_INTRON "$current_chr\t$intron_start\t$intron_end\t$gene_id($current_transcript)\n";
                } elsif ($current_transcript =~ /^NR_/) {
                    print NONCODING_INTRON "$current_chr\t$intron_start\t$intron_end\t$gene_id($current_transcript)\n";
                }
            }
        }

        # Store new transcript information
        $current_transcript = $transcript_id;
        $current_chr = $fields[0];
        $current_strand = $fields[6];
        $current_tx_start = $fields[3];
        $current_tx_end = $fields[4];
        @exon_starts = ();
        @exon_ends = ();
    }
    elsif ($feature_type eq "exon") {
        push @exon_starts, $fields[3];
        push @exon_ends, $fields[4];

        # UTR and coding region logic
        if ($current_strand eq "+") {
            if ($fields[3] < $current_tx_start) {
                print CODING_5PUTR "$current_chr\t$fields[3]\t".min($fields[4], $current_tx_start)."\t$gene_id($current_transcript)\n" if $transcript_id =~ /^NM_/;
                print NONCODING_5PUTR "$current_chr\t$fields[3]\t".min($fields[4], $current_tx_start)."\t$gene_id($current_transcript)\n" if $transcript_id =~ /^NR_/;
            }
            if ($fields[4] > $current_tx_end) {
                print CODING_3PUTR "$current_chr\t".max($fields[3], $current_tx_end)."\t$fields[4]\t$gene_id($current_transcript)\n" if $transcript_id =~ /^NM_/;
                print NONCODING_3PUTR "$current_chr\t".max($fields[3], $current_tx_end)."\t$fields[4]\t$gene_id($current_transcript)\n" if $transcript_id =~ /^NR_/;
            }
            if (min($fields[4], $current_tx_end) - max($fields[3], $current_tx_start) > 0) {
                print CODING_EXON "$current_chr\t".max($fields[3], $current_tx_start)."\t".min($fields[4], $current_tx_end)."\t$gene_id($current_transcript)\n" if $transcript_id =~ /^NM_/;
                print NONCODING_EXON "$current_chr\t".max($fields[3], $current_tx_start)."\t".min($fields[4], $current_tx_end)."\t$gene_id($current_transcript)\n" if $transcript_id =~ /^NR_/;
            }
        } else {
            if ($fields[3] < $current_tx_start) {
                print CODING_3PUTR "$current_chr\t$fields[3]\t".min($fields[4], $current_tx_start)."\t$gene_id($current_transcript)\n" if $transcript_id =~ /^NM_/;
                print NONCODING_3PUTR "$current_chr\t$fields[3]\t".min($fields[4], $current_tx_start)."\t$gene_id($current_transcript)\n" if $transcript_id =~ /^NR_/;
            }
            if ($fields[4] > $current_tx_end) {
                print CODING_5PUTR "$current_chr\t".max($fields[3], $current_tx_end)."\t$fields[4]\t$gene_id($current_transcript)\n" if $transcript_id =~ /^NM_/;
                print NONCODING_5PUTR "$current_chr\t".max($fields[3], $current_tx_end)."\t$fields[4]\t$gene_id($current_transcript)\n" if $transcript_id =~ /^NR_/;
            }
            if (min($fields[4], $current_tx_end) - max($fields[3], $current_tx_start) > 0) {
                print CODING_EXON "$current_chr\t".max($fields[3], $current_tx_start)."\t".min($fields[4], $current_tx_end)."\t$gene_id($current_transcript)\n" if $transcript_id =~ /^NM_/;
                print NONCODING_EXON "$current_chr\t".max($fields[3], $current_tx_start)."\t".min($fields[4], $current_tx_end)."\t$gene_id($current_transcript)\n" if $transcript_id =~ /^NR_/;
            }
        }
    }
    elsif ($feature_type eq "5UTR") {
        if ($transcript_id =~ /^NM_/) {
            print CODING_5PUTR "$current_chr\t$fields[3]\t$fields[4]\t$gene_id($current_transcript)\n";
        } elsif ($transcript_id =~ /^NR_/) {
            print NONCODING_5PUTR "$current_chr\t$fields[3]\t$fields[4]\t$gene_id($current_transcript)\n";
        }
    }
    elsif ($feature_type eq "3UTR") {
        if ($transcript_id =~ /^NM_/) {
            print CODING_3PUTR "$current_chr\t$fields[3]\t$fields[4]\t$gene_id($current_transcript\n";
        } elsif ($transcript_id =~ /^NR_/) {
            print NONCODING_3PUTR "$current_chr\t$fields[3]\t$fields[4]\t$gene_id($current_transcript\n";
        }
    }
}

# Print introns for the last transcript
if (@exon_starts) {
    for (my $i = 1; $i < @exon_starts; $i++) {
        my $intron_start = $exon_ends[$i - 1];
        my $intron_end = $exon_starts[$i];
        if ($current_transcript =~ /^NM_/) {
            print CODING_INTRON "$current_chr\t$intron_start\t$intron_end\t$current_transcript\n";
        } elsif ($current_transcript =~ /^NR_/) {
            print NONCODING_INTRON "$current_chr\t$intron_start\t$intron_end\t$current_transcript\n";
        }
    }
}

# Close all files
close(IN);
close(CODING_EXON);
close(CODING_INTRON);
close(CODING_5PUTR);
close(CODING_3PUTR);
close(NONCODING_EXON);
close(NONCODING_INTRON);
