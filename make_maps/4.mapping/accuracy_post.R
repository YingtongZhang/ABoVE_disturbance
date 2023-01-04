# Accuracy Assessment
#
# post-stratification
# the map has changed after the stratification
# disturbance map is the overlaid stacks through 1987 to 2012
#
# reference: Stephen V. Stehman (2014) Estimating area and map accuracy for stratified random sampling 
# when the strata are different from the map classes, International Journal of Remote Sensing, 35:13, 4923-4939
#
# Created On: 02/20/2020
# -------------------------------------------------------


# AA
# calclate accuracy
rm(list=ls())
library(ggplot2)

<<<<<<< HEAD
#mPath <- '/Users/zhangyt/Google Drive/PhD/Projects/ABoVE/Accuracy/AA_final_map/'
mPath <- '/Users/Yingtong/Google Drive/PhD/Projects/ABoVE/Accuracy/AA_final_map/'
sfile <- paste(mPath,'post_strat/sort_table_to_3c/STRATA_MAP_INTP_3C.csv',sep='')
strfile <- paste(mPath, 'post_strat/sort_table_to_3c/stratum.csv',sep='')
oPath <- paste(mPath,'post_strat/sort_table_to_3c/',sep='')
# sfile <- paste(mPath,'post_strat/dist_nodist/STRATA_MAP_INTP_1C.csv',sep='')
# strfile <- paste(mPath, 'post_strat/dist_nodist/stratum.csv',sep='')
# oPath <- paste(mPath,'post_strat/dist_nodist/',sep='')
# sfile <- paste(mPath,'post_strat/split_fire/STRATA_MAP_INTP_4C.csv',sep='')
# strfile <- paste(mPath, 'post_strat/split_fire/stratum.csv',sep='')
# oPath <- paste(mPath,'post_strat/split_fire/',sep='')
=======
mPath <- '/Users/zhangyt/Google Drive/PhD/Projects/ABoVE/Accuracy/AA_final_map/'
# mPath <- '/Users/Yingtong/Google Drive/PhD/Projects/ABoVE/Accuracy/AA_final_map/'
# sfile <- paste(mPath,'post_strat/sort_table_to_3c/STRATA_MAP_INTP_3C.csv',sep='')
# strfile <- paste(mPath, 'post_strat/sort_table_to_3c/stratum.csv',sep='')
# oPath <- paste(mPath,'post_strat/sort_table_to_3c/',sep='')
sfile <- paste(mPath,'post_strat/dist_nodist/STRATA_MAP_INTP_1C.csv',sep='')
strfile <- paste(mPath, 'post_strat/dist_nodist/stratum.csv',sep='')
oPath <- paste(mPath,'post_strat/dist_nodist/',sep='')

>>>>>>> 8c0cdddc3fe85b972884e7f7e2dddaeb5758bbaf

## remember to swith between 2, 4, and 6
# 2: Disturbance or NoDisturbance
# 4: Fire, Insect, Logging (3C), and NoDisturbance
# 6：FNFire, Insect, Logging, Other, NNFire, and NoDisturbance 
nClass <- function(x, n){
  substr(x, nchar(x)-n+1, nchar(x)-n+1)
}
const <- as.numeric(nClass(sfile,6)) + 1 
print(const)

# read the data
sampledata <- read.table(sfile,sep=',',stringsAsFactors=F,header=T)
#samples_comb <- sampledata
#samples_comb[samples_comb$STRATA < 7, "STRATA"] <- 0
stratum_sizes <- read.table(strfile,sep=',',stringsAsFactors=F,header=T)

##############
# indicators #
##############

# if pixel u is reference class (14)
indicator <- function(sample,inclass){
  
  if (sample == inclass){
    yu = 1
  }
  else{
    yu = 0
  }
  
  return(yu)
  
}

# if pixel u is classified correctly (12)
indicator1 <- function(map, reference){
  
  if ((map == reference) | (map < 7) & (reference == 0)){
    yu = 1
  }
  else{
    yu = 0
  }
  
  return(yu)
  
}

# if pixel u is map class (19)
indicator0 <- function(map,inclass){
  
  if ((map == inclass) | (map < 7) & (inclass == 0)){
    xu = 1
  }
  else{
    xu = 0
  }
  
  return(xu)
  
}

# if pixel u is classified correctly and has map class (18)
indicator2 <- function(map,ref,class){
  
  x1 = indicator0(map,class)
  x2 = indicator1(map,ref)
  if (x1*x2 == 1){
    yu = 1
  }
  else{
    yu = 0
  }
  
  return(yu)
}

# if pixel u is reference class (23)
indicator00 <- function(ref,class){
  
  if (ref == class){
    xu = 1
  }
  else{
    xu = 0
  }
  
  return(xu)
}

# if pixel u is correctly classified and has reference class (22)
indicator3 <- function(map,ref,class){
  
  x1 = indicator00(ref,class)
  x2 = indicator1(map,ref)
  if (x1*x2 == 1){
    yu = 1
  }
  else{
    yu = 0
  }
  
  return(yu)
}


