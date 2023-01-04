
# coding: utf-8

# # ABoVE post-processing with added FDB

from osgeo import gdal, gdal_array, osr, ogr
import numpy as np
import logging
import click
import pdb
from IPython.core.debugger import set_trace
from scipy import stats

"""
The main change of this version (Dec.10)
1)add the additional FDB generated myself -- targetting on the fire out of FDB, and trying not mess up with insect -- but only applied to the fire add in; 
2)insect in the orginal FDB -- fire; 
3)FFdecline -- get back more; 
4)throw less others
"""

logger = logging.getLogger('post_pro_agr')
fill = -32767
window_size = 11
n = window_size
k = int((n - 1) / 2)
window_size_s = 5
ns = window_size_s
ks = int((ns - 1) / 2)


# 3 year fire database window 
def post_process_smoothing(tile_name, combine_dir, category_dir, FFdecline_dir, FNother_dir, lc_dir, fireDB_path, AddfireDB_path, PolyfireDB_path, cropland_path, output_dir):
    
    year_avail = np.arange(1987, 2013, dtype=np.int16)
    #year_avail = np.arange(2002, 2003, dtype=np.int16)
    nrows=6000
    ncols=6000
    
    # cropland mask
    agri_file = cropland_path + 'AGR.' +  tile_name + '.tif'
    agri_ds = gdal.Open(agri_file)
    agri_raster = agri_ds.ReadAsArray()
    agri_array = np.array(agri_raster)
 
    for year in year_avail:
        print(year)
        # the fire database of three-year-range(before, middle, after) --- (before2, before1, current)
        fireYear = []
        fireYear_add = []
        fireYear_poly = []
        cc_file = []
        
        #for i in range(-1, 2):
        for i in range(-2, 1):
            fireDB_filename = ('{0}_fireDB_{1}.tif').format(tile_name, year + i)
            fireYear.append(fireDB_path + fireDB_filename)
        
        # need to be optimized later
        # fire database
        fdb_ds0 = gdal.Open(fireYear[0])
        fdb_raster0 = fdb_ds0.ReadAsArray()
        fdb_array0 = np.array(fdb_raster0)
    
        fdb_ds1 = gdal.Open(fireYear[1])
        fdb_raster1 = fdb_ds1.ReadAsArray()
        fdb_array1 = np.array(fdb_raster1)
    
        fdb_ds2 = gdal.Open(fireYear[2])
        fdb_raster2 = fdb_ds2.ReadAsArray()
        fdb_array2 = np.array(fdb_raster2)

        ########add start
        #automatic add FDB
        for i in range(-1, 2):
            fireDB_filename = ('{0}_FDB_add_{1}.tif').format(tile_name, year + i)
            fireYear_add.append(AddfireDB_path + fireDB_filename)
        
        # fire database
        add_fdb_ds0 = gdal.Open(fireYear_add[0])
        add_fdb_raster0 = add_fdb_ds0.ReadAsArray()
        add_fdb_array0 = np.array(add_fdb_raster0)
    
        add_fdb_ds1 = gdal.Open(fireYear_add[1])
        add_fdb_raster1 = add_fdb_ds1.ReadAsArray()
        add_fdb_array1 = np.array(add_fdb_raster1)
    
        add_fdb_ds2 = gdal.Open(fireYear_add[2])
        add_fdb_raster2 = add_fdb_ds2.ReadAsArray()
        add_fdb_array2 = np.array(add_fdb_raster2)
        
        #mannually drawing FDB
        for i in range(-2, 1):
            fireDB_filename = ('{0}_FireAdd_{1}.tif').format(tile_name, year + i)
            fireYear_poly.append(PolyfireDB_path + fireDB_filename)
        
        # fire database
        if year == 1987:
            addd_fdb_ds0 = gdal.Open(fireYear_poly[2])
            addd_fdb_raster0 = addd_fdb_ds0.ReadAsArray()
            addd_fdb_array0 = np.array(addd_fdb_raster0)

            addd_fdb_array2 = addd_fdb_array1 = addd_fdb_array0
        elif year == 1988:
            addd_fdb_ds1 = gdal.Open(fireYear_poly[1])
            addd_fdb_raster1 = addd_fdb_ds1.ReadAsArray()
            addd_fdb_array1 = np.array(addd_fdb_raster1)

            addd_fdb_ds2 = gdal.Open(fireYear_poly[2])
            addd_fdb_raster2 = addd_fdb_ds2.ReadAsArray()
            addd_fdb_array2 = np.array(addd_fdb_raster2)
              
            addd_fdb_array0 = addd_fdb_array1
        else:
            addd_fdb_ds0 = gdal.Open(fireYear_poly[0])
            addd_fdb_raster0 = addd_fdb_ds0.ReadAsArray()
            addd_fdb_array0 = np.array(addd_fdb_raster0)
    
            addd_fdb_ds1 = gdal.Open(fireYear_poly[1])
            addd_fdb_raster1 = addd_fdb_ds1.ReadAsArray()
            addd_fdb_array1 = np.array(addd_fdb_raster1)
    
            addd_fdb_ds2 = gdal.Open(fireYear_poly[2])
            addd_fdb_raster2 = addd_fdb_ds2.ReadAsArray()
            addd_fdb_array2 = np.array(addd_fdb_raster2)
        #########add end

        
       # disturbance map
        for i in range(-1, 2):
            cc_filename = ('{0}_FF_FN_NF_NN_{1}_cl.tif').format(tile_name, year + i)
            cc_file.append(combine_dir + cc_filename)
        
        cc_ds0 = gdal.Open(cc_file[0])
        cc_raster0 = cc_ds0.ReadAsArray()
        cc_array0 = np.array(cc_raster0)
    
        cc_ds1 = gdal.Open(cc_file[1])
        cc_raster1 = cc_ds1.ReadAsArray()
        cc_array1 = np.array(cc_raster1)
        print(cc_file[1])
            
        if year != 2013:
            cc_ds2 = gdal.Open(cc_file[2])
            cc_raster2 = cc_ds2.ReadAsArray()
            cc_array2 = np.array(cc_raster2)
        else:
            cc_array2 = cc_array1
        
        ## disturbance maps
        #cc_file = combine_dir + tile_name +'_FF_FN_NF_NN_' + str(year) + '_cl.tif'
        #cc_ds = gdal.Open(cc_file)
        #cc_raster = cc_ds.ReadAsArray()
        #cc_array = np.array(cc_raster)

        
        # NNother categories
        ct_file = category_dir + tile_name + '_dTC_NN_' + str(year) + '_cl.tif'
        ct_ds = gdal.Open(ct_file)
        ct_raster = ct_ds.ReadAsArray()
        ct_array = np.array(ct_raster)
        
        # FFdecline dTC
        dFFd_file = FFdecline_dir + tile_name + '_dTC_FFd_' + str(year) + '.tif'
        dFFd_ds = gdal.Open(dFFd_file)
        dFFd_raster = dFFd_ds.ReadAsArray()
        dFFd_array = np.array(dFFd_raster)
        
        # FNother dTC
        dFNo_file = FNother_dir + tile_name + '_dTC_FN_' + str(year) + '.tif'
        dFNo_ds = gdal.Open(dFNo_file)
        dFNo_raster = dFNo_ds.ReadAsArray()
        dFNo_array = np.array(dFNo_raster)
        
        # land cover maps
        lc_af_file = lc_dir + tile_name + '_' + str(year) + '_tc_20180416_noGeo_k55_pam_rf_remap.tif'
        lc_af_ds = gdal.Open(lc_af_file)
        lc_af_raster = lc_af_ds.ReadAsArray()
        lc_af_array = np.array(lc_af_raster)
  
        lc_bf_file = lc_dir + tile_name + '_' + str(year-1) + '_tc_20180416_noGeo_k55_pam_rf_remap.tif'
        lc_bf_ds = gdal.Open(lc_bf_file)
        lc_bf_raster = lc_bf_ds.ReadAsArray()
        lc_bf_array = np.array(lc_bf_raster)
        
        # initialize
        map_array = np.ones((nrows, ncols, 1), dtype=np.int16) * fill 
        
        #preserve the border
        map_array[0:k+1,:, 0] = cc_array1[0:k+1, :]
        map_array[:,0:k+1, 0] = cc_array1[:, 0:k+1]
        map_array[nrows-k:nrows,:,0] = cc_array1[nrows-k:nrows, :]
        map_array[:, nrows-k:nrows,0] = cc_array1[:, nrows-k:nrows]


        # eliminate the noisy pixels
        for i in np.arange(k, nrows - k):
            for j in np.arange(k, ncols - k):  
                cc = int(cc_array1[i, j])
                map_array[i, j, 0] = cc
                
                if cc in [3, 4, 5, 6, 8]:
                    cc0 = cc_array0[i-ks:i+ks+1, j-ks:j+ks+1]    # the year before
                    cc1 = cc_array1[i-ks:i+ks+1, j-ks:j+ks+1]    # the right year
                    cc2 = cc_array2[i-ks:i+ks+1, j-ks:j+ks+1]    # the year after
                    tmp_window = time_window(cc0, cc1, cc2, ks)
                    #tmp_window = cc_array[i-ks:i+ks+1, j-ks:j+ks+1]
                    map_array[i, j, 0] = noise_filter(tmp_window, cc, ct_array[i,j], fill)
        
        
        # if the pixel is FN fire (3)
        for i in np.arange(k, nrows - k):
            for j in np.arange(k, ncols - k):  
                cc = int(map_array[i, j])

                if cc == 3:
                    cc0 = cc_array0[i-k:i+k+1, j-k:j+k+1]
                    cc1 = map_array[i-k:i+k+1, j-k:j+k+1]
                    cc2 = cc_array2[i-k:i+k+1, j-k:j+k+1]
                    tmp_window = time_window(cc0, cc1, cc2, k)
                    #tmp_window = cc_array[i-k:i+k+1, j-k:j+k+1]
                    map_array[i, j, 0] = FNfire_filter(fdb_array0[i, j], fdb_array1[i, j], fdb_array2[i, j],
                                                       add_fdb_array0[i, j], add_fdb_array1[i, j], add_fdb_array2[i, j],
                                                       addd_fdb_array0[i, j], addd_fdb_array1[i, j], addd_fdb_array2[i, j],
                                                       tmp_window)
                else:
                    map_array[i, j, 0] = cc


        # if the pixel is FN insects, FN logging or FN others 
        for i in np.arange(k, nrows - k):
            for j in np.arange(k, ncols - k):
                cc = int(map_array[i, j, 0])
                
                if cc in [4, 5, 6]:
                    cc0 = cc_array0[i-ks:i+ks+1, j-ks:j+ks+1]
                    cc1 = map_array[i-ks:i+ks+1, j-ks:j+ks+1]
                    cc2 = cc_array2[i-ks:i+ks+1, j-ks:j+ks+1]
                    tmp_window = time_window(cc0, cc1, cc2, ks)
                    map_array[i, j, 0] = insc_log_othr_filter(fdb_array0[i, j], fdb_array1[i, j], 
                                                              fdb_array2[i, j], add_fdb_array0[i, j], 
                                                              add_fdb_array1[i, j], add_fdb_array2[i, j],
                                                              addd_fdb_array0[i, j], addd_fdb_array1[i, j], 
                                                              addd_fdb_array2[i, j],tmp_window, cc)

        # if the pixel is NN fire 
        for i in np.arange(k, nrows - k):
            for j in np.arange(k, ncols - k):
                cc = int(map_array[i, j, 0])
                
                if cc == 8:
                    cc0 = cc_array0[i-k:i+k+1, j-k:j+k+1]
                    cc1 = map_array[i-k:i+k+1, j-k:j+k+1]
                    cc2 = cc_array2[i-k:i+k+1, j-k:j+k+1]
                    tmp_window = time_window(cc0, cc1, cc2, k)
                    #tmp_window = map_array[i-k:i+k+1, j-k:j+k+1, 0]
                    map_array[i, j, 0] = NNfire_filter(fdb_array0[i, j], fdb_array1[i, j], fdb_array2[i, j],
                                                       add_fdb_array0[i, j], add_fdb_array1[i, j], 
                                                       add_fdb_array2[i, j], addd_fdb_array0[i, j],
                                                       addd_fdb_array1[i, j], addd_fdb_array2[i, j],
                                                       lc_bf_array[i, j], lc_af_array[i, j], ct_array[i,j], 
                                                       agri_array[i, j], tmp_window, cc)

        # NN others
        for i in np.arange(k, nrows - k):
            for j in np.arange(k, ncols - k):
                cc = int(map_array[i, j, 0])
                
                if cc in [9, 10, 11, 12, 13, 14, 15, 16, 17]:
                    cc0 = cc_array0[i-k:i+k+1, j-k:j+k+1]
                    cc1 = map_array[i-k:i+k+1, j-k:j+k+1]
                    cc2 = cc_array2[i-k:i+k+1, j-k:j+k+1]
                    tmp_window = time_window(cc0, cc1, cc2, k)
                    #tmp_window = map_array[i-k:i+k+1, j-k:j+k+1, 0]
                    map_array[i, j, 0] = NNother_filter(fdb_array0[i, j], fdb_array1[i, j], fdb_array2[i, j],
                                                        add_fdb_array0[i, j], add_fdb_array1[i, j], 
                                                        add_fdb_array2[i, j], addd_fdb_array0[i, j],  
                                                        addd_fdb_array1[i, j],addd_fdb_array2[i, j],tmp_window, cc)
                    
        ######### filter the dTC (FFdecline and FNother) ######
        # if the pixel is FFdecline
        for i in np.arange(k, nrows - k):
            for j in np.arange(k, ncols - k):
                cc = int(map_array[i, j, 0])
                tmp_window = map_array[i-k:i+k+1, j-k:j+k+1, 0]
                
                if cc == 1:
                    # 6 layers -- db, dg, dw, pb, pg, pw
                    # if dTC(dg/dw) of FFdecline smaller than -1000, get the most frequent pixel
                    # among FFdecline and FN classes
                    # last version was -1000 and -500
                    if (-5000 < dFFd_array[1, i, j] < -850) or (-5000 < dFFd_array[2, i, j] < -850):
                        map_array[i, j, 0] = FFd2FN_filter(tmp_window)
                
                elif cc == 6:
                    if (-5000 < dFNo_array[1, i, j] < -400) or (-5000 < dFNo_array[2, i, j] < -400):
                        map_array[i, j, 0] = cc
                    else:
                        map_array[i, j, 0] = 18
        
        
        #####deal with the border#####
        ##original process: preserve the border (problem: committed large area agriculture) 
        #the first (five) column
        for i in np.arange(0, nrows):
            for j in np.arange(0, k):
                cc = int(map_array[i, j, 0])
                lb = max(0, i-k)
                hb = min(i+k, 6000)
                
                if cc == 8:
                    tmp_window1 = map_array[lb:hb, j:j+2*k, 0]
                    win_size = (hb - lb) * (2 * k)
                    print(win_size)
                    map_array[i, j, 0] = edge_NNfire(fdb_array0[i, j], fdb_array1[i, j], fdb_array2[i, j],
                                                     add_fdb_array0[i, j], add_fdb_array1[i, j], 
                                                       add_fdb_array2[i, j], addd_fdb_array0[i, j],
                                                       addd_fdb_array1[i, j], addd_fdb_array2[i, j],
                                                       lc_bf_array[i, j], lc_af_array[i, j], ct_array[i,j], 
                                                       agri_array[i, j], tmp_window1, win_size)
        
        #the last (five) column
        for i in np.arange(0, nrows):
            for j in np.arange(ncols-k, ncols):
                cc = int(map_array[i, j, 0])
                lb = max(0, i-k)
                hb = min(i+k, 6000)
                
                if cc == 8:
                    tmp_window1 = map_array[lb:hb, j-2*k:j, 0]
                    win_size = (hb - lb) * (2 * k)
                    map_array[i, j, 0] = edge_NNfire(fdb_array0[i, j], fdb_array1[i, j], fdb_array2[i, j],
                                                       add_fdb_array0[i, j], add_fdb_array1[i, j], 
                                                       add_fdb_array2[i, j], addd_fdb_array0[i, j],
                                                       addd_fdb_array1[i, j], addd_fdb_array2[i, j],
                                                       lc_bf_array[i, j], lc_af_array[i, j], ct_array[i,j], 
                                                       agri_array[i, j], tmp_window1, win_size)
                    
        #the first (five) row
        for i in np.arange(0, k):
            for j in np.arange(0, ncols):
                cc = int(map_array[i, j, 0])
                lb = max(0, i-k)
                hb = min(i+k, 6000)
                
                if cc == 8:
                    tmp_window1 = map_array[i:i+2*k, lb:hb, 0]
                    win_size = (hb - lb) * (2 * k)
                    map_array[i, j, 0] = edge_NNfire(fdb_array0[i, j], fdb_array1[i, j], fdb_array2[i, j],
                                                       add_fdb_array0[i, j], add_fdb_array1[i, j], 
                                                       add_fdb_array2[i, j], addd_fdb_array0[i, j],
                                                       addd_fdb_array1[i, j], addd_fdb_array2[i, j],
                                                       lc_bf_array[i, j], lc_af_array[i, j], ct_array[i,j], 
                                                       agri_array[i, j], tmp_window1, win_size)
                    
        #the last (five) row
        for i in np.arange(nrows-k, nrows):
            for j in np.arange(0, ncols):
                cc = int(map_array[i, j, 0])
                lb = max(0, i-k)
                hb = min(i+k, 6000)
                
                if cc == 8:
                    tmp_window1 = map_array[i-2*k:i, lb:hb, 0]
                    win_size = (hb - lb) * (2 * k)
                    map_array[i, j, 0] = edge_NNfire(fdb_array0[i, j], fdb_array1[i, j], fdb_array2[i, j],
                                                       add_fdb_array0[i, j], add_fdb_array1[i, j], 
                                                       add_fdb_array2[i, j], addd_fdb_array0[i, j],
                                                       addd_fdb_array1[i, j], addd_fdb_array2[i, j],
                                                       lc_bf_array[i, j], lc_af_array[i, j], ct_array[i,j], 
                                                       agri_array[i, j], tmp_window1, win_size)
                    
               
        
        pp_map_name = tile_name +'_FF_FN_NF_NN_' + str(year) +'_cl_pp.tif'
        outfile = output_dir + pp_map_name

        img_file = gdal.Open(cc_file[1])
        geo_info = img_file.GetGeoTransform()
        ulx = geo_info[0]
        pix_x = geo_info[1]
        uly = geo_info[3]
        pix_y = geo_info[5]
        cols = img_file.RasterXSize
        rows = img_file.RasterYSize
        proj_info = img_file.GetProjection()
        grid_info = {'nrows':rows, 'ncols':cols, 'projection':proj_info, 
                     'ulx':ulx, 'pix_x':pix_x, 'uly':uly, 'pix_y':pix_y}
        gdal_frmt = 'GTiff'
        write_output(map_array, outfile, grid_info, gdal_frmt, band_names=None, ndv=fill)
        
        print(year, "completed")




