# FF -- decline: 1 growth: 2
# FN -- fire: 3 insect: 4 logging: 5 others: 6
# NF -- regrowth: 7
# NN -- fire: 8 comb: 9-17
# 
# *no changes between FF two classes and neither NF
# FN                                                   NN
# 3--4: 1     4--3: 4     5--3: 7     6--3: 10         8--(9, 17): 13
# 3--5: 2     4--5: 5     5--4: 8     6--4: 11         (9,17)--8: 14
# 3--6: 3     4--6: 6     5--6: 9     6--5: 12

csv_dir = "/projectnb/landsat/users/zhangyt/above/post_processing/validation/"

ori_tab_name <- paste0(csv_dir, "attributes_.csv")
ori_tab <- read.csv(ori_tab_name, header = F, sep = "")
add_tab <- matrix(0, nrow = 380, ncol = 2)
ori_tab <- cbind(ori_tab, add_tab)

intp_tab_name <- paste0(csv_dir, "pp_interpretation_all.csv")
intp_tab <- read.csv(intp_tab_name, header = T, stringsAsFactors = F)
colnames(intp_tab) <- c("id", "year", "type", "agent", "conf")

for (i in 1:380){
  current_type <- intp_tab$type[i]
  current_agent <- intp_tab$agent[i]
  current_conf <- intp_tab$conf[i]
  if (current_type == 1){
    if (current_agent == "fire"){
      intp_tab$conf[i] = 3
    }
    else if(current_agent == "insects"){
      intp_tab$conf[i] = 4
    }
    else if(current_agent == "logging"){
      intp_tab$conf[i] = 5
    }
    else if(current_agent == "others"){
      intp_tab$conf[i] = 6
    }
  }
  
  else{
    if (current_agent == "fire"){
      intp_tab$conf[i] = 8
    }
    else if(current_agent == "others"){
      intp_tab$conf[i] = 9
    }
  }
}

ori_tab <- cbind(ori_tab, intp_tab$conf)
colnames(ori_tab) <- c("id", "year", "type", "bf_pp", "af_pp", "intp")

for (i in 1:380){
  current_type <- ori_tab$type[i]
  if (current_type == 1){
    ori_tab$bf_pp[i] = 3
    ori_tab$af_pp[i] = 4
  }
  else if (current_type == 2){
    ori_tab$bf_pp[i] = 3
    ori_tab$af_pp[i] = 5
  }
  else if (current_type == 3){
    ori_tab$bf_pp[i] = 3
    ori_tab$af_pp[i] = 6
  }
  else if (current_type == 4){
    ori_tab$bf_pp[i] = 4
    ori_tab$af_pp[i] = 3
  }
  else if (current_type == 5){
    ori_tab$bf_pp[i] = 4
    ori_tab$af_pp[i] = 5
  }
  else if (current_type == 6){
    ori_tab$bf_pp[i] = 4
    ori_tab$af_pp[i] = 6
  }
  else if (current_type == 7){
    ori_tab$bf_pp[i] = 5
    ori_tab$af_pp[i] = 3
  }
  else if (current_type == 8){
    ori_tab$bf_pp[i] = 5
    ori_tab$af_pp[i] = 4
  }
  else if (current_type == 9){
    ori_tab$bf_pp[i] = 5
    ori_tab$af_pp[i] = 6
  }
  else if (current_type == 10){
    ori_tab$bf_pp[i] = 6
    ori_tab$af_pp[i] = 3
  }
  else if (current_type == 11){
    ori_tab$bf_pp[i] = 6
    ori_tab$af_pp[i] = 4
  }
  else if (current_type == 12){
    ori_tab$bf_pp[i] = 6
    ori_tab$af_pp[i] = 5
  }
  else if (current_type == 13){
    ori_tab$bf_pp[i] = 8
    ori_tab$af_pp[i] = 9
  }
  else if (current_type == 14){
    ori_tab$bf_pp[i] = 9
    ori_tab$af_pp[i] = 8
  }
  
}

ori_tab <- ori_tab[complete.cases(ori_tab),]

x_tab <- table(ori_tab$af_pp, ori_tab$intp)


write.csv(ori_tab, file = "ori_tab_part1.csv")
