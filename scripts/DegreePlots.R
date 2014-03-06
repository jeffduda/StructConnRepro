#! /usr/bin/Rscript --vanilla --default-packages=utils,stats
library(ggplot2)



intraEulerAAL <- read.csv("../data/Statistics/intra_euler_aal_dice.csv" )
intraFactAAL  <- read.csv("../data/Statistics/intra_fact_aal_dice.csv" )
intraRkAAL <- read.csv("../data/Statistics/intra_rk4_aal_dice.csv" )
intraTendAAL <- read.csv("../data/Statistics/intra_tend_aal_dice.csv" )
  
interEulerAAL <- read.csv("../data/Statistics/inter_euler_aal_dice.csv" )
interFactAAL  <- read.csv("../data/Statistics/inter_fact_aal_dice.csv" )
interRkAAL <- read.csv("../data/Statistics/inter_rk4_aal_dice.csv" )
interTendAAL <- read.csv("../data/Statistics/inter_tend_aal_dice.csv" )

m1 <- colMeans(intraEulerAAL[,5:dim(intraEulerAAL)[2]])
m2 <- colMeans(intraFactAAL[,5:dim(intraFactAAL)[2]])
m3 <- colMeans(intraRkAAL[,5:dim(intraRkAAL)[2]])
m4 <- colMeans(intraTendAAL[,5:dim(intraTendAAL)[2]])

m5 <- colMeans(interEulerAAL[,5:dim(interEulerAAL)[2]])
m6 <- colMeans(interFactAAL[,5:dim(interFactAAL)[2]])
m7 <- colMeans(interRkAAL[,5:dim(interRkAAL)[2]])
m8 <- colMeans(interTendAAL[,5:dim(interTendAAL)[2]])

intraEulerDKT <- read.csv("../data/Statistics/intra_euler_dkt31_dice.csv" )
intraFactDKT  <- read.csv("../data/Statistics/intra_fact_dkt31_dice.csv" )
intraRkDKT <- read.csv("../data/Statistics/intra_rk4_dkt31_dice.csv" )
intraTendDKT <- read.csv("../data/Statistics/intra_tend_dkt31_dice.csv" )
  
interEulerDKT <- read.csv("../data/Statistics/inter_euler_dkt31_dice.csv" )
interFactDKT  <- read.csv("../data/Statistics/inter_fact_dkt31_dice.csv" )
interRkDKT <- read.csv("../data/Statistics/inter_rk4_dkt31_dice.csv" )
interTendDKT <- read.csv("../data/Statistics/inter_tend_dkt31_dice.csv" )

m9 <- colMeans(intraEulerDKT[,5:dim(intraEulerDKT)[2]])
m10 <- colMeans(intraFactDKT[,5:dim(intraFactDKT)[2]])
m11 <- colMeans(intraRkDKT[,5:dim(intraRkDKT)[2]])
m12 <- colMeans(intraTendDKT[,5:dim(intraTendDKT)[2]])

m13 <- colMeans(interEulerDKT[,5:dim(interEulerDKT)[2]])
m14 <- colMeans(interFactDKT[,5:dim(interFactDKT)[2]])
m15 <- colMeans(interRkDKT[,5:dim(interRkDKT)[2]])
m16 <- colMeans(interTendDKT[,5:dim(interTendDKT)[2]])

ln <- max(c(length(m1),length(m2),length(m3),length(m4),length(m5),length(m6),length(m7),length(m8),length(m9),length(m10),length(m11),length(m12),length(m13),length(m14),length(m15),length(m16) ) )
length(m1) <- ln
length(m2) <- ln
length(m3) <- ln
length(m4) <- ln
length(m5) <- ln
length(m6) <- ln
length(m7) <- ln
length(m8) <- ln
length(m9) <- ln
length(m10) <- ln
length(m11) <- ln
length(m12) <- ln
length(m13) <- ln
length(m14) <- ln
length(m15) <- ln
length(m16) <- ln

dens <- (c(1:ln)*0.005)
dens <- rep(dens,16)

aalintra <- c(m1,m2,m3,m4)
aalintra <- aalintra[which(!is.na(aalintra))]
aalinter <- c(m5,m6,m7,m8)
aalinter <- aalinter[which(!is.na(aalinter))]
dktintra <- c(m9,m10,m11,m12)
dktintra <- dktintra[which(!is.na(dktintra))]
dktinter <- c(m13,m14,m15,m16)
dktinter <- dktinter[which(!is.na(dktinter))]


print(paste("AAL intra", min(aalintra), max(aalintra) ) )
print(paste("AAL inter", min(aalinter), max(aalinter) ) )
print(paste("DKT intra", min(dktintra), max(dktintra) ) )
print(paste("DKT inter", min(dktinter), max(dktinter) ) )

dice <- c(m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16)

id <- rep(c(1:16),each=ln)

alg <- c(rep("Euler",ln),rep("FACT",ln),rep("RK4",ln),rep("TEND",ln),rep("Euler",ln),rep("FACT",ln),rep("RK4",ln),rep("TEND",ln))
alg <- c(alg,alg)

