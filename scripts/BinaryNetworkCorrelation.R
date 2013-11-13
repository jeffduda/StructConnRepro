#! /usr/bin/Rscript --vanilla --default-packages=utils,stats
options <- commandArgs(trailingOnly = TRUE)
n1 <- as.matrix(read.csv(options[1]))
n2 <- as.matrix(read.csv(options[2]))
n1 <- n1[upper.tri(n1)]
n2 <- n2[upper.tri(n2)]
n1[ n1 > 0 ] <- 1
n1[ n2 > 0 ] <- 1
print( cor.test(n1,n2) )
print( cor.test(n1,n2)$p.value )


