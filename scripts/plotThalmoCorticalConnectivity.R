# plot thalamo cortical connectivity

getThalamoCorticalConnectivity <- function( )
{
  listIdx <- 1
  matlist <- list()
  files <- list.files(path="/mnt/picsl/jtduda/StructConnRepro/data/MMRR-21_processed/", all.files=TRUE, full.names=TRUE, recursive=TRUE, pattern="*bayes1000_sc.csv")

  subjects <- c()
  
  for ( file in files ) {
    #print( paste( "Reading:", file ))
    if ( file.info(file)$size > 0 ) {
      cmat <- as.matrix(read.csv( file ))
      cmat[is.na(cmat)] <- 0

      print(basename(file))
      id <- substr(basename(file),0,3)
      
      if ( dim(cmat)[1] > 6000 ) {
        leftvals <- (cmat[,4] == 1)
        rightvals <- (cmat[,4] == 2)
        
        lsums <- rowSums( cmat[leftvals,6:12] )
        rsums <- rowSums( cmat[rightvals,13:19] )
        sums <- rowSums( cmat[,6:19] )

        #cmat[,6:19] <- cmat[,6:19] / sums
        cmat[leftvals,6:12 ] <- cmat[leftvals,6:12] / lsums
        cmat[rightvals,13:19 ] <- cmat[rightvals,13:19] / rsums
        cmat[is.nan(cmat)] <- 0
        print(max(cmat[leftvals, 6:12]))
        print(max(cmat[rightvals, 13:19]))

        
        matlist[[listIdx]] <- cmat
        print( paste( listIdx, file ) )
        subjects <- c(subjects, id)
        listIdx <- listIdx + 1
        
      }
      }
    else {
      print( paste("Ignoring empty file:",file))
    }
  }

  return( list(data=matlist, names=subjects) )
}
 

plotThalamoCorticalConnectivity <- function( connectivityMats, names )
{

  labs <- c(1:14)
  labs[ labs > 7 ] <- labs[ labs > 7 ] + 1
  labs <- labs + 1
  regions <- c( "Sensory", "Occipital", "Frontal", "Premotor", "Parietal", "Temporal", "Cingulate")
  revregions <- regions[c(7:1)]
  actualRegions <- c(paste("L",regions), paste("R",revregions))
  plotRegions <- c( "Top", paste("L",regions),"Bottom",paste("R",revregions) )
 
  labs <- c(actualRegions)
  
  values <- c()
  subject <- c()
  hemi <- c()
  labels <- c()
  
  n <- length(connectivityMats)
  for ( i in c(1:n) ) {
    mat <- connectivityMats[[i]]
    id <- names[i]
    
    mat[is.na(mat)] <- 0
    nCol <- dim(mat)[2]

    # divide counts by number of streamlines
    #mat[,6:nCol] <- mat[,6:nCol] / mat[,5]

    lvalues <- (mat[,4] == 1)
    rvalues <- (mat[,4] == 2)
    lvals <- colMeans( mat[lvalues,6:12] )
    rvals <- colMeans( mat[rvalues,13:19] )
    vals <- c(lvals, rvals[c(7:1)])
    
    #vals[ is.na(vals) ] <- 0
    #print(paste( i, sum(vals) ) )
    #print( max(vals) )    
    #vals <- vals[c(c(1:7),c(14:8))]

    values <- c(values, vals)
    #subject <- c(subject, rep(i,length(vals) ) )
    subject <- c(subject, rep(id, length(vals) ) )
    hemi <- c( hemi, rep((i*2-1),7), rep((i*2),7))

    labels <- c(labels, labs)
    
  }

  labels <- factor( labels, levels=plotRegions )
 
  dat <- data.frame( Connectivity=values, subject=as.factor(subject), hemi=as.factor(hemi), labels=labels)

  #x2 <- c(0,0,0,0,0,0)
  #y2 <- c(0,0.01,0.02,0.03,0.04,0.05)
  #textvalues <-c("0.00", "0.01", "0.02", "0.03", "0.04", "0.05" )
  textdat <- data.frame(x2=0.0, y2=0.0, texthere="Text Here")

  xx=seq(0,14,length=10)
  yy=rep(0,10)
  
  g <- ggplot( dat, aes( x=labels, y=Connectivity, colour=subject, group=hemi) ) + geom_line(alpha=0.4) + geom_point(alpha=0.4) + scale_y_continuous(limits=c(-sqrt(var(values)),max(values))) + theme(axis.text.x=element_text(size=7,face="bold"), axis.title.x=element_blank() ) + theme(legend.position = "none")  + ggtitle( "Thalma-Cortical Structural Connectivity" ) + geom_hline(aes(x=xx, y=yy))
  g <- g + coord_polar(theta="x", direction=-1)
  
  #+ geom_text(data=NULL, colour="black", aes(x=0, y=10, label="Text"))
 

  return ( g )
  
}
