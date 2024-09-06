#### R code to plot the vetor between delta tesseled cap
rm(list=ls())

# setwd("/projectnb/landsat/projects/ABOVE/CCDC/Bh13v15/out_tc_Forest")

## load raster packages
library(rgdal)
library(shape)

tc_csv_path = "/projectnb/landsat/users/zhangyt/above/Bh13v15/rand_forest/combined_csv.csv"

data <- read.csv(file=tc_csv_path, header=TRUE, sep=",", stringsAsFactors = FALSE)
data <- na.omit(data)

agent_Fire <- subset(data, agent == "Fire")
agent_Insects <- subset(data, agent == "Insects")
agent_Logging <- subset(data, agent == "Logging")
agent_Urbanization <- subset(data, agent == "Urbanization")
# Fire
bottom_b_f = agent_Fire[, 7]
head_b_f = agent_Fire[, 7] + agent_Fire[, 4]
bottom_g_f = agent_Fire[, 8]
head_g_f = agent_Fire[, 8] + agent_Fire[, 5]
bottom_w_f = agent_Fire[, 9]
head_w_f = agent_Fire[, 9] + agent_Fire[, 6]
# Insects
bottom_b_i = agent_Insects[, 7]
head_b_i = agent_Insects[, 7] + agent_Insects[, 4]
bottom_g_i = agent_Insects[, 8]
head_g_i = agent_Insects[, 8] + agent_Insects[, 5]
bottom_w_i = agent_Insects[, 9]
head_w_i = agent_Insects[, 9] + agent_Insects[, 6]
# Logging
bottom_b_l = agent_Logging[, 7]
head_b_l = agent_Logging[, 7] + agent_Logging[, 4]
bottom_g_l = agent_Logging[, 8]
head_g_l = agent_Logging[, 8] + agent_Logging[, 5]
bottom_w_l = agent_Logging[, 9]
head_w_l = agent_Logging[, 9] + agent_Logging[, 6]
# Urbanization
bottom_b_u = agent_Urbanization[, 7]
head_b_u = agent_Urbanization[, 7] + agent_Urbanization[, 4]
bottom_g_u = agent_Urbanization[, 8]
head_g_u = agent_Urbanization[, 8] + agent_Urbanization[, 5]
bottom_w_u = agent_Urbanization[, 9]
head_w_u = agent_Urbanization[, 9] + agent_Urbanization[, 6]


# plot arrows
# axis_rg <- max(abs(c(bottom_b, bottom_g, bottom_w, head_b, head_g, head_w)))
# xlim <- c(-axis_rg, axis_rg)
# ylim <- c(-axis_rg, axis_rg)

# plot wetness and greenness
xlim <- c(-2500, 2500)
ylim <- c(-1000, 5000)
plot(0, type = "n", xlim = xlim, ylim = ylim, xlab = "delta_wetness", ylab = "delta_greenness",
     main = "Change direction of TC")
# length_bw <- sqrt((head_w - head_b)^2 + (bottom_w - bottom_b)^2)
Arrows(bottom_w_f, bottom_g_f, head_w_f, head_g_f, code = 2, arr.adj = 0.5, 
       arr.type = "curved", lcol = 1)
Arrows(bottom_w_i, bottom_g_i, head_w_i, head_g_i, code = 2, arr.adj = 0.5, 
       arr.type = "curved", lcol = 2)
Arrows(bottom_w_l, bottom_g_l, head_w_l, head_g_l, code = 2, arr.adj = 0.5, 
       arr.type = "curved", lcol = 3)
Arrows(bottom_w_u, bottom_g_u, head_w_u, head_g_u, code = 2, arr.adj = 0.5, 
       arr.type = "curved", lcol = 4)

# plot wetness and brightness
plot(0, type = "n", xlim = xlim, ylim = ylim, xlab = "delta_wetness", ylab = "delta_brightness",
     main = "Change direction of TC")
Arrows(bottom_w_f, bottom_b_f, head_w_f, head_b_f, code = 2, arr.adj = 0.5, 
       arr.type = "curved", lcol = 1)
Arrows(bottom_w_i, bottom_b_i, head_w_i, head_b_i, code = 2, arr.adj = 0.5, 
       arr.type = "curved", lcol = 2)
Arrows(bottom_w_l, bottom_b_l, head_w_l, head_b_l, code = 2, arr.adj = 0.5, 
       arr.type = "curved", lcol = 3)
Arrows(bottom_w_u, bottom_b_u, head_w_u, head_b_u, code = 2, arr.adj = 0.5, 
       arr.type = "curved", lcol = 4)

# plot greenness and brightness
plot(0, type = "n", xlim = xlim, ylim = ylim, xlab = "delta_greenness", ylab = "delta_brightness",
     main = "Change direction of TC")
Arrows(bottom_g_f, bottom_b_f, head_g_f, head_b_f, code = 2, arr.adj = 0.5, 
       arr.type = "curved", lcol = 1)
Arrows(bottom_g_i, bottom_b_i, head_g_i, head_b_i, code = 2, arr.adj = 0.5, 
       arr.type = "curved", lcol = 2)
Arrows(bottom_g_l, bottom_b_l, head_g_l, head_b_l, code = 2, arr.adj = 0.5, 
       arr.type = "curved", lcol = 3)
Arrows(bottom_g_u, bottom_b_u, head_g_u, head_b_u, code = 2, arr.adj = 0.5, 
       arr.type = "curved", lcol = 4)
# angles_bw <- (head_w - head_b)/(bottom_w - bottom_b)


# Arrows(bottom_w, bottom_b, head_w, head_b, code = 2, arr.adj = 0.5, 
#        arr.type = "curved", lcol = 1)
# Arrows(bottom_g_, bottom_b_, head_g_, head_b_, code = 2, arr.adj = 0.5, 
#        arr.type = "curved", lcol = 1:2)
# Arrows(bottom_w, bottom_b, head_w, head_b, code = 2, arr.adj = 0.5, 
#        arr.type = "curved", arr.col = 1:600, lcol = 1:600)

#################
out_sample <- matrix(c(t(ilayer_), t(jlayer_), t(head_b_), t(head_g_), t(head_w_), 
                       t(bottom_b_), t(bottom_g_), t(bottom_w_)), nrow = length(t(ilayer_)))
colnames(out_sample) <- c("max_ID", "min_ID", "head_b", "head_g", "head_w", "bottom_b",
                          "bottom_g", "bottom_W")
write.csv(out_sample, file = "/projectnb/landsat/users/zhangyt/above/Bh13v15/Arrow_plot/after_arrow100_2.csv")