plot_area <- function(o_area, se_area, nc){

  # acquire stratum
  stratum_s <- stratum_sizes$size[1:nc]
  stratum_size <- sum(stratum_s)


  AgentsCom <- list(c("No Disturbance", "Disturbance"), c("No Disturbance", "Fire", "Insect", "Logging"), c("No Disturbance", "FNFire", "Insect", "Logging", "FNothers", "NNfire"))
  agents <- AgentsCom[[nc/2]]
  area <- stratum_size * o_area * (30^2) / (1000^2)
  area_ci <- stratum_size * se_area * (30^2) / (1000^2) * 1.96
  map.area <- stratum_s * (30^2) / (1000^2)
  df <- data.frame("Agents"=agents, "Area.estimates" = area, "ci0" = area-area_ci, "ci1" = area+area_ci, stringsAsFactors = F, "Map.Area" = map.area)

  p1 <- ggplot(df) +
    geom_bar(aes(x=Agents, y=Area.estimates, group = 1), stat="identity", fill="#1175be", alpha=0.7, width=0.45) +
    geom_errorbar(aes(x=Agents, ymin=ci0, ymax=ci1, group = 1), width=0.35, colour="gray6", alpha=0.8, size=0.6) +
    geom_point(aes(x=Agents, y=Map.Area, group = 1), colour="#858585", stat="identity") +
    geom_line(aes(x=Agents, y=Map.Area, group = 1), colour="#858585", stat="identity") +
    coord_flip() +
    theme_bw() +
    theme(panel.border = element_blank(), axis.text = element_text(size=10.5),
          axis.line = element_line(size=0.5, colour = "black")) +
    scale_y_continuous(name = "Agent estimates (km2)",
                       limits=c(0, 4e6),
                       labels = comma)

  # ggsave("ALL_3agent.png", plot = p1, device = NULL,
  #        path = oPath,
  #        width = 8.1,
  #        height = 5,
  #        units = c("in"),
  #        dpi = 300)


  # zoom in
  df_dist <- df[-1,]
  p2 <- ggplot(df_dist) +
    geom_bar(aes(x=Agents, y=Area.estimates, group = 1), stat="identity", fill="#1175be", alpha=0.7, width=0.45) +
    geom_errorbar( aes(x=Agents, ymin=ci0, ymax=ci1, group = 1), width=0.35, colour="gray6", alpha=0.8, size=0.6) +
    geom_point(aes(x=Agents, y=Map.Area, group = 1), colour="#858585", stat="identity") +
    geom_line(aes(x=Agents, y=Map.Area, group = 1), colour="#858585", stat="identity") +
    coord_flip() +
    theme_bw() +
    theme(panel.border = element_blank(), axis.text = element_text(size=10.5),
          axis.line = element_line(size=0.5, colour = "black")) +
    scale_y_continuous(name = "Agent estimates (km2)",
                       limits=c(0, 5e5),
                       labels = comma)

  # ggsave("ALL_3agent_nobreak.png", plot = p2, device = NULL,
  #        path = oPath,
  #        width = 7.2,
  #        height = 4.6,
  #        units = c("in"),
  #        dpi = 300)

}



