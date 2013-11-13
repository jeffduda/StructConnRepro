PermutationTestFDA <- function(x,y,n=10000) {
  nx <- dim(x)[1]
  ny <- dim(y)[1]
  #print(paste("orig",dim(x)[1],dim(x)[2],dim(y)[1],dim(y)[2]))
  
  rx <- dim(x)[2]
  ry <- dim(y)[2]

  if ( ry < rx ) {
    rx <- ry
  }

  x <- x[,1:rx]
  y <- y[,1:rx]
  
  groups <- c( rep(0,nx), rep(1,ny) )

  #plot(colMeans(x),type="l")
  #lines(colMeans(y),col="red")
  #Sys.sleep(2)
  
  diff <- sum(abs(colMeans(x)-colMeans(y)))
  nLarger <- 0

  #print(paste("trimmed",dim(x)[1],dim(x)[2],dim(y)[1],dim(y)[2],"diff",diff))
  
  dat <- rbind(x,y)
  for ( i in c(1:n) ) {
    norder <- sample(c(1:(nx+ny)), (nx+ny) )
    a <- norder[1:nx]
    b <- norder[(nx+1):(nx+ny)]

    amat <- dat[a,]
    bmat <- dat[b,]

    #plot( colMeans(amat),type="l" )
    #lines( colMeans(bmat),col="red" )
    #Sys.sleep(2)
    
    abdiff <- sum(abs(colMeans(amat)-colMeans(bmat)))
    #print(paste(dim(amat)[1],dim(amat)[2],dim(bmat)[1], dim(bmat)[2],"diff",abdiff ))
    if ( abdiff > diff ) {
      nLarger <- nLarger + 1
      #print( paste(diff, abdiff) )
    }
  }
  return ( nLarger / n )
}

