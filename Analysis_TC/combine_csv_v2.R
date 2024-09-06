# This script reorganize the csv data sheets. 
rm(list=ls())
tc_csv_path = "/projectnb/landsat/users/zhangyt/above/Bh13v15/rand_forest/val_Bh13v15_tc.csv"
interpt_csv_path = "/projectnb/landsat/users/zhangyt/above/Bh13v15/rand_forest/Ref_Bh13v15.csv"
out_csv_path = "/projectnb/landsat/users/zhangyt/above/Bh13v15/rand_forest/combined_csv.csv"
  
tc_df <- read.csv(file=tc_csv_path, header=TRUE, sep=",",stringsAsFactors=FALSE)
interpt_df <- read.csv(file=interpt_csv_path, header=TRUE, sep=",",stringsAsFactors=FALSE)

n_pix = nrow(interpt_df)
#interpt_df[,7] time
#interpt_df[,9] agent
out_tab = array(NA,dim = c(n_pix, 9))
colnames(out_tab) = c("pix_id","dis_year","agent","db","dg","dw","bb","bg","bw")

# reorder by Pix_ID
interpt_df <- interpt_df[order(interpt_df[,'Pix_ID']),]
out_tab[,'pix_id'] <- interpt_df[,'Pix_ID']
out_tab[,'agent'] <- interpt_df[,'Disturbance_agent']

# get disturbance year
for(i in 1:n_pix){
  dis_time <- interpt_df[i,'Disturbance_time']
  if(!is.na(dis_time)){
    out_tab[i,'dis_year'] = substr(dis_time, start=1, stop=4)
  }
}

# get db, dg, dw
tc_colname = colnames(tc_df)
num_col = length(tc_df[1,])
for(j in 1:n_pix){
  for(k in 1:num_col){
    tc_year = substr(tc_colname[k],start=4, stop=7)
    if(identical(toString(out_tab[j,'dis_year']), tc_year)){
        #print(tc_colname[k])
        dtc = substr(tc_colname[k],start=1, stop=2)
        if(dtc=='db'){
          out_tab[j,'db'] = tc_df[j,tc_colname[k]]
          out_tab[j,'bb'] = tc_df[j,tc_colname[k+3]]
        }
        if(dtc=='dg'){
          out_tab[j,'dg'] = tc_df[j,tc_colname[k]]
          out_tab[j,'bg'] = tc_df[j,tc_colname[k+3]]
        }
        if(dtc=='dw'){
          out_tab[j,'dw'] = tc_df[j,tc_colname[k]]
          out_tab[j,'bw'] = tc_df[j,tc_colname[k+3]]
        }
    }
  }
}
write.table(out_tab,file=out_csv_path,sep=",",col.names=T,row.names=F,quote=F)
