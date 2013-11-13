#! /usr/bin/Rscript --vanilla --default-packages=utils,stats
library(ggplot2)


pEulerAAL <- read.csv("../data/Statistics/assort_euler_aal.csv" )
pFactAAL  <- read.csv("../data/Statistics/assort_fact_aal.csv" )
pRkAAL <- read.csv("../data/Statistics/assort_rk4_aal.csv" )
pTendAAL <- read.csv("../data/Statistics/assort_tend_aal.csv" )
  
pEulerDKT <- read.csv("../data/Statistics/assort_euler_dkt31.csv" )
pFactDKT  <- read.csv("../data/Statistics/assort_fact_dkt31.csv" )
pRkDKT <- read.csv("../data/Statistics/assort_rk4_dkt31.csv" )
pTendDKT <- read.csv("../data/Statistics/assort_tend_dkt31.csv" )

v1 <- as.matrix(pEulerAAL[,5:dim(pEulerAAL)[2]])
v2 <- as.matrix(pFactAAL[,5:dim(pFactAAL)[2]])
v3 <- as.matrix(pRkAAL[,5:dim(pRkAAL)[2]])
v4 <- as.matrix(pTendAAL[,5:dim(pTendAAL)[2]])

v5 <- as.matrix(pEulerDKT[,5:dim(pEulerDKT)[2]])
v6 <- as.matrix(pFactDKT[,5:dim(pFactDKT)[2]])
v7 <- as.matrix(pRkDKT[,5:dim(pRkDKT)[2]])
v8 <- as.matrix(pTendDKT[,5:dim(pTendDKT)[2]])

m1 <- colMeans(v1)
m2 <- colMeans(v2)
m3 <- colMeans(v3)
m4 <- colMeans(v4)
m5 <- colMeans(v5)
m6 <- colMeans(v6)
m7 <- colMeans(v7)
m8 <- colMeans(v8)

ln <- max(c(length(m1),length(m2),length(m3),length(m4),length(m5),length(m6),length(m7),length(m8) ) )
length(m1) <- ln
length(m2) <- ln
length(m3) <- ln
length(m4) <- ln
length(m5) <- ln
length(m6) <- ln
length(m7) <- ln
length(m8) <- ln



dens <- (c(1:ln)*0.005)
dens <- rep(dens,8)

values <- c(m1,m2,m3,m4,m5,m6,m7,m8)

id <- rep(c(1:8),each=ln)

alg <- c(rep("Euler",ln),rep("FACT",ln),rep("RK4",ln),rep("TenD",ln),rep("Euler",ln),rep("FACT",ln),rep("RK4",ln),rep("TenD",ln))

label <- c(rep("AAL",ln*4),rep("DKT31",ln*4))

data <- data.frame(Assortativity=values, Density=dens, Algorithm=as.factor(alg), ID=as.factor(id), Labels=as.factor(label) )

pathplot <- ggplot( data, aes(x=Density, y=Assortativity, colour=Algorithm, group=ID ) ) + geom_line() + ggtitle("Assortativity in constant density subgraphs") + theme(plot.title = element_text(lineheight=0.5)) + facet_grid(. ~ Labels)

png( filename="../data/Statistics/assort_plot.png", width=1000, height=300 )
print(pathplot)
dev.off()

icc1 <- rep(NA,ln)
icc2 <- rep(NA,ln)
icc3 <- rep(NA,ln)
icc4 <- rep(NA,ln)
icc5 <- rep(NA,ln)
icc6 <- rep(NA,ln)
icc7 <- rep(NA,ln)
icc8 <- rep(NA,ln)
nSubs <- dim(v1)[1]/2
ids <- as.factor(rep(c(1:nSubs),each=2))

