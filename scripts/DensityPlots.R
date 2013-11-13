#! /usr/bin/Rscript --vanilla --default-packages=utils,stats
library(ggplot2)
library(ICC)


d1 <- read.csv("../data/Statistics/density_euler_aal_dice.csv" )[,2]
d2  <- read.csv("../data/Statistics/density_fact_aal_dice.csv" )[,2]
d3 <- read.csv("../data/Statistics/density_rk4_aal_dice.csv" )[,2]
d4 <- read.csv("../data/Statistics/density_tend_aal_dice.csv" )[,2]
d5 <- read.csv("../data/Statistics/density_euler_dkt31_dice.csv" )[,2]
d6  <- read.csv("../data/Statistics/density_fact_dkt31_dice.csv" )[,2]
d7 <- read.csv("../data/Statistics/density_rk4_dkt31_dice.csv" )[,2]
d8 <- read.csv("../data/Statistics/density_tend_dkt31_dice.csv" )[,2]
subs <- length(d1)

alg <- c(rep("Euler",subs),rep("FACT",subs),rep("RK4",subs),rep("TenD",subs))
alg <- c(alg,alg)
labels <- c(rep("AAL",subs*4),rep("DKT31",subs*4))

minaal <- min(d1,d2,d2,d4)
maxaal <- max(d1,d2,d3,d4)
mindkt <- min(d5,d6,d7,d8)
maxdkt <- max(d5,d6,d7,d8)


print( paste("AAL range",minaal,maxaal))
print( paste("DKT range",mindkt,maxdkt))

densityData <- data.frame(Density=c(d1,d2,d3,d4,d5,d6,d7,d8), Algorithm=as.factor(alg), Labels=as.factor(labels) )

densityplot <- ggplot( densityData, aes(x=Algorithm, y=Density, fill=Algorithm) ) + stat_boxplot(geom ='errorbar') + geom_boxplot() + ggtitle("Full graph density") + theme(plot.title = element_text(lineheight=0.5)) + facet_grid(. ~ Labels) + theme(legend.position="none")

png( filename="../data/Statistics/density_plot.png", width=500, height=300 )
print(densityplot)
dev.off()

# Plot diamond shape at mean value
# + stat_summary(fun.y=mean, geom="point", shape=5, size=4)
ids <- as.factor(rep( c(1:(subs/2)), each=2 ))
data1 <- data.frame(Density=d1,Subject=ids)
icc1 <- ICCest(Subject,Density,data1)
data2 <- data.frame(Density=d2,Subject=ids)
icc2 <- ICCest(Subject,Density,data2)
data3 <- data.frame(Density=d3,Subject=ids)
icc3 <- ICCest(Subject,Density,data3)
data4 <- data.frame(Density=d4,Subject=ids)
icc4 <- ICCest(Subject,Density,data4)
data5 <- data.frame(Density=d5,Subject=ids)
icc5 <- ICCest(Subject,Density,data5)
data6 <- data.frame(Density=d6,Subject=ids)
icc6 <- ICCest(Subject,Density,data6)
data7 <- data.frame(Density=d7,Subject=ids)
icc7 <- ICCest(Subject,Density,data7)
data8 <- data.frame(Density=d8,Subject=ids)
icc8 <- ICCest(Subject,Density,data8)

alg <- c("Euler","FACT","RK4","TenD","Euler","FACT","RK4","TenD")
labels <- c(rep("AAL",4),rep("DKT31",4))
icc <- c(icc1$ICC, icc2$ICC, icc3$ICC, icc4$ICC, icc5$ICC, icc6$ICC, icc7$ICC, icc8$ICC)
lci <- c(icc1$LowerCI, icc2$LowerCI, icc3$LowerCI, icc4$LowerCI, icc5$LowerCI, icc6$LowerCI, icc7$LowerCI, icc8$LowerCI)
uci <- c(icc1$UpperCI, icc2$UpperCI, icc3$UpperCI, icc4$UpperCI, icc5$UpperCI, icc6$UpperCI, icc7$UpperCI, icc8$UpperCI)
iccdata <- data.frame(Algorithm=alg, Labels=labels, ICC=icc, LowerCI=lci, UpperCI=uci)
write.csv(iccdata,"../data/Statistics/density_icc.csv") 
