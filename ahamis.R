library(ggplot2);

setwd("data")

id = read.table(
  "WKYvariantsinclSHR13.strains.txt",
  header = FALSE,
  stringsAsFactors = FALSE);
x = (id$V1 == id$V2);
id$V1[!x] = paste(id$V1[!x], id$V2[!x], sep="_");
id = id$V1;

data = read.table(
  "WKYvariantsinclSHR13.minGQ10_minDP4.maskhetgenotype.max-missing-count0.genotypecount",
  header = FALSE,
  stringsAsFactors=F);
names(data)[ncol(data)] = "count";
data = data[order(data$count, decreasing = TRUE), ];
n = ncol(data) - 1;
# unify SNPs in complete LD
for (i in 1:nrow(data)) {
  if (data$count[i] == 0) { next };
  unify_snp_g = function () {
    j = which(
      apply(
        as.matrix(data[, -(n+1)]) == 
          matrix(g, nrow=nrow(data), ncol=n, byrow=TRUE),
        1,
        all));
    if (length(j)==1 && (i < j)) {
      data$count[i] = data$count[i] + data$count[j];
      data$count[j] = 0;
    }
    return(data);
  }
  g = data[i, -(n+1)];
  # if not 0 1 alleles, skip; eg. tri-allelic
  x = setdiff(as.character(g), c("0/0", "1/1"));
  if (length(x) > 0) {
    print(paste0("Irregular alleles in ", i));
    print(g);
    next();
  }
  # 1 0
  g = gsub("z/z", "1/1",
           gsub("1/1", "0/0",
                gsub("0/0", "z/z", g)));
  data = unify_snp_g();
  # Added 2019.02.14
  # 2 0
  g = gsub("1/1", "2/2", g);
  data = unify_snp_g();
  # 2 1
  g = gsub("0/0", "1/1", g);
  data = unify_snp_g();
  # 1 2
  g = gsub("o/o", "2/2",
           gsub("2/2", "1/1",
                gsub("1/1", "o/o", g)));
  data = unify_snp_g();
  # 0 2
  g = gsub("1/1", "0/0", g);
  data = unify_snp_g();
}
data = data[data$count >0, ];
data = data[order(data$count, decreasing=TRUE), ];
write.table(data,
            "genotype/genotypecount.txt",
            row.names = TRUE,
            sep = "\t")
# Edit this tab text file by hand:
# Remove monomorphic line (i.e., genotype identical for all strains)
# Add last column for "code"
# Save as genotype/genotypecount.polymorphic.withcode.txt


###
### Enumerate clusters of SNPs in complete LD as LDclusters
###
foo = read.table(
  "WKYvariantsinclSHR13.minGQ10_minDP4.maskhetgenotype.max-missing-count0.positions.gz",
  header = FALSE,
  stringsAsFactors = FALSE);
names(foo) = c("chr", "pos");
foo = foo[foo$chr %in% paste("chr", c(1:20,"X"), sep=""), ];
foo$chr = sub("chr", "", foo$chr);
foo$chr = sub("X", "21", foo$chr);
foo$chr = as.numeric(foo$chr);
foo = foo[order(foo$chr, foo$pos), ];
chrposall = foo;

datacode = read.table(
  "genotype/genotypecount.polymorphic.withcode.txt",
  header = TRUE,
  stringsAsFactors = FALSE);
LDclusters = data.frame();
for (i in 1:nrow(datacode)) {
  print(i);
  if (datacode$count[i] < 10) { #20
    next
  };
  if (length(grep("[23]", datacode$code[i])) > 0) { next }
  foo = read.table(
    paste0(
      "genotype/",
      datacode$code[i]),
    header=F, stringsAsFactors=F);
  names(foo) = c("chr", "pos");
  foo = foo[foo$chr %in% paste("chr", c(1:20,"X"), sep=""), ];
  foo$chr = sub("chr", "", foo$chr);
  foo$chr = sub("X", "21", foo$chr);
  foo$chr = as.numeric(foo$chr);
  foo = foo[order(foo$chr, foo$pos), ];
  chrpossegregate = foo;
  
  # extract clusters by variant count, rather than bp,
  # in order to avoid density bias of variants/sequencing in genome
  chrpossegregate$orderinall =
    match(paste(chrpossegregate$chr, chrpossegregate$pos),
          paste(chrposall$chr, chrposall$pos));
  chrpossegregate$gapfromprev =
    c(0, diff(chrpossegregate$orderinall));
  # x = chrpossegregate$gapfromprev;
  # x = x[-1];
  # mean(x <= 10);
  # x = x[x > 10];
  # plot(log10(sort(x)));
  ## max gap set to 100
  ## this is conservative; can subdivide one cluster
  maxgap = 100;
  
  # Cluster neighbouring SNPs
  snpstowindow = function(chr, pos, gapfromprev) {
    if (length(chr)==0) {
      return(data.frame());
    }
    result = c(chr[1], pos[1]);
    cprev = chr[1];
    pprev = pos[1];
    snpsinwindow  = 1;
    if (length(chr) > 1) {
      for (j in 2:length(chr)) {
        if (chr[j]==cprev & (gapfromprev[j] <= maxgap)) {
          pprev = pos[j];
          snpsinwindow = snpsinwindow + 1;
        } else {
          result = c(result, pprev, snpsinwindow, chr[j], pos[j]);
          cprev = chr[j];
          pprev = pos[j];
          snpsinwindow = 1;
        }
      }
    }
    result = c(result, pprev, snpsinwindow);
    result = data.frame(matrix(result, ncol=4, byrow=TRUE));
    names(result) = c("chr", "start", "end", "snpsinwindow");
    result
  }
  
  w = snpstowindow(chrpossegregate$chr,
                   chrpossegregate$pos,
                   chrpossegregate$gapfromprev);
  # plot(log10(sort(w$snpsinwindow)));
  # plot(sort(w$snpsinwindow[w$snpsinwindow < 50]));
  # require 20 >= snpsinwindow
  # This is conservative; some complete LD SNP clusters could be undetected
  w = w[w$snpsinwindow >= 20, ];
  
  if (nrow(w) > 0) {
    w$snpsinwindow = paste(datacode$code[i], w$snpsinwindow, sep=".");
    names(w)[4] = "name";
    LDclusters = rbind(LDclusters, w);
  } else {
    print(paste0("No complete LD clusters detected for ", i));
  }
  
}
write.table(LDclusters, "LDclusters.txt",
            row.names=F, sep="\t");