# summary statistics 
calc_estimates <- function(s_area_mean, s_overall_mean, s_users_mean, s_prods_mean, 
                           s_area_var, s_overall_var, s_users_var, s_prods_var, 
                           s_users_cov, s_prods_cov, nc, verbose=T){
  
  # acquire stratum
  #stratum_s <- stratum_sizes$size.1[1:6]
  stratum_s <- stratum_sizes$size
  #stratum_size_s <- sum(stratum_s)
  stratum_size_s <- sum(stratum_s)
  
  # initialize accuray
  o_area <- matrix(0,nc)
  o_users <- matrix(0,nc)
  a0=b0=o_users
  o_prods <- matrix(0,nc)
  a1=b1=o_prods
  c0 <- matrix(0,nc)
  c1=c0
  
  #initialize SE
  se_area <- matrix(0,nc)
  se_users <- matrix(0,nc)
  se_prods <- matrix(0,nc)
  
  
  for (i in 2:(length(s_area_mean))){
    
    # proportion of area of classes
    # user's and producer's accuracy
    o_area[i-1] <- (t(stratum_s) %*% s_area_mean[,i]) / stratum_size_s
    a0[i-1] <- (t(stratum_s) %*% s_users_mean[,2*(i-1)])
    b0[i-1] <- (t(stratum_s) %*% s_users_mean[,2*i-1])
    o_users[i-1] <- a0[i-1]/b0[i-1]
    a1[i-1] <- (t(stratum_s) %*% s_prods_mean[,2*(i-1)])
    b1[i-1] <- (t(stratum_s) %*% s_prods_mean[,2*i-1])
    o_prods[i-1] <- a1[i-1]/b1[i-1]
    
    
    # SE (i should be i-1)
    #se_area[i-1] <- sqrt((1/stratum_size_s^2) * (t(stratum_s^2) %*%  (s_area_var[,i] / stratum_sizes$sample.1[1:6])))
    se_area[i-1] <- sqrt((1/stratum_size_s^2) * (t(stratum_s^2) %*%  (s_area_var[,i] / stratum_sizes$sample[1:nc])))
    
    c0 <- s_users_var[,2*(i-1)] + ((o_users[i-1])^2) * s_users_var[,2*i-1] - 2*o_users[i-1] * s_users_cov[,i-1]
    #se_users[i-1] <- sqrt((1/b0[i-1]^2)* (t(stratum_s^2) %*%  (c0 / stratum_sizes$sample.1[1:6]) ))
    se_users[i-1] <- sqrt((1/b0[i-1]^2)* (t(stratum_s^2) %*%  (c0 / stratum_sizes$sample[1:nc]) ))
    c1 <- s_prods_var[,2*(i-1)] + ((o_prods[i-1])^2) * s_prods_var[,2*i-1] - 2*o_prods[i-1] * s_prods_cov[,i-1]
    #se_prods[i-1] <- sqrt((1/b1[i-1]^2)* (t(stratum_s^2) %*%  (c1 / stratum_sizes$sample.1[1:6]) ))
    se_prods[i-1] <- sqrt((1/b1[i-1]^2)* (t(stratum_s^2) %*%  (c1 / stratum_sizes$sample[1:nc]) ))
  }
  
  # overall accuracy
  o_overall <- (t(stratum_s) %*% s_overall_mean[,2]) / stratum_size_s
  
  # overall SE
  #se_overall <- sqrt((1/stratum_size_s^2) * (t(stratum_s^2) %*%  (s_overall_var[,2] / stratum_sizes$sample.1[1:6])))
  se_overall <- sqrt((1/stratum_size_s^2) * (t(stratum_s^2) %*%  (s_overall_var[,2] / stratum_sizes$sample[1:nc])))
  
  
  # print out the results
  if(verbose){
    print('Overall Accuracy: ')
    print(o_overall)
    print("User's Accuracy: ")
    print(o_users)
    print("Producer's Accuracy: ")
    print(o_prods)
    print('Area Proportion: ')
    print(o_area)
    
    print('SE for area proportion: ')
    print(se_area)
    print('SE for Overall Accuracy: ')
    print(se_overall)
    print("SE for User's Accuracy: ")
    print(se_users)
    print("SE for Producer's Accuracy: ")
    print(se_prods)
  }
  
  
  # plot
  
  p1 <- plot_area(o_area, se_area, nc)
}



# stratum-specific statistics (Table 3)
summary_sta <- function(c_area, c_overall, c_users, c_prods, strata, nc){
  
  # original stratum -- res class
  # proportion of area
  samples_area <- cbind(strata, as.data.frame(c_area))
  colnames(samples_area)[1] <- "STRATA"
  s_area_mean <- aggregate(samples_area[,-1], list(samples_area$STRATA), mean)
  s_area_var <- aggregate(samples_area[,-1], list(samples_area$STRATA), var)
  
  # overall accuracy
  samples_overall <- cbind(strata, as.data.frame(c_overall))
  colnames(samples_overall)[1] <- "STRATA"
  s_overall_mean <- aggregate(samples_overall[,2], list(samples_overall$STRATA), mean)
  s_overall_var <- aggregate(samples_overall[,2], list(samples_overall$STRATA), var)
  
  calc_cov <- function(x){
    
    nclass <- sort(unique(samples_users$STRATA))
    cov_mat <- matrix(0, length(nclass), length(x)/2)
    
    for (i in 1:length(nclass)){
      x_sub <- x[x$STRATA == nclass[i],-1]
      for (j in 1:floor(length(x)/2)){
        cov_mat[i,j] <- cov(x_sub[,2*j-1], x_sub[,2*j])
      }
    }
    
    return(cov_mat)
  }
  
  
  # user's accuracy
  samples_users <- cbind(strata, as.data.frame(c_users))
  colnames(samples_users)[1] <- "STRATA"
  s_users_mean <- aggregate(samples_users[,-1], list(samples_users$STRATA), mean)
  s_users_var <- aggregate(samples_users[,-1], list(samples_users$STRATA), var)
  s_users_cov <- calc_cov(samples_users)
  
  # producer's accuracy
  samples_prods <- cbind(strata, as.data.frame(c_prods))
  colnames(samples_prods)[1] <- "STRATA"
  s_prods_mean <- aggregate(samples_prods[,-1], list(samples_prods$STRATA), mean)
  s_prods_var <- aggregate(samples_prods[,-1], list(samples_prods$STRATA), var)
  s_prods_cov <- calc_cov(samples_prods)
  
  results <- calc_estimates(s_area_mean, s_overall_mean, s_users_mean, s_prods_mean, 
                            s_area_var, s_overall_var, s_users_var, s_prods_var, 
                            s_users_cov, s_prods_cov, nc, T)
}

