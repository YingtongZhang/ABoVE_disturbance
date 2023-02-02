import arcpy
import arcpy.mapping
import numpy as np
import os

# Set up ArcGIS environments
mxd=arcpy.mapping.MapDocument('CURRENT')
dfs = arcpy.mapping.ListDataFrames(mxd,'*')
lyr=arcpy.mapping.ListLayers(mxd)

# get the larger dataframe and list all layers
domain_df  = dfs[0]
domain_df_lyrs=arcpy.mapping.ListLayers(mxd, '*', domain_df)

# Global variables
num_of_frames = 26
half_num_of_frames = 13
fps = 15

# get year label
year_label = arcpy.mapping.ListLayoutElements(mxd, 'TEXT_ELEMENT')[0]


#domain_df_extent = domain_df.extent

# define extent arrary
pointname_list = ['A', 'm1', 'B']
xmin_array = [-1771581.876254060, -2120757.142032760, -2273618.185996800]
ymin_array = [2324533.703920190, 2340107.285546350, 2674486.638666930]
xmax_array = [-796219.9255301290, -1096627.093772620, -1468944.576649550]
ymax_array = [2873174.801202350, 2916180.437692620, 3127115.543924710]




# x to y function
for j in range(len(xmin_array)-1):
  # move the map to the start view
  start_extent = arcpy.Extent(xmin_array[j], ymin_array[j], xmax_array[j], ymax_array[j])
  domain_df.extent = start_extent
  
  # turn off all the disturbance map layers
  for k in range(1987, 2013):
    dis_year_lyr=arcpy.mapping.ListLayers(mxd, "*agents_" + str(k) + "*", domain_df)[0]
    dis_year_lyr.visible=False

  # calculate the movement for each frame
  XMin_steps = np.linspace(xmin_array[j], xmin_array[j+1], num = half_num_of_frames * fps)
  XMax_steps = np.linspace(xmax_array[j], xmax_array[j+1], num = half_num_of_frames * fps)
  YMin_steps = np.linspace(ymin_array[j], ymin_array[j+1], num = half_num_of_frames * fps)
  YMax_steps = np.linspace(ymax_array[j], ymax_array[j+1], num = half_num_of_frames * fps)
  
  # path to save the frames; create one if it doesn't exist
  frame_png_path = "D:/YT/movies/frames_v2/" + pointname_list[j] + '_to_' + pointname_list[j+1]
  os.mkdir(frame_png_path)
  
  # generate frames from A to m1
  if j % 2 == 0:
    start_year = 1987
    year_label.text = str(start_year)

    for i in range(half_num_of_frames * fps):
      frame_XMin = XMin_steps[i]
      frame_XMax = XMax_steps[i]
      frame_YMin = YMin_steps[i]
      frame_YMax = YMax_steps[i]
      
      # update the extent for each frame
      frame_extent = arcpy.Extent(frame_XMin, frame_YMin, frame_XMax, frame_YMax)

      domain_df.extent = frame_extent
      
      # update the year label
      year = start_year + i / fps
      year_label.text = str(year)

      if (i % fps) == 0:
      	dis_year_lyr=arcpy.mapping.ListLayers(mxd, "*agents_" + str(year) + "*", domain_df)[0]
      	dis_year_lyr.visible=True

      # save frames as pngs
      frame_png_fn = frame_png_path + "/" + pointname_list[j] + '_to_' + pointname_list[j+1] + "_" + str(i) + ".png"
      arcpy.mapping.ExportToPNG(mxd, frame_png_fn, "PAGE_LAYOUT", resolution=400)
  
  # generate frames from m1 to B
  else:
    start_year = 2000
    year_label.text = str(start_year)

    for k in range(1987, start_year):
      dis_year_lyr=arcpy.mapping.ListLayers(mxd, "*agents_" + str(k) + "*", domain_df)[0]
      dis_year_lyr.visible=True

    for i in range(half_num_of_frames * fps):
      frame_XMin = XMin_steps[i]
      frame_XMax = XMax_steps[i]
      frame_YMin = YMin_steps[i]
      frame_YMax = YMax_steps[i]

      frame_extent = arcpy.Extent(frame_XMin, frame_YMin, frame_XMax, frame_YMax)

      domain_df.extent = frame_extent

      year = start_year + i / fps
      year_label.text = str(year)

      if (i % fps) == 0:
        dis_year_lyr=arcpy.mapping.ListLayers(mxd, "*agents_" + str(year) + "*", domain_df)[0]
        dis_year_lyr.visible=True
      

      frame_png_fn = frame_png_path + "/" + pointname_list[j] + '_to_' + pointname_list[j+1] + "_" + str(i) + ".png"

      arcpy.mapping.ExportToPNG(mxd, frame_png_fn, "PAGE_LAYOUT", resolution=400)