def time_window(cc0, cc1, cc2, k):
    tmp_window = np.array(cc1)
    for i in np.arange(0, 2*k+1):
        for j in np.arange(0, 2*k+1):
            if tmp_window[i, j] == fill:
                if cc0[i, j] != fill:
                    tmp_window[i, j] = cc0[i, j]
                elif cc2[i, j] != fill:
                    tmp_window[i, j] = cc2[i, j]
    
    return tmp_window


# should eliminate the isolated pixels before ran into any post-processing functions
# we would not touch it for the 2nd version post-processing algorithm
def noise_filter(tmp_window, cc, ct_array, fill):
    window_s = np.array(tmp_window)
    window_s = np.reshape(window_s, ns * ns)
    countF = 0
    countN = 0
    for pix in window_s:
        pix = int(pix)
        # not return anything here, only for statistic
        if pix in [3, 4, 5, 6]:
            countF += 1
        if pix == 8:
            countN += 1
    
    count = countF + countN    
    if count == 1:
        if countF == 1:
            return 6
        elif countN == 1:
            return ct_array
    else:
        return cc


## the changes made here are aiming to solve the fire omission in the firedatabase area
## and some of the confusion between fire and pest damage
def FNfire_filter(fdb_array0, fdb_array1, fdb_array2, add_fdb_array0, add_fdb_array1, add_fdb_array2, addd_fdb_array0, addd_fdb_array1, addd_fdb_array2, tmp_window):
    # if in fire database, it is fire
    if fdb_array0 == 1 or fdb_array1 == 1 or fdb_array2 == 1 or add_fdb_array0 == 1 or add_fdb_array1 == 1 or add_fdb_array2 == 1 or addd_fdb_array0 == 1 or addd_fdb_array1 == 1 or addd_fdb_array2 == 1:
        return 3
    else:
        # if out of fire database
        window = np.array(tmp_window)
        window = np.reshape(window, n * n)
        cc_win_FN = []
        fn_fire = 0
        for pix in window:
            pix = int(pix)
            # not return anything here, only for statistic
            if pix > fill:
                if pix in [3, 8]:
                    fn_fire += 1
                elif pix in [4, 5, 6]:
                    cc_win_FN.append(pix)
                    
        # v0: if more than a half is fire, it is fire.
        # v1: 1/3; v2: 1/4; v3: 50
        if fn_fire > 50:
            return 3
        # else take the most frequent non-fire FN class
        else:
            if cc_win_FN:
                mode = stats.mode(cc_win_FN, axis = None)
                return mode[0]
            # if it is null assign to 3
            else:
                if fn_fire > 10:
                    return 3
                else:
                    return 6