# sample data complementary (Table2)
calc_from_sample <- function(samples, nc){
  
  # get data
  strata_vec <- samples[,'STRATA']
  res_vec <- samples[,'MAP']
  ref_vec <- samples[,'REF']
  
  res_class <- sort(unique(res_vec))      # (1,2,3,4,5,6),7,8,9,10,11
  ref_class <- sort(unique(ref_vec))      # 0,7,8,9,10,11
  
  # initialize result
  c_area <- matrix(0,length(ref_vec),length(ref_class))   # column of id of classes
  c_overall <- matrix(0,length(ref_vec),1)
  c_users <- matrix(0,length(ref_vec),2*length(ref_class))
  c_prods <- matrix(0,length(ref_vec),2*length(ref_class))
  
  # column names
  colnames(c_area) <- c(paste("Area (class ", as.character(ref_class), ")"))
  colnames(c_overall) <- "O"
  base_name <- rep(c("yu", "xu"), times = length(ref_class))
  colnames(c_users) <- c(paste(base_name, "User's (class ", as.character(rep(ref_class, each=2)),  ")"))
  colnames(c_prods) <- c(paste(base_name, "Prod's (class ", as.character(rep(ref_class, each=2)),  ")"))
  
  # proportation of area
  for (j in 1:length(ref_class)){
    iclass = ref_class[j]
    for (i in 1:length(ref_vec)){
      iref = ref_vec[i]
      c_area[i,j] <- indicator(iref,iclass)
    }
  }
  
  # overall accuracy (12)
  for (i in 1:length(ref_vec)){
    imap = res_vec[i]
    iref = ref_vec[i]
    
    c_overall[i,1] <- indicator1(imap,iref)
  }
  
  # user's accuracy (18),(19)
  for (j in 1:length(ref_class)){
    iclass = ref_class[j]
    
    for (i in 1:length(ref_vec)){
      imap = res_vec[i]
      iref = ref_vec[i]
      c_users[i,2*j-1] <- indicator2(imap,iref,iclass)
      c_users[i,2*j] <- indicator0(imap,iclass)
      # (8,11) in the matrix was because of the inaccurate original strata map
      # -- which is changed in the later version of the map
    }
  }
  
  # producer's accuracy (22), (23)
  for (j in 1:length(ref_class)){
    iclass = ref_class[j]
    
    for (i in 1:length(ref_vec)){
      imap = res_vec[i]
      iref = ref_vec[i]
      c_prods[i, 2*j-1] <- indicator3(imap,iref,iclass)
      c_prods[i, 2*j] <- indicator00(iref,iclass)
    }
  }
  
  
  # proportion of area for other row/col Pij
  # TODO
  
  strata <- samples$STRATA
  AA <- summary_sta(c_area, c_overall, c_users, c_prods, strata, nc)
  
}



calc_from_sample(sampledata, const)



# confusion matrix
conf_mat <- function(samples){

  # get data
  res_vec <- samples[,'MAP']
  ref_vec <- samples[,'REF']

  # initialize result
  res_class <- sort(unique(res_vec))
  ref_class <- sort(unique(ref_vec))
  r <- matrix(0,length(res_class),length(ref_class))

  # caculate matrix
  for(i in 1:length(ref_vec)){
    r[res_class==res_vec[i],ref_class==ref_vec[i]] <- r[res_class==res_vec[i],ref_class==ref_vec[i]] + 1
  }
  rownames(r)=res_class
  colnames(r)=ref_class

  # export result
  print(r)

  # done
  return(r)

}

accu <- conf_mat(sampledata)