type <- c(rep("Intra-Subject",ln*4),rep("Inter-Subject",ln*4) )
type <- c(type,type)

label <- c(rep("AAL",ln*8),rep("DKT31",ln*8))

data <- data.frame(Dice=dice, Density=dens, Algorithm=as.factor(alg), Cohort=as.factor(type), ID=as.factor(id), Labels=as.factor(label) )

diceplot <- ggplot( data, aes(x=Density, y=Dice, colour=Algorithm, group=ID ) ) + geom_line(aes(linetype=Cohort)) + ggtitle("Overlap of constant density subgraphs") + theme(plot.title = element_text(lineheight=0.5)) + facet_grid(. ~ Labels)

png( filename="../data/Statistics/dice_overlap_plot.png", width=1000, height=300 )
print(diceplot)
dev.off()

print("Intra")
print( PermutationTestFDA(intraEulerAAL[,5:dim(intraEulerAAL)[2]],intraFactAAL[,5:dim(intraFactAAL)[2]]) )
print( PermutationTestFDA(intraEulerAAL[,5:dim(intraEulerAAL)[2]],intraRkAAL[,5:dim(intraRkAAL)[2]]) )
print( PermutationTestFDA(intraEulerAAL[,5:dim(intraEulerAAL)[2]],intraTendAAL[,5:dim(intraTendAAL)[2]]) )
print( PermutationTestFDA(intraFactAAL[,5:dim(intraFactAAL)[2]],intraRkAAL[,5:dim(intraRkAAL)[2]]) )
print( PermutationTestFDA(intraFactAAL[,5:dim(intraFactAAL)[2]],intraTendAAL[,5:dim(intraTendAAL)[2]]) )
print( PermutationTestFDA(intraRkAAL[,5:dim(intraRkAAL)[2]],intraTendAAL[,5:dim(intraTendAAL)[2]]) )

print("Inter")
print( PermutationTestFDA(interEulerAAL[,5:dim(interEulerAAL)[2]],interFactAAL[,5:dim(interFactAAL)[2]]) )
print( PermutationTestFDA(interEulerAAL[,5:dim(interEulerAAL)[2]],interRkAAL[,5:dim(interRkAAL)[2]]) )
print( PermutationTestFDA(interEulerAAL[,5:dim(interEulerAAL)[2]],interTendAAL[,5:dim(interTendAAL)[2]]) )
print( PermutationTestFDA(interFactAAL[,5:dim(interFactAAL)[2]],interRkAAL[,5:dim(interRkAAL)[2]]) )
print( PermutationTestFDA(interFactAAL[,5:dim(interFactAAL)[2]],interTendAAL[,5:dim(interTendAAL)[2]]) )
print( PermutationTestFDA(interRkAAL[,5:dim(interRkAAL)[2]],interTendAAL[,5:dim(interTendAAL)[2]]) )

print("Intra DKT")
print( PermutationTestFDA(intraEulerDKT[,5:dim(intraEulerDKT)[2]],intraFactDKT[,5:dim(intraFactDKT)[2]]) )
print( PermutationTestFDA(intraEulerDKT[,5:dim(intraEulerDKT)[2]],intraRkDKT[,5:dim(intraRkDKT)[2]]) )
print( PermutationTestFDA(intraEulerDKT[,5:dim(intraEulerDKT)[2]],intraTendDKT[,5:dim(intraTendDKT)[2]]) )
print( PermutationTestFDA(intraFactDKT[,5:dim(intraFactDKT)[2]],intraRkDKT[,5:dim(intraRkDKT)[2]]) )
print( PermutationTestFDA(intraFactDKT[,5:dim(intraFactDKT)[2]],intraTendDKT[,5:dim(intraTendDKT)[2]]) )
print( PermutationTestFDA(intraRkDKT[,5:dim(intraRkDKT)[2]],intraTendDKT[,5:dim(intraTendDKT)[2]]) )

print("Inter DKT")
print( PermutationTestFDA(interEulerDKT[,5:dim(interEulerDKT)[2]],interFactDKT[,5:dim(interFactDKT)[2]]) )
print( PermutationTestFDA(interEulerDKT[,5:dim(interEulerDKT)[2]],interRkDKT[,5:dim(interRkDKT)[2]]) )
print( PermutationTestFDA(interEulerDKT[,5:dim(interEulerDKT)[2]],interTendDKT[,5:dim(interTendDKT)[2]]) )
print( PermutationTestFDA(interFactDKT[,5:dim(interFactDKT)[2]],interRkDKT[,5:dim(interRkDKT)[2]]) )
print( PermutationTestFDA(interFactDKT[,5:dim(interFactDKT)[2]],interTendDKT[,5:dim(interTendDKT)[2]]) )
print( PermutationTestFDA(interRkDKT[,5:dim(interRkDKT)[2]],interTendDKT[,5:dim(interTendDKT)[2]]) )

#print( PermutationTestFDA(m2,m6) )
#print( PermuationTestFDA(m3,m7)