def insc_log_othr_filter(fdb_array0, fdb_array1, fdb_array2, 
                         add_fdb_array0, add_fdb_array1, add_fdb_array2,
                         addd_fdb_array0, addd_fdb_array1, addd_fdb_array2, tmp_window, cc):
    # v0: if the pixel is in the fire database (exact the same year)
    # v1: the year and year before; v2: last two years and this year
    window_s = np.array(tmp_window)
    window_s = np.reshape(window_s, ns * ns)
    if fdb_array0 == 1 or fdb_array1 == 1 or fdb_array2 == 1 or add_fdb_array0 == 1 or add_fdb_array1 == 1 or add_fdb_array2 == 1 or addd_fdb_array0 == 1 or addd_fdb_array1 == 1 or addd_fdb_array2 == 1:
        ## v2: change to the larger window to smooth logging and insect out in the fire database
        #window = np.array(tmp_window)
        #window = np.reshape(window, n * n)
        cc_win_FN = []
        count_fire = count_insect = count_logging = 0
        for pix in window_s:
            pix = int(pix)
            if pix in [3, 4, 5, 6, 8]:
                cc_win_FN.append(pix)
                if pix in [3, 8]:
                    count_fire += 1
                elif pix == 4:
                    count_insect += 1
                elif pix == 5:
                    count_logging += 1
        
        max_count = max(count_fire, 24)
        if cc_win_FN:
            mode = stats.mode(cc_win_FN, axis = None)
            # if the plurality is fire, it is fire
            if (mode[0] == 3) or (mode[0] == 8):
                return 3
            # make sure # of pixel of plurality class larger than the fire total
            elif mode[0] == 4 and count_insect < max_count:
                return 3
            elif mode[0] == 5 and count_logging < 6:
                return 3
            else:
                return mode[0]
        
    # if the pixel is out of the fire database
    else:
        cc_win_FN_no_fire = []
        count_insect = count_logging = 0
        for pix in window_s:
            pix = int(pix)
            if pix in [4, 5, 6]:
                cc_win_FN_no_fire.append(pix)
                #if pix == 4:
                #    count_insect += 1
                #elif pix == 5:
                #    count_logging += 1
        
        if cc_win_FN_no_fire:
            mode = stats.mode(cc_win_FN_no_fire, axis = None)
            #if cc == 4 and count_insect < 3:
            #    return 6
            #elif cc == 5 and count_logging <3:
            #    return 6
            #else:
            if len(cc_win_FN_no_fire) > 2:
                return mode[0]
            else:
                return 6
        else:
            return cc


