; Script to compute the Sinoptic Eddy Vorticity Forcing (SEVF) 
; 
; Lorenzo Zampieri (lorenzo.zampieri@awi.de) 19/04/2020

begin

; --------------- Part 1
; --------------- Load the data & time average

	dir     = "./"      					; model resolution
	file_u 	= "U_bpf"
	fu 	= addfile(dir+file_u, "r")
;        time 	= fu->time
 	plev 	= fu->plev
 	lat 	= fu->lat
 	lon 	= fu->lon
        file_v 	= "V_bpf"
        fv 	= addfile(dir+file_v, "r")
        file_vo = "VO_bpf"
        fvo 	= addfile(dir+file_vo, "r")
        u_vo 	= dim_avg_n_Wrap( (fu->out)*(fvo->out), 0)
        v_vo 	= dim_avg_n_Wrap( (fv->out)*(fvo->out), 0)

; --------------- Part 2
; --------------- Divergence

        dv = uv2dvF_Wrap(u_vo,v_vo)

; --------------- Part 2
; --------------- Laplacian

        sevf = dv(:,:,:)

        do i=0,18
           dv_sel = dv(i,:,:)
           sevf(i,:,:) = -ilapsF_Wrap(dv_sel,0)
        end do

        sevf!0    = "plev"
        sevf&plev = plev
        sevf!1    = "lat"
        sevf&lat = lat
        sevf!2    = "lon"
        sevf&lon = lon

; --------------- Part 4
; --------------- Save variable to file

        var_type  = "float"
        ntim  = 1
	nlev  = dimsizes(plev)                                               
	nlat  = dimsizes(lat)  
	nlon  = dimsizes(lon)      

        system("/bin/rm -f sevf.nc")

	setfileoption("nc","preFill",False)
	setfileoption("nc","defineMode",True)

        f = addfile("sevf.nc","c")

	fAtt               = True            ; assign file attributesfAtt@title         = "NCL Efficient Approach to netCDF Creation"  
	fAtt@title         = "Eddy Vorticity Forcing (SEVF)"  
	fAtt@creation_date = systemfunc ("date")        
	fileattdef( f, fAtt )            ; copy file attributes  

	dims          = dimsizes(sevf)     ; ntim x nlev x nlat x nlev
	dim_names     = getvardims(sevf)   ; "time", "lev", "lat", "lon"
	dim_unlimited = (/False,False,False/)
	filedimdef(f,dim_names,dims,dim_unlimited)

 	filevardef(f,"plev",typeof(sevf&plev),"plev")
  	filevardef(f,"lat", typeof(sevf&lat), "lat")
 	filevardef(f,"lon", typeof(sevf&lon), "lon")
  	filevardef(f,"sevf",typeof(sevf),     dim_names)

        filevarattdef(f,"sevf" ,sevf)                    ; copy sevf attributes
        filevarattdef(f,"plev" ,sevf&plev)               ; copy lev attributes
        filevarattdef(f,"lat"  ,sevf&lat)                ; copy lat attributes
        filevarattdef(f,"lon"  ,sevf&lon)                ; copy lon attributes   

        setfileoption(f,"DefineMode",False)

        f->plev    = (/sevf&plev/)
        f->lat    = (/sevf&lat/)
        f->lon    = (/sevf&lon/) 
        f->sevf   = (/sevf/)                         ; write new variable

end
