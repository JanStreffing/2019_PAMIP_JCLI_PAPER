;----------------------------------------------------------------------
; bandpass.ncl
;
; Calculates 2-8 day Lanczos bandpass filter 
;=======================================================================
;                  MAIN: 6.4.0 or later
;=======================================================================

begin

;---Set options
  dir     = "./"                      					; directory with file
  var     = getenv("var")             					; model resolution
  fi      = addfile(dir+var+"_bpf_prep", "r")    			; file references (pointers)
  fo      = dir+var+"_bpf.nc"   				        ; file references (pointers)


; import the desired variables for the specified time period		; (time,plev,lat,lon)
  data   = fi->$var$(:,:,:,:)


; construction Lanczos filter
  fca    = 0.25/8                     					; low frequency cutoff
  fcb    = 0.25/2                     					; high frequency cutoff
  nwt    = 31			      					; number of points for filter
  ihp    = 2			      					; 0=highpass 1=lowpass 2=bandpas
  nsigma = 1.			      					; power of the sigma factor
  wgt    = filwgts_lanczos (nwt, ihp, fca, fcb, nsigma)  


; compute running avarage
  out = wgt_runave_n_Wrap (data, wgt, 0, 0)   	; compute running ave


; output to netcdf file
  var_type  = "float"
  system("/bin/rm -f "+fo)

  setfileoption("nc","preFill",False)
  setfileoption("nc","defineMode",True)

  f = addfile(fo,"c")

  fAtt               = True            ; assign file attributesfAtt@title         = "NCL Efficient Approach to netCDF Creation"
  fAtt@title         = "Lanczos 2-8 day bandpass filtered "+var
  fAtt@creation_date = systemfunc ("date")
  fileattdef( f, fAtt )            ; copy file attributes

  dims          = dimsizes(out)     ; ntim x nlev x nlat x nlev
  dim_names     = getvardims(out)   ; "time", "lev", "lat", "lon"
  dim_unlimited = (/True,False,False,False/)
  filedimdef(f,dim_names,dims,dim_unlimited)

  filevardef(f,"plev",typeof(out&plev),"plev")
  filevardef(f,"lat", typeof(out&lat), "lat")
  filevardef(f,"lon", typeof(out&lon), "lon")
  filevardef(f,"out",typeof(out),     dim_names)

  filevarattdef(f,"out" ,out)                    ; copy out attributes
  filevarattdef(f,"plev" ,out&plev)               ; copy lev attributes
  filevarattdef(f,"lat"  ,out&lat)                ; copy lat attributes
  filevarattdef(f,"lon"  ,out&lon)                ; copy lon attributes

  setfileoption(f,"DefineMode",False)

  f->plev    = (/out&plev/)
  f->lat    = (/out&lat/)
  f->lon    = (/out&lon/)
  f->out   = (/out/)                         ; write new variable

end

