#! /usr/bin/Rscript --vanilla --default-packages=utils,stats
library(ggplot2)
library(ICC)

pEulerAAL <- read.csv("../data/Statistics/richclub_euler_aal.csv" )
pFactAAL  <- read.csv("../data/Statistics/richclub_fact_aal.csv" )
pRkAAL <- read.csv("../data/Statistics/richclub_rk4_aal.csv" )
pTendAAL <- read.csv("../data/Statistics/richclub_tend_aal.csv" )
  
pEulerDKT <- read.csv("../data/Statistics/richclub_euler_dkt31.csv" )
pFactDKT  <- read.csv("../data/Statistics/richclub_fact_dkt31.csv" )
pRkDKT <- read.csv("../data/Statistics/richclub_rk4_dkt31.csv" )
pTendDKT <- read.csv("../data/Statistics/richclub_tend_dkt31.csv" )

v1 <- as.matrix(pEulerAAL[,2:51])
v2 <- as.matrix(pFactAAL[,2:51])
v3 <- as.matrix(pRkAAL[,2:51])
v4 <- as.matrix(pTendAAL[,2:51])

v5 <- as.matrix(pEulerDKT[,2:51])
v6 <- as.matrix(pFactDKT[,2:51])
v7 <- as.matrix(pRkDKT[,2:51])
v8 <- as.matrix(pTendDKT[,2:51])

m1 <- colMeans(v1)
m2 <- colMeans(v2)
m3 <- colMeans(v3)
m4 <- colMeans(v4)
m5 <- colMeans(v5)
m6 <- colMeans(v6)
m7 <- colMeans(v7)
m8 <- colMeans(v8)

subs <- length(m1)

k=rep(c(3:52),8)

alg <- c(rep("Euler",subs),rep("FACT",subs),rep("RK4",subs),rep("TenD",subs))
alg <- c(alg,alg)
labels <- c(rep("AAL",subs*4),rep("DKT31",subs*4))

id <- rep(c(1:8),each=subs )

data <- data.frame(RichClubCoefficient=c(m1,m2,m3,m4,m5,m6,m7,m8), k=k, Algorithm=as.factor(alg), Labels=as.factor(labels), ID=as.factor(id) )

rcplot <- ggplot( data, aes(x=k, y=RichClubCoefficient, colour=Algorithm, group=ID ) ) + geom_line() + ggtitle("Rich club coefficient") + theme(plot.title = element_text(lineheight=0.5)) + facet_grid(. ~ Labels)
print( "make new plot" )
png( filename="../data/Statistics/richclub_plot.png", width=1000, height=300 )
print(rcplot)
dev.off()
ln <- length(m1)

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

  if ( (i <= dim(v1)[2]) && (var(v1[,i]) > 0.001) ) {
    dat <- data.frame(path=v1[,i],id=ids)
    picc1 <- ICCest(id,path,dat)
    icc1[i] <- picc1$ICC
  }
    
  if ( (i <= dim(v2)[2]) && (var(v2[,i]) > 0.001) ) {
    dat <- data.frame(path=v2[,i],id=ids)
    picc1 <- ICCest(id,path,dat)
    icc2[i] <- picc1$ICC
  }
  
  if ( (i <= dim(v3)[2]) && (var(v3[,i]) > 0.001) ) {
    dat <- data.frame(path=v3[,i],id=ids)
    picc1 <- ICCest(id,path,dat)
    icc3[i] <- picc1$ICC
  }
  
  if ( (i <= dim(v4)[2]) && (var(v4[,i]) > 0.001) ) {
    dat <- data.frame(path=v4[,i],id=ids)
    picc1 <- ICCest(id,path,dat)
    icc4[i] <- picc1$ICC
  }
  
  if ( i <= dim(v5)[2] && (var(v5[,i]) > 0.001) ) {
    dat <- data.frame(path=v5[,i],id=ids)
    picc1 <- ICCest(id,path,dat)
    icc5[i] <- picc1$ICC
  }
  
  if ( i <= dim(v6)[2] && (var(v6[,i]) > 0.001) ) {
    dat <- data.frame(path=v6[,i],id=ids)
    picc1 <- ICCest(id,path,dat)
    icc6[i] <- picc1$ICC
  }
  
  if ( i <= dim(v7)[2] && (var(v7[,i]) > 0.001) ) {
    dat <- data.frame(path=v7[,i],id=ids)
    picc1 <- ICCest(id,path,dat)
    icc7[i] <- picc1$ICC
  }
  
  if ( i <= dim(v8)[2] && (var(v8[,i]) > 0.001) ) {
    dat <- data.frame(path=v8[,i],id=ids)
    picc1 <- ICCest(id,path,dat)
    icc8[i] <- picc1$ICC
  }
}
  
pathiccvalues <- c(icc1,icc2,icc3,icc4,icc5,icc6,icc7,icc8)
pathiccdata <- data.frame(ICC=pathiccvalues, k=k, Algorithm=as.factor(alg), ID=as.factor(id), Labels=as.factor(labels) )
 
pathiccplot <- ggplot( pathiccdata, aes(x=k, y=ICC, colour=Algorithm, group=ID ) ) + geom_line() + ggtitle("ICC of rich club coefficient") + theme(plot.title = element_text(lineheight=0.5)) + facet_grid(. ~ Labels) + geom_hline(aes(yintercept=0.2),linetype="dashed",colour="darkgray") + geom_hline(aes(yintercept=0.4),linetype="dashed",colour="darkgray") + geom_hline(aes(yintercept=0.6),linetype="dashed",colour="darkgray") + geom_hline(aes(yintercept=0.8),linetype="dashed",colour="darkgray") + scale_y_continuous(limits = c(-0.3, 0.9))


png( filename="../data/Statistics/richclub_icc_plot.png", width=1000, height=300 )
print(pathiccplot)
dev.off()


firstTimes <- c(1:21)*2-1
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