def NNfire_filter(fdb_array0, fdb_array1, fdb_array2, add_fdb_array0, add_fdb_array1, add_fdb_array2,
                  addd_fdb_array0, addd_fdb_array1, addd_fdb_array2, lc_bf_array, lc_af_array, ct_array, agri_array, tmp_window, cc):
    # if the pixel is in the database
    if fdb_array0 == 1 or fdb_array1 == 1 or fdb_array2 == 1 or add_fdb_array0 == 1 or add_fdb_array1 == 1 or add_fdb_array2 == 1 or addd_fdb_array0 == 1 or addd_fdb_array1 == 1 or addd_fdb_array2 == 1:
        return 8
    
    # if the pixel is outside fire database    
    else:
        ## if there is no land cover change before and after, it is not fire
        #if int(lc_bf_array) == int(lc_af_array):
        #    return ct_array

        #if the land cover is fen or bog or switches between bog and fen, it is not fire
        #mask agricuture fire
        if (agri_array == 2) or (int(lc_bf_array) in [7, 8]) and (int(lc_af_array) in [7, 8]):
            return ct_array

        else:
            # if less than half of pixel is not fire, it is not fire
            window = np.array(tmp_window)
            window = np.reshape(window, n * n)                      
            nn_fire = 0
            for pix in window:
                pix = int(pix)
                if pix in [3, 8]:
                    nn_fire += 1

            # v0: if less than a half is fire, it is not fire
            # v1: 1/3; v2: 1/4; v3: 50
            if nn_fire > 50:
                return 8
            else:
                return ct_array

            