for ( i in c(1:ln) ) {  
  if ( i <= dim(v1)[2] ) {
    dat <- data.frame(path=v1[,i],id=ids)
    picc1 <- ICCest(id,path,dat)
    icc1[i] <- picc1$ICC
    }
  if ( i <= dim(v2)[2] ) {
    dat <- data.frame(path=v2[,i],id=ids)
    picc1 <- ICCest(id,path,dat)
    icc2[i] <- picc1$ICC
  }
  if ( i <= dim(v3)[2] ) {
    dat <- data.frame(path=v3[,i],id=ids)
    picc1 <- ICCest(id,path,dat)
    icc3[i] <- picc1$ICC
  }
  if ( i <= dim(v4)[2] ) {
    dat <- data.frame(path=v4[,i],id=ids)
    picc1 <- ICCest(id,path,dat)
    icc4[i] <- picc1$ICC
  }
  if ( i <= dim(v5)[2] ) {
    dat <- data.frame(path=v5[,i],id=ids)
    picc1 <- ICCest(id,path,dat)
    icc5[i] <- picc1$ICC
  }
  if ( i <= dim(v6)[2] ) {
    dat <- data.frame(path=v6[,i],id=ids)
    picc1 <- ICCest(id,path,dat)
    icc6[i] <- picc1$ICC
  }
  if ( i <= dim(v7)[2] ) {
    dat <- data.frame(path=v7[,i],id=ids)
    picc1 <- ICCest(id,path,dat)
    icc7[i] <- picc1$ICC
  }
  if ( i <= dim(v8)[2] ) {
    dat <- data.frame(path=v8[,i],id=ids)
    picc1 <- ICCest(id,path,dat)
    icc8[i] <- picc1$ICC
  }
}
  
pathiccvalues <- c(icc1,icc2,icc3,icc4,icc5,icc6,icc7,icc8)
pathiccdata <- data.frame(ICC=pathiccvalues, Density=dens, Algorithm=as.factor(alg), ID=as.factor(id), Labels=as.factor(label) )

pathiccplot <- ggplot( pathiccdata, aes(x=Density, y=ICC, colour=Algorithm, group=ID ) ) + geom_line() + ggtitle("ICC of assortativity in constant density subgraphs") + theme(plot.title = element_text(lineheight=0.5)) + facet_grid(. ~ Labels)  + geom_hline(aes(yintercept=0.2),linetype="dashed",colour="darkgray") + geom_hline(aes(yintercept=0.4),linetype="dashed",colour="darkgray") + geom_hline(aes(yintercept=0.6),linetype="dashed",colour="darkgray") + geom_hline(aes(yintercept=0.8),linetype="dashed",colour="darkgray") + scale_y_continuous(limits = c(-0.3, 0.9))


png( filename="../data/Statistics/assort_icc_plot.png", width=1000, height=300 )
print(pathiccplot)
dev.off()

firstTimes <- c(1:21)*2-1
print(pEulerAAL[firstTimes,1])
pmat <- matrix(NA,4,4)

print( "EulerAAL - FactAAL" )
print( PermutationTestFDA( v1[firstTimes,],v2[firstTimes,]) )
print( "EulerAAL - RK4AAL" )
print( PermutationTestFDA( v1[firstTimes,],v3[firstTimes,]) )
print( "EulerAAL - TendAAL" )
print( PermutationTestFDA( v1[firstTimes,],v4[firstTimes,]) )
print( "FactAAL - RK4AAL" )
print( PermutationTestFDA( v2[firstTimes,],v3[firstTimes,]) )
print( "FactAAL - TendAAL" )
print( PermutationTestFDA( v2[firstTimes,],v4[firstTimes,]) )
print( "RK4AAL - TendAAL" )
print( PermutationTestFDA( v3[firstTimes,],v4[firstTimes,]) )
print( "EulerDKT31 - FactDKT31" )
print( PermutationTestFDA( v5[firstTimes,],v6[firstTimes,]) )
print( "EulerDKT31 - RK4DKT31" )
print( PermutationTestFDA( v5[firstTimes,],v7[firstTimes,]) )
print( "EulerDKT31 - TendDKT31" )
print( PermutationTestFDA( v5[firstTimes,],v8[firstTimes,]) )
print( "FactDKT31 - RK4DKT31" )
print( PermutationTestFDA( v6[firstTimes,],v7[firstTimes,]) )
print( "FactDKT31 - TendDKT31" )
print( PermutationTestFDA( v6[firstTimes,],v8[firstTimes,]) )
print( "RK4DKT31 - TendDKT31" )
print( PermutationTestFDA( v7[firstTimes,],v8[firstTimes,]) )