##
## List overlaps as LDclustersoverlap
##
LDclustersstartend = LDclusters[, c("chr","start","name")];
names(LDclustersstartend)[2] = "pos";
LDclustersstartend$startend = 1;
x = LDclusters[, c("chr","end","name")];
names(x)[2] = "pos";
x$startend = -1;
LDclustersstartend = rbind(
  LDclustersstartend, x);
LDclustersstartend =
  LDclustersstartend[
    order(LDclustersstartend$chr, LDclustersstartend$pos), ];

result = c(LDclustersstartend$chr[1],
           LDclustersstartend$pos[1]);
cprev = LDclustersstartend$chr[1];
currentfeaturescount = 1;
currentfeaturesname = LDclustersstartend$name[1];
for (i in 2:nrow(LDclustersstartend)) {
  if (LDclustersstartend$startend[i] == 1) {
    # starting a cluster
    if (cprev != LDclustersstartend$chr[i]) {
      # switched chr; no output
      result = c(result[seq(1, length(result)-2)],
                 LDclustersstartend$chr[i],
                 LDclustersstartend$pos[i]);
    } else {
      # still in same chr
      result = c(result,
                 LDclustersstartend$pos[i] - 1,
                 currentfeaturescount,
                 paste(currentfeaturesname, collapse=" "),
                 LDclustersstartend$chr[i],
                 LDclustersstartend$pos[i]);
    }
    cprev = LDclustersstartend$chr[i];
    currentfeaturescount = currentfeaturescount + 1;
    currentfeaturesname = sort(c(currentfeaturesname,
                                 LDclustersstartend$name[i]));
  } else {
    # ending a cluster
    result = c(result,
               LDclustersstartend$pos[i],
               currentfeaturescount,
               paste(currentfeaturesname, collapse=" "),
               LDclustersstartend$chr[i],
               LDclustersstartend$pos[i] + 1);
    cprev = LDclustersstartend$chr[i];
    currentfeaturescount = currentfeaturescount - 1;
    currentfeaturesname = setdiff(currentfeaturesname,
                                  LDclustersstartend$name[i]);
  }
}
result = result[seq(1, length(result)-2)];
result = data.frame(matrix(result, ncol=5, byrow=TRUE));
names(result) = c("chr", "start", "end", "count", "name");
for (i in c("chr", "start", "end", "count")) {
  result[, i] =
    as.numeric(as.character(result[, i]));
}
LDclustersoverlap = result;


##
## Annotate LDclustersoverlap
##
LDclustersoverlap$haplotypecount = 1;
LDclustersoverlap$haplotypename = "";
for (i in 1:nrow(LDclustersoverlap)) {
  if (LDclustersoverlap$count[i] == 0) { next };
  
  # generate datasmall
  x = as.character(LDclustersoverlap$name[i]);
  x = strsplit(x, " ")[[1]];
  x = sub("\\.[0-9]+", "", x);
  datasmall = matrix(as.numeric(unlist(strsplit(x, "_"))),
                     byrow=TRUE,
                     nrow=length(x));
  
  # haplotype classes
  x = apply(datasmall,
            2,
            function(z){ paste0(z, collapse=" ") });
  names(x) = id;
  x = as.ordered(x);
  LDclustersoverlap$haplotypecount[i] = length(levels(x));
  LDclustersoverlap$haplotypename[i] =
    paste0(as.numeric(x), collapse=" ");
  
}
write.table(LDclustersoverlap, "LDclustersoverlap.txt",
            row.names=F, sep="\t");


##
## Plot ancestral haplotype map
##
ggplot(data=LDclustersoverlap) +
  geom_segment(aes(x=chr, xend=chr, y=start, yend=end,
                   color=factor(haplotypecount),
                   size=haplotypecount)) +
  scale_color_manual(values=c("black","blue","orange","green","red")) +
  xlab("Chr") +
  ylab("Position [bp]")