# ########################################################################################################################
# AA <- function(sta,ref,verbose=T){
#   
#   # read input data
#   sta2 <- read.table(sta,sep=',',stringsAsFactors=F)
#   if(typeof(ref)=='character'){
#     ref2 <- read.table(ref,sep=',',stringsAsFactors=F,header=T)
#   }else{
#     ref2 <- ref
#   }
#   
#   # get information
#   mapCls <- sort(unique(ref2[,'MAP']))
#   staCls <- sta2[,1]
#   staCnt <- sta2[,2]
#   n <- sum(staCnt)
#   nClass <- length(mapCls)
#   nStra <- length(staCls)
#   nRef <- nrow(ref2)
#   nh <- rep(0,nStra)
#   for(i in 1:nStra){
#     nh[i] <- sum(ref2[,'STA']==staCls[i])
#   }
#   
#   # initialize coefficients
#   y_All <- rep(0,nRef)
#   y_User <- matrix(0,nRef,nClass)
#   x_User <- matrix(0,nRef,nClass)
#   y_Prod <- matrix(0,nRef,nClass)
#   x_Prod <- matrix(0,nRef,nClass)
#   y_Area <- matrix(0,nRef,nClass)
#   y_Err <- array(0,c(nClass,nClass,nRef))
#   
#   # initialize coefficient means
#   yh_All <- rep(0,nStra)
#   yh_User <- matrix(0,nClass,nStra)
#   xh_User <- matrix(0,nClass,nStra)
#   yh_Prod <- matrix(0,nClass,nStra)
#   xh_Prod <- matrix(0,nClass,nStra)
#   yh_Area <- matrix(0,nClass,nStra)
#   yh_Err <- array(0,c(nClass,nClass,nStra))
#   
#   # initialize coefficient variances and covariances
#   yv_All <- rep(0,nStra)
#   yv_User <- matrix(0,nClass,nStra)
#   xv_User <- matrix(0,nClass,nStra)
#   co_User <- matrix(0,nClass,nStra)
#   yv_Prod <- matrix(0,nClass,nStra)
#   xv_Prod <- matrix(0,nClass,nStra)
#   co_Prod <- matrix(0,nClass,nStra)
#   yv_Area <- matrix(0,nClass,nStra)
#   
#   # initialize accuracies
#   X_User <- rep(0,nClass)
#   X_Prod <- rep(0,nClass)
#   conf <- matrix(0,nClass,nClass)
#   a_User <- rep(0,nClass)
#   a_Prod <- rep(0,nClass)
#   a_All <- 0
#   area <- rep(0,nClass)
#   
#   # initialize standard error
#   v_Area <- rep(0,nClass)
#   v_User <- rep(0,nClass)
#   v_Prod <- rep(0,nClass)
#   v_All <- 0
#   se_Area <- rep(0,nClass)
#   se_User <- rep(0,nClass)
#   se_Prod <- rep(0,nClass)
#   se_All <- 0
#   
#   # calculation coefficients
#   for(i in 1:nRef){
#     y_All[i] <- (ref2[i,'MAP']==ref2[i,'REF'])
#     y_User[i,] <- (ref2[i,'MAP']==ref2[i,'REF'])&(mapCls==ref2[i,'MAP'])
#     x_User[i,] <- (mapCls==ref2[i,'MAP'])
#     y_Prod[i,] <- (ref2[i,'MAP']==ref2[i,'REF'])&(mapCls==ref2[i,'REF'])
#     x_Prod[i,] <- (mapCls==ref2[i,'REF'])
#     y_Area[i,] <- (mapCls==ref2[i,'REF'])
#     y_Err[which(mapCls==ref2[i,'MAP']),which(mapCls==ref2[i,'REF']),i] <- 1
#   }
#   
#   # calculate coefficients means
#   for(i in 1:nStra){
#     yh_All[i] <- mean(y_All[ref2[,'STA']==staCls[i]])
#     yh_User[,i] <- colMeans(y_User[ref2[,'STA']==staCls[i],])
#     xh_User[,i] <- colMeans(x_User[ref2[,'STA']==staCls[i],])
#     yh_Prod[,i] <- colMeans(y_Prod[ref2[,'STA']==staCls[i],])
#     xh_Prod[,i] <- colMeans(x_Prod[ref2[,'STA']==staCls[i],])
#     yh_Area[,i] <- colMeans(y_Area[ref2[,'STA']==staCls[i],])
#     yh_Err[,,i] <- apply(y_Err[,,ref2[,'STA']==staCls[i]],c(1,2),mean)
#   }
#   
#   # calculate coefficients variance
#   for(i in 1:nStra){
#     yv_All[i] <- var(y_All[ref2[,'STA']==staCls[i]])
#     for(j in 1:nClass){
#       yv_User[j,i] <- var(y_User[ref2[,'STA']==staCls[i],j])
#       xv_User[j,i] <- var(x_User[ref2[,'STA']==staCls[i],j])
#       yv_Prod[j,i] <- var(y_Prod[ref2[,'STA']==staCls[i],j])
#       xv_Prod[j,i] <- var(x_Prod[ref2[,'STA']==staCls[i],j])
#       yv_Area[j,i] <- var(y_Area[ref2[,'STA']==staCls[i],j])
#     }
#   }
#   
#   # calculate coefficients covariance
#   for(i in 1:nStra){
#     for(j in 1:nClass){
#       co_User[j,i] <- var(y_User[ref2[,'STA']==staCls[i],j],x_User[ref2[,'STA']==staCls[i],j])
#       co_Prod[j,i] <- var(y_Prod[ref2[,'STA']==staCls[i],j],x_Prod[ref2[,'STA']==staCls[i],j])
#     }
#   }
#   
#   # calculate accuracies
#   a_All <- (yh_All%*%staCnt)/n
#   for(i in 1:nClass){
#     X_User[i] <- (xh_User[i,]%*%staCnt)
#     X_Prod[i] <- (xh_Prod[i,]%*%staCnt)
#     a_User[i] <- (yh_User[i,]%*%staCnt)/(xh_User[i,]%*%staCnt)
#     a_Prod[i] <- (yh_Prod[i,]%*%staCnt)/(xh_Prod[i,]%*%staCnt)
#     area[i] <- (yh_Area[i,]%*%staCnt)/n
#     for(j in 1:nClass){
#       conf[i,j] <- (yh_Err[i,j,]%*%staCnt)/n
#     }
#   }
#   
#   # calculate standard errors
#   v_All <- (1/n^2)*(((staCnt^2)*(1-nh/staCnt))%*%(yv_All/nh))
#   se_All <- sqrt(v_All)
#   for(i in 1:nClass){
#     v_Area[i] <- (1/n^2)*(((staCnt^2)*(1-nh/staCnt))%*%(yv_Area[i,]/nh))
#     se_Area[i] <- sqrt(v_Area[i])
#     v_User[i] <- (1/X_User[i]^2)*(((staCnt^2)*(1-nh/staCnt))%*%((yv_User[i,]+a_User[i]^2*xv_User[i,]-2*a_User[i]*co_User[i,])/nh))
#     se_User[i] <- sqrt(v_User[i])
#     v_Prod[i] <- (1/X_Prod[i]^2)*(((staCnt^2)*(1-nh/staCnt))%*%((yv_Prod[i,]+a_Prod[i]^2*xv_Prod[i,]-2*a_Prod[i]*co_Prod[i,])/nh))
#     se_Prod[i] <- sqrt(v_Prod[i])
#   }
#   
#   # export results
#   if(verbose){
#     print('Overall Accuracy: ')
#     print(a_All)
#     print("User's Accuracy: ")
#     print(a_User)
#     print("Producer's Accuracy: ")
#     print(a_Prod)
#     print('Area Proportion: ')
#     print(area)
#     print('Confusion Matrix: ')
#     print(conf)
#   }
#   
#   # done
#   return(rbind(a_Prod,a_Prod+se_Prod*1.96,a_Prod-se_Prod*1.96))
#   
# }
# 
# cal_accuracy <- function(dataPath,pct,model,size,samples,sta,m,alpha=-1){
# 
#   if(m=='lag'){
#     lags <- cal_detect_rate(d,dataPath,pct,model,size)
#   }else{
#     lags <- cal_detect_rate2(d,dataPath,pct,model,size)
#   }
#   r <- cal_den(lags[,2])
#   samples$MAP <- 0
#   r <- cbind(r,rep(0,nrow(r)),rep(0,nrow(r)),rep(0,nrow(r)))
# 
#   samples[(samples[,'STA']==alpha)&(samples[,'REF']==1),'MAP'] <- 1
# 
#   for(i in 1:nrow(r)){
#     lags2 <- lags[lags[,2]<=r[i,1],,drop=F]
#     for(j in 1:nrow(lags2)){
#       samples[samples[,'ID']==lags2[j,1],'MAP'] <- 1
#     }
#     accu <- AA(sta,samples,F)
#     r[i,3] <- accu[1,2]
#     r[i,4] <- accu[2,2]
#     r[i,5] <- accu[3,2]
#   }
# 
#   return(cbind(r[,1],r[,3],r[,4],r[,5]))
# }
# 
# cal_detect_rate <- function(d,dataPath,pct,model,size,fd=F){
# 
#   # initialize output
#   if(fd){
#     d <- d[find_dup(d[,'AREA2'])==0,]
#     d$CDATE <- 0
#     for(i in 1:nrow(d)){
#       if(d[i,'D_EVENT']>0){
#         d[i,'CDATE'] <- d[i,'D_EVENT']
#       }else{
#         d[i,'CDATE'] <- d[i,'D_FIRST_NF']
#       }
#     }
#     d <- d[d['CDATE']>=2013000,]
#   }
#   if(length(size)==2){
#     d <- d[d[,'AREA2']>=size[1],]
#     d <- d[d[,'AREA2']<=size[2],]
#   }
# 
#   cat(paste('Total number of events: ',nrow(d),'\n',sep=''))
#   r <- rep(9999,nrow(d))
#   #r <- cbind(r,r)
#   r <- cbind(r,r,r)
# 
#   # loop through events
#   for(i in 1:nrow(d)){
#     # grab info
#     pid <- d[i,'PID']
#     r[i,1] <- pid
#     if(d[i,'D_EVENT']>0){
#       baseDate <- d[i,'D_EVENT']
#     }else{
#       baseDate <- d[i,'D_FIRST_NF']
#     }
#     r[i,3] <- get_doy(d[i,'CDATE'])
#     # read file
#     eventFile <- paste(dataPath,model,'/event_',pid,'.csv',sep='')
#     if(!file.exists(eventFile)){
#       # cat(paste(pid,' file not exist.\n',sep=''))
#       next
#     }
#     e <- read.table(eventFile,sep=',',stringsAsFactors=F,header=T)
#     # calculate date
#     lag <- sub_doy(e[,'DATE'],baseDate)
#     # find lag time for percentile
#     for(k in 1:nrow(e)){
#       if(e[k,'PROP']>=pct){
#         r[i,2] <- lag[k]
#         break
#       }
#     }
#   }
# 
#   # done
#   return(r)
# }
# 
# plot_event <- function(outPath){
#   png(file=paste(outPath,'test.png',sep=''),width=1000,height=1000,pointsize=20)
#   a=cal_detect_rate(events,dPath,0.1,'fu',0,T)
#   plot(a[,3],a[,2],main='Detection Rate',ylab='Detection Rate',xlab='Lag Time',xlim=c(0,400),ylim=c(0,200),bty='n',pch=16,col='blue')
#   box(col='black',lwd=1)
# 
#   abline(h=50,col='grey',lwd=1)
#   abline(h=100,col='grey',lwd=1)
#   abline(h=150,col='grey',lwd=1)
#   abline(h=200,col='grey',lwd=1)
#   abline(h=0,col='grey',lwd=1)
#   #abline(h=300,col='grey',lwd=1)
#   #abline(h=350,col='grey',lwd=1)
# 
#   abline(v=0,col='grey',lwd=1)
#   abline(v=100,col='grey',lwd=1)
#   abline(v=200,col='grey',lwd=1)
#   abline(v=300,col='grey',lwd=1)
#   abline(v=400,col='grey',lwd=1)
# 
# 
#   abline(v=152,col='red',lwd=1)
#   abline(v=304,col='red',lwd=1)
# 
#   dev.off()
# 
# }
# 
# plot_detect_rate <- function(outPath){
# 
#   # all events three sites
#   png(file=paste(outPath,'test3.png',sep=''),width=1000,height=1000,pointsize=20)
#   plot(0,-1,main='Detection Rate',ylab='Detection Rate',xlab='Lag Time',xlim=c(-50,200),ylim=c(0,1),lwd=8,bty='n')
#   a <- cal_accuracy(events,dPath,0.1,'fu',0,samples,strata,'lag')
#   #a2 <- cal_accuracy(events,dPath,0.05,'fu',0,samples,strata,'lag')
#   #a3 <- cal_accuracy(events,dPath,0.1,'fu',0,samples,strata,'lag')
#   #a4 <- cal_accuracy(events,dPath,0.2,'fu',0,samples,strata,'lag')
#   #a5 <- cal_accuracy(events,dPath,0.5,'fu',0,samples,strata,'lag')
#   b <- cal_accuracy(events,dPath,0.1,'mc',0,samples,strata,'lag')
#   #c <- cal_accuracy(events,dPath,0.1,'ti',0,samples,strata,'lag')
#   #a2 <- cal_accuracy(events,dPath2,0.1,'fu',0,samples,strata,'nob')
#   #b <- cal_accuracy(events,dPath2,0.1,'mc',0,samples,strata,'nob')
#   #c <- cal_accuracy(events,dPath2,0.1,'ti',0,samples,strata,'nob')
# 
#   mps <- 231.656
# 
#   box(col='black',lwd=1)
# 
#   polygon(c(a[,1],rev(a[,1])),c(a[,3],rev(a[,4])),col='grey96',border=NA)
#   polygon(c(b[,1],rev(b[,1])),c(b[,3],rev(b[,4])),col='grey90',border=NA)
#   #polygon(c(c[,1],rev(c[,1])),c(c[,3],rev(c[,4])),col='grey90',border=NA)
# 
#   lines(a[,1],a[,2],col='red',lwd=2)
#   lines(a[,1],a[,3],col='red',lwd=1,lty='dashed')
#   lines(a[,1],a[,4],col='red',lwd=1,lty='dashed')
#   #lines(a2[,1],a2[,2],col='red',lwd=2)
#   #lines(a3[,1],a3[,2],col='green',lwd=2)
#   #lines(a4[,1],a4[,2],col='black',lwd=2)
#   #lines(a5[,1],a5[,2],col='green',lwd=2)
#   lines(b[,1],b[,2],col='blue',lwd=2)
#   lines(b[,1],b[,3],col='blue',lwd=1,lty='dashed')
#   lines(b[,1],b[,4],col='blue',lwd=1,lty='dashed')
#   #lines(c[,1],c[,2],col='green',lwd=2)
#   #lines(c[,1],c[,3],col='green',lwd=1,lty='dashed')
#   #lines(c[,1],c[,4],col='green',lwd=1,lty='dashed')
# 
#   abline(h=0.2,col='grey',lwd=1)
#   abline(h=0.4,col='grey',lwd=1)
#   abline(h=0.6,col='grey',lwd=1)
#   abline(h=0.8,col='grey',lwd=1)
#   abline(v=0,col='grey',lwd=1)
#   abline(v=50,col='grey',lwd=1)
#   abline(v=100,col='grey',lwd=1)
#   abline(v=150,col='grey',lwd=1)
# 
#   dev.off()
# 
#   # done
#   return(0)
# }
# 
# # substract doy
# sub_doy <- function(x,y){
#   return((floor(x/1000)-floor(y/1000))*365+((x-floor(x/1000)*1000)-(y-floor(y/1000)*1000)))
# }
# 
# # doy to decimal year
# doy2dy <- function(x){
#   return(floor(x/1000)+(x-floor(x/1000)*1000)/365)
# }
# 
# # calculate density
# cal_den <- function(x){
#   n <- length(x)
#   x2 <- sort(unique(x))
#   y <- rep(0,length(x2))
#   for(i in 1:length(x2)){
#     y[i] <- sum(x<=x2[i])/n
#   }
#   return(cbind(x2,y))
# }
# 
# 
# 
# md = 'ma2'
# pFile <- paste(mPath,'VNRT/analysis2/date/',md,'_pieces.csv',sep='')
# oPath2 <- paste(mPath,'VNRT/analysis2/date/',md,'/',sep='')
# oFile2 <- paste(mPath,'VNRT/analysis2/date/',md,'_result.csv',sep='')
# sum_dates <-function(events,pieceFile,outPath,outFile){
# 
#   # read input file
#   pieces <- read.table(pieceFile,sep=',',stringsAsFactors=F,header=T)
# 
#   # initilize overall output file
#   rall <- matrix(0,nrow(events),13)
#   colnames(rall) <- c('PID','EAREA','DAREA','PROP','DLASTF','DFSTNF','DEXPD','DEVENT','DCLEAR','D25','D50','D75','LAG')
# 
#   # loop through all events
#   for(i in 1:nrow(events)){
# 
#     # get information
#     rall[i,'PID'] <- events[i,'PID']
#     rall[i,'EAREA'] <- events[i,'AREA2']
#     rall[i,'DLASTF'] <- events[i,'D_LAST_F']
#     rall[i,'DFSTNF'] <- events[i,'D_FIRST_NF']
#     rall[i,'DEXPD'] <- events[i,'D_EXPAND']
#     rall[i,'DEVENT'] <- events[i,'D_EVENT']
#     rall[i,'DCLEAR'] <- events[i,'D_CLEAR']
#     event_pieces <- pieces[pieces[,'PID']==rall[i,'PID'],]
#     if(nrow(event_pieces)==0){
#       next
#     }else{
#       event_dates <- sort(unique(event_pieces[,'DDATE']))
#     }
# 
#     # initialize results
#     r <- matrix(0,length(event_dates),6)
#     colnames(r) <- c('PID','EAREA','DATE','DAREA','CAREA','PROP')
#     r[,'PID'] <- rall[i,'PID']
#     r[,'EAREA'] <- rall[i,'EAREA']
#     areasum <- 0
# 
#     # calculate areas and proportions
#     for(j in 1:length(event_dates)){
#       date_pieces <- event_pieces[event_pieces[,'DDATE']==event_dates[j],]
#       r[j,'DATE'] <- event_dates[j]
#       r[j,'DAREA'] <- sum(date_pieces[,'AREA3'])
#       areasum <- areasum+r[j,'DAREA']
#       r[j,'CAREA'] <- areasum
#       r[j,'PROP'] <- r[j,'CAREA']/rall[i,'EAREA']
# 
#       # update overall results
#       if((rall[i,'D25']==0)&(r[j,'PROP']>=0.25)){
#         rall[i,'D25'] <- r[j,'DATE']
#       }
#       if((rall[i,'D50']==0)&(r[j,'PROP']>=0.5)){
#         rall[i,'D50'] <- r[j,'DATE']
#       }
#       if((rall[i,'D75']==0)&(r[j,'PROP']>=0.75)){
#         rall[i,'D75'] <- r[j,'DATE']
#       }
# 
#     }
# 
#     # update overall results
#     rall[i,'DAREA'] <- r[nrow(r),'CAREA']
#     rall[i,'PROP'] <- r[nrow(r),'PROP']
#     if(rall[i,'DEVENT']==0){
#       rall[i,'LAG'] <- sub_doy(rall[i,'D25'],rall[i,'DFSTNF'])
#     }else{
#       rall[i,'LAG'] <- sub_doy(rall[i,'D25'],rall[i,'DEVENT'])
#     }
# 
#     # export result
#     write.table(r,paste(outPath,'event_',rall[i,'PID'],'.csv',sep=''),sep=',',
#                 row.names=F,col.names=T)
#   }
# 
#   # export overall results
#   write.table(rall,outFile,sep=',',row.names=F,col.names=T)
# 
#   # done
#   return(0)
# 
# }
# 
# 
# 
# 
# # get day of year
# get_doy <- function(x){
#   return((x/1000-floor(x/1000))*1000)
# }
# 
# # find duplicate
# find_dup <- function(x){
#   y <- rep(0,length(x))
#   for(i in 1:length(x)){
#     if(sum(x==x[i])>1){
#       if(y[i]==0){
#         y[x==x[i]] <- 1
#         y[i] <- 0
#       }
#     }
#   }
#   return(y)
# }
# 
