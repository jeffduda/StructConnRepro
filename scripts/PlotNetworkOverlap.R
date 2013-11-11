# quantifyCBF
# 
# chen 2011 paper pCASL
# --------------------------------------------------------------------------------------
PlotNetworkOverlap <- function( x,y, low=1, high=NA, interval=NA )
{

  if ( is.na(high) ) {
    high <- length(which(upper.tri(x)))
  }
  if ( is.na(interval) ) {
    interval <- 1
  }

  density <- seq(low,high,interval)

      overlap <- c()
  for ( i in density ) {
    subx <- reduceNetwork(x, N=i)
    suby <- reduceNetwork(y, N=i)
    
    density <- c(density,i)
    overlap <- c(overlap, length(intersect(subx$edgelist,suby$edgelist))/i)
  }

  plot(overlap)
  return(overlap)
  
}
