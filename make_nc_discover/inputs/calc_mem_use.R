
DIM_Y = 6000
YPARTS = 5    
NUM_BANDS = 8
LOC_YRANGE = DIM_Y / YPARTS

size_int = 16
DIM_X = 6000
num_proc = 600
numRows = LOC_YRANGE / num_proc

numFiles = seq(1000,6000,500)
dat_out = size_int*DIM_X*numRows*NUM_BANDS*numFiles

b_to_gb = 1/1000000000
mem_needed_gb = dat_out*b_to_gb
plot(numFiles,mem_needed_gb,xlab="Number of Files",ylab="Memory in GB")

mem_per_node = 124
num_cores = 28
mem_per_core = mem_per_node / num_cores

tot_mem_demand = mem_needed_gb * num_proc

num_proc_use = seq(10,25,5)
num_nodes_need = num_proc / num_proc_use
tot_mem_supply = num_nodes_need * mem_per_node