def edge_NNfire(fdb_array0, fdb_array1, fdb_array2, add_fdb_array0, add_fdb_array1, add_fdb_array2,
                  addd_fdb_array0, addd_fdb_array1, addd_fdb_array2, lc_bf_array, lc_af_array, ct_array, agri_array, tmp_window, win_size):
    # if the pixel is in the database
    if fdb_array0 == 1 or fdb_array1 == 1 or fdb_array2 == 1 or add_fdb_array0 == 1 or add_fdb_array1 == 1 or add_fdb_array2 == 1 or addd_fdb_array0 == 1 or addd_fdb_array1 == 1 or addd_fdb_array2 == 1:
        return 8
    
    # if the pixel is outside fire database    
    else:
        if (agri_array == 2) or (int(lc_bf_array) in [7, 8]) and (int(lc_af_array) in [7, 8]):
            return ct_array

        else:
            # if less than half of pixel is not fire, it is not fire
            window = np.array(tmp_window)
            window = np.reshape(window, win_size)                      
            nn_fire = 0
            for pix in window:
                pix = int(pix)
                if pix in [3, 8]:
                    nn_fire += 1
            
            thre = int(win_size*0.7)
            if nn_fire > thre:
                return 8
            else:
                return ct_array            
            
            

def NNother_filter(fdb_array0, fdb_array1, fdb_array2, add_fdb_array0, add_fdb_array1, add_fdb_array2, 
                   addd_fdb_array0, addd_fdb_array1, addd_fdb_array2, tmp_window, cc):
    # if the pixel is in the fire database
    #set_trace()
    if fdb_array0 == 1 or fdb_array1 == 1 or fdb_array2 == 1 or add_fdb_array0 == 1 or add_fdb_array1 == 1 or add_fdb_array2 == 1 or addd_fdb_array0 == 1 or addd_fdb_array1 == 1 or addd_fdb_array2 == 1:
        window = np.array(tmp_window)
        window = np.reshape(window, n * n)
        cc_win_NN = []
        for pix in window:
            pix = int(pix)
            if pix in [8, 9, 10, 11, 12, 13, 14, 15, 16, 17]:
                cc_win_NN.append(pix)
        if cc_win_NN:
            mode = stats.mode(cc_win_NN, axis = None)
            if mode[0] == 8:
                return 8
            else:
                return cc
    else:
        return cc


