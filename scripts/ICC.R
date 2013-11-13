ICC <- function(intra, inter) {

mean <- colMeans(rbind(intra,inter))

intraVar <- apply(intra,1,function(x) x-mean)
intraVar <- intraVar*intraVar
intraVar <- colSums( intraVar )
#intraVar <- intraVar*intraVar

interVar <- apply(inter,1,function(x) x-mean)
interVar <- interVar*interVar
interVar <- colSums( interVar )
#interVar <- interVar*interVar

print(paste(intraVar, ":", interVar))

iccval <- interVar / ( interVar + intraVar )

return(iccval)

}