def FFd2FN_filter(tmp_window):
    # the most frequent pixel among FFdecline and FN classes
    window = np.array(tmp_window)
    window = np.reshape(window, n * n)
    cc_win_FFd_FN = []
    for pix in window:
        pix = int(pix)
        if pix in [1, 3, 4, 5, 6]:
            cc_win_FFd_FN.append(pix)
    if cc_win_FFd_FN:
        mode = stats.mode(cc_win_FFd_FN, axis = None)
        return mode[0]

  


# MAPPING UTILITIES
def write_output(raster, output, grid_info, gdal_frmt, band_names=None, ndv=fill):
    """ Write raster to output file """   

    logger.debug('Writing output to disk')
    driver = gdal.GetDriverByName(str(gdal_frmt))

    if len(raster.shape) > 2:
        nband = raster.shape[2]
    else:
        nband = 1

    ds = driver.Create(
        output,
        grid_info['ncols'], grid_info['nrows'], nband,
        gdal_array.NumericTypeCodeToGDALTypeCode(raster.dtype.type)
    )

    if band_names is not None:
        if len(band_names) != nband:
            logger.error('Did not get enough names for all bands')
            sys.exit(1)

    if raster.ndim > 2:
        for b in range(nband):
            logger.debug('    writing band {b}'.format(b=b + 1))
            ds.GetRasterBand(b + 1).WriteArray(raster[:, :, b])
            ds.GetRasterBand(b + 1).SetNoDataValue(ndv)

            if band_names is not None:
                ds.GetRasterBand(b + 1).SetDescription(band_names[b])
                ds.GetRasterBand(b + 1).SetMetadata({
                    'band_{i}'.format(i=b + 1): band_names[b]
                })
    else:
        logger.debug('    writing band')
        ds.GetRasterBand(1).WriteArray(raster)
        ds.GetRasterBand(1).SetNoDataValue(ndv)

        if band_names is not None:
            ds.GetRasterBand(1).SetDescription(band_names[0])
            ds.GetRasterBand(1).SetMetadata({'band_1': band_names[0]})
    #print(grid_info["projection"])
    ds.SetProjection(grid_info["projection"])
    ## the geo transform goes - ulx, pix_x(w-e pixel resolution), easting, uly, northing, pix_y(n-s pixel resolution, negative value)
    ds.SetGeoTransform((grid_info["ulx"],grid_info["pix_x"],0,
                        grid_info["uly"],0,grid_info["pix_y"]))

    ds = None



@click.command()
@click.option('--tile_name', default='Bh13v15', help='Name of the tile, for example: Bh13v15')
#tile_name = 'Bh02v04'
#print(tile_name, "starts processing.")


def main(tile_name):
    combine_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/new_map/out_classes/'.format(tile_name)
    category_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/new_map/out_category/'.format(tile_name)
    FFdecline_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/new_map/out_tc_4type/'.format(tile_name)
    FNother_dir =FFdecline_dir
    #FNother_dir = r'/projectnb/landsat/users/zhangyt/above/CCDC/{0}/FNother/'.format(tile_name)
    lc_dir = r'/projectnb/modislc/users/jonwang/data/rf/rast/tc_20180416_noGeo_k55_pam_rf/{0}/remap/'.format(tile_name)
    #output_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/new_map/out_pp/'.format(tile_name)
    output_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/new_map/out_pp/remap/'.format(tile_name)
    
    fireDB_path = r'/projectnb/landsat/users/shijuan/above/ABOVE_fires_new/ABOVE_fireDB/' + tile_name + '/'
    AddfireDB_path = r'/projectnb/landsat/users/zhangyt/above/ABOVE_fires/FDB_ADD/' + tile_name + '/'  #automatic additional fire database
    PolyfireDB_path = r'/projectnb/landsat/users/zhangyt/above/ABOVE_fires/FDB_Polygon/shp_year_tile/' + tile_name + '/'  # mannually drawing
    
    cropland_path = r'/projectnb/landsat/users/zhangyt/above/data/NA_cropland/TILES/'
    
    # the smoothing function starts
    post_process_smoothing(tile_name, combine_dir, category_dir, FFdecline_dir, FNother_dir, lc_dir, fireDB_path, AddfireDB_path, PolyfireDB_path, cropland_path, output_dir)


if __name__ == "__main__":
    main()

