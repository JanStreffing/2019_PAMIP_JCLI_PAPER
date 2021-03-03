;************************************************************************
; TO MAKE NCL RUN AT MET OFFICE NEED TO FIRST SET UP LINKS TO NCL LIBRARIES USING (in UNIX window)
; export NCARG_ROOT=/data/nwp1/frca/gensoft/ncl_ncarg-6.3.0.Linux_RHEL6.4_x86_64_nodap_gcc447
; export PATH=$NCARG_ROOT/bin:$PATH
; export NCL_NO_SYSTEM_PAGER=
;
; To run code, need to include realization number to convert (expm)
; ncl 'expm="301"'  NCL_FILES/tem_dynvar_openifs_prim_wap.ncl
;************************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/net/home/h05/hadre/CODE/NCL_FILES/tem_functions_dynvar.ncl"

; Author: Felix Bunzel
;         Max-Planck-Instutute for Meteorology, March 2010
;
; History:
;   May 2010: another way to calculate wtem was added to the comments, FB
;   Jun 2010: small update to speed up the script. avg_dim and
;             conform_dims commands were used to handle multiple
;             dimensions simultaneously. Further speed-up seems to
;             be possible by using these commands in the subroutines, FB
;   Dec 2010: the amount of dimsizes-commands was reduced to a
;             minimum, since their execution was found to take
;             a lot of time, FB
;   Mar 2011: the introduction of file output after each time step
;             drastically reduced the amount of memory required
;             for the computation, FB
;   Aug 2011: H2O tracer added, FB
;   Feb 2016: reduction and modification to adapt to dynvar data request, Hauke Schmidt
;   Dec 2016: extra output for icon evaluation, Elisa Manzini
;   Feb 2018: Removal of warnings due to new version of NCL, Matthias Bittner
;   Sep 2020: Updated to read in separate files for input data and 
;             removed the lat inversion step in dfdphi (tem_functions_dynvar.ncl) as data already starts at south pole, Rosie Eade
;             *Have chosen code options to calculate without wap

begin

  ; This code calculates TEM quantities as they are described in
  ; "Middle Atmosphere Dynamics" by Andrews et al. 1987.
  ; To understand better the meaning of the output quantities of
  ; this code, take a look at page 128.

  ; =======================================================
  ; INSTRUCTIONS:
  ; * Code expects realization number to be entered when run code, see example at line 8.
  ;   You can setup a script to loop through all suitable numbers.
  ;
  ; To use this code, set the filenames for input and output netCDF-files:
  ;   ~ lines 76-86
  ; Replace load paths with own locations of ncl libraries and
  ; tem_functions_dynvar.ncl which should be placed in the same directory as this file
  ;   ~ lines 10-12 (and in tem_functions_dynvar.ncl ~ line 13)
  ; The expected names of the variables and dimensions in the input files are listed below
  ; - you will need to change these in the code if they differ for your files
  ;   e.g. update occurences of wa_in->wap to wa_in->W or whatever your variable is named as
  ;
  ; TEMPERATURE:       T [in K] 	; time plev lat lon
  ; U-WIND:            U [in m/s]	; 
  ; V-WIND:            V [in m/s]
  ; VERTICAL VELOCITY: wap [in Pa/s]
  ;
  ; (or adapt the variable names in the script to your liking)
  ; =======================================================
  ;
  ; As for the coordinate variables, the levels are expected to
  ; be in reverse order, starting at the surface, while the
  ; latitudinal grid is expected to start at (or near) the north pole.
  ; Both the levels as well as the latitudinal grid are expected to
  ; have double precision, while the four input variables t,u,v,omega
  ; are expected to be of type float.
  ; The file tem_functions.ncl contains four ncl-subroutines used by
  ; by this code. It has to be placed in the same directory as this file.

  ; CHANGE INPUT FILE PATHS HERE:
  ta_input = "/data/users/hadre/DATA/PAMIP/external/OpenIFSnew/T159/pdSST-pdSIC/T_11_E"+expm+"_T159.nc"
  ua_input = "/data/users/hadre/DATA/PAMIP/external/OpenIFSnew/T159/pdSST-pdSIC/U_11_E"+expm+"_T159.nc"
  va_input = "/data/users/hadre/DATA/PAMIP/external/OpenIFSnew/T159/pdSST-pdSIC/V_11_E"+expm+"_T159.nc"
  wa_input = "/data/users/hadre/DATA/PAMIP/external/OpenIFSnew/T159/pdSST-pdSIC/W_11_E"+expm+"_T159.nc"
  output =   "/data/users/hadre/DATA/PAMIP/external/OpenIFSnew/T159/pdSST-pdSIC/temnwa_11_E"+expm+"_T159.nc"
  
  ;ta_input = "/data/users/hadre/DATA/PAMIP/external/OpenIFSnew/T159/pdSST-futArcSIC/T_16_E"+expm+"_T159.nc"
  ;ua_input = "/data/users/hadre/DATA/PAMIP/external/OpenIFSnew/T159/pdSST-futArcSIC/U_16_E"+expm+"_T159.nc"
  ;va_input = "/data/users/hadre/DATA/PAMIP/external/OpenIFSnew/T159/pdSST-futArcSIC/V_16_E"+expm+"_T159.nc"
  ;wa_input = "/data/users/hadre/DATA/PAMIP/external/OpenIFSnew/T159/pdSST-futArcSIC/W_16_E"+expm+"_T159.nc"
  ;output =   "/data/users/hadre/DATA/PAMIP/external/OpenIFSnew/T159/pdSST-futArcSIC/temnwa_16_E"+expm+"_T159.nc"

  
print (ta_input) 
print (ua_input) 
print (va_input) 
print (output)
print ("read files...")
  ; open input file
  ta_in = addfile(ta_input,"r")
  ua_in = addfile(ua_input,"r")
  va_in = addfile(va_input,"r")
  wa_in = addfile(wap_input,"r")

  ; set constants
  PI    = 3.1415926d    ; pi
  RD    = 287.05d       ; gas constant for dry air [J/K/kg]
  CPD   = 1005.46d      ; specific heat for dry air [J/K/kg]
  PS    = 101325.0d     ; surface pressure [Pa]
  KAPPA = RD/CPD        ; kappa
  A     = 6371000.0d    ; earth radius [m]
  H     = 7000.0d       ; scale height [m]
  G     = 9.80665d      ; gravity acceleration [m/s^2]
  DAY   = 86400.0d      ; day length [s]
  OMEGA = 2.0d*PI/DAY   ; earth angular rotation velocity [1/s]

  ; pressure correction for hPa input levels
   if (ta_in->plev@units.eq."hPa".or.ta_in->plev@units.eq."millibars") then
    p_corr = 100.0d
   else
    p_corr = 1.0d
   end if

  vdim = new(3,integer)
  vdim = dimsizes(ta_in->T(0,:,:,:))
  time = dimsizes(ta_in->T(:,0,0,0))

  ; create output file
  setfileoption("nc","Format","LargeFile")
  out = addfile(output,"c")

  ; create coordinate variables
  dimNames = (/ "time","plev","lat","lon" /)
  dimSiz = array_append_record(dimsizes(ta_in->T(:,:,:,0)),(/ 1 /),0)
  dimUnlim = (/ False,False,False,False /)
  filedimdef(out,dimNames,dimSiz,dimUnlim)

  filevardef(out, "time", typeof(ta_in->T&time), getvardims(ta_in->T&time))
  filevarattdef(out, "time", ta_in->T&time)
  out->time = (/ta_in->T&time/)

  filevardef(out, "plev", typeof(ta_in->T&plev), getvardims(ta_in->T&plev))
  filevarattdef(out, "plev", ta_in->T&plev)
  out->plev  = (/ta_in->T&plev/)

  filevardef(out, "lat", typeof(ta_in->T&lat), getvardims(ta_in->T&lat))
  filevarattdef(out, "lat", ta_in->T&lat)
  out->lat  = (/ta_in->T&lat/)

  dlon = (/ 0.d /)
  dlon!0="lon"
  filevardef(out, "lon", typeof(dlon), getvardims(dlon))
  out->lon = (/dlon/)
  out->lon@standard_name = (/"longitude"/)
  out->lon@long_name = (/"longitude"/)
  out->lon@units = (/"degrees_east"/)

  ; define netCDF output variables

  filevardef(out,"va","double",(/ "time","plev","lat","lon" /))
  filevardef(out,"wa","double",(/ "time","plev","lat","lon" /))
  filevardef(out,"utendepfdy","double",(/ "time","plev","lat","lon" /))
  filevardef(out,"utendepfdz","double",(/ "time","plev","lat","lon" /))

  filevardef(out,"ta","double",(/ "time","plev","lat","lon" /))
  filevardef(out,"ua","double",(/ "time","plev","lat","lon" /))
  filevardef(out,"vtem","double",(/ "time","plev","lat","lon" /))
  filevardef(out,"wtem","double",(/ "time","plev","lat","lon" /))
  filevardef(out,"psitem","double",(/ "time","plev","lat","lon" /))
  filevardef(out,"epfy","double",(/ "time","plev","lat","lon" /))
  filevardef(out,"epfz","double",(/ "time","plev","lat","lon" /))
  filevardef(out,"utendvtem","double",(/ "time","plev","lat","lon" /))
  filevardef(out,"utendwtem","double",(/ "time","plev","lat","lon" /))
  filevardef(out,"utendepfd","double",(/ "time","plev","lat","lon" /))

  ; start TEM computation
  do t=0,time-1

    ; declare array variables

    va     = new (vdim(0:1), double)
    wa     = new (vdim(0:1), double)
    utendepfdy = new (vdim(0:1), double)
    utendepfdz = new (vdim(0:1), double)

    ta     = new (vdim(0:1), double)
    ua     = new (vdim(0:1), double)
    tb     = new (vdim(0:1), double)
    ub     = new (vdim(0:1), double)
    vb     = new (vdim(0:1), double)
    ob     = new (vdim(0:1), double)
    td     = new (vdim, double)
    ud     = new (vdim, double)
    vd     = new (vdim, double)
    od     = new (vdim, double)
    vub    = new (vdim(0:1), double)
    oub    = new (vdim(0:1), double)
    thb    = new (vdim(0:1), double)
    vthb   = new (vdim(0:1), double)
    othb   = new (vdim(0:1), double)
    psi    = new (vdim(0:1), double)
    chi    = new (vdim(0:1), double)
    vtem     = new (vdim(0:1), double)
    wtem     = new (vdim(0:1), double)
    epfy    = new (vdim(0:1), double)
    epfz    = new (vdim(0:1), double)
    utendvtem = new (vdim(0:1), double)
    utendwtem = new (vdim(0:1), double)
    utendepfd = new (vdim(0:1), double)
    duepy  = new (vdim(0:1), double)
    duepz  = new (vdim(0:1), double)

    ; set latitudinal grid, level grid and the coriolis parameter
    latrad   = ta_in->T&lat * 2 * PI / 360
    levels   = ta_in->T&plev * p_corr
    ;print(levels)
    f = 2 * OMEGA * sin(latrad)



    ; calculate zonal means
    tb   = dim_avg(ta_in->T(t,:,:,:)) ; don't need flt2dble as already double for speedy?
    ub   = dim_avg(ua_in->U(t,:,:,:))
    vb   = dim_avg(va_in->V(t,:,:,:))
    ob   = dim_avg(wa_in->wap(t,:,:,:))

    ; calculate anomaly relative to zonal mean?
    td   = ta_in->T(t,:,:,:) - conform_dims(vdim,dim_avg(ta_in->T(t,:,:,:)),(/0,1/))
    ud   = ua_in->U(t,:,:,:) - conform_dims(vdim,dim_avg(ua_in->U(t,:,:,:)),(/0,1/))
    vd   = va_in->V(t,:,:,:) - conform_dims(vdim,dim_avg(va_in->V(t,:,:,:)),(/0,1/))
    od   = wa_in->wap(t,:,:,:) - conform_dims(vdim,dim_avg(wa_in->wap(t,:,:,:)),(/0,1/))

    ; v' u' bar
    vub  = dim_avg(vd*ud)
    oub  = dim_avg(od*ud)
    thb  = tb*((PS/conform_dims(vdim(0:1),levels,0))^KAPPA)
    vthb = dim_avg(vd*td)*((PS/conform_dims(vdim(0:1),levels,0))^KAPPA)
    othb = dim_avg(od*td)*((PS/conform_dims(vdim(0:1),levels,0))^KAPPA)

print("Processing time step "+(t+1)+" of "+time+"...")

    ; apply TEM analysis
    ; for dfdp derivatives scaling is applied for better accuracy
    ; (variables are rescaled after the derivation process).
    ; the scale factor is the 3rd parameter of the dfdp-call.

    ; ATTENTION: For the sake of simplicity, the p-system is used for calculation of
    ;            all TEM quantities. Afterwards, variables are transformed back to
    ;            the z-system, so that the output is in the z-system.

    ; eddy imposed velocity-streamfunction (this is negative compared to GBM2016?)
    psi(:,:) = -vthb(:,:) / dfdp(thb(:,:),levels,-KAPPA)

    ; residual velocity-streamfunction (i.e. integral part of the mass stream function?)
    do ilat=0,vdim(1)-1

      ; for the uppermost level the integral ifdp (see below) becomes zero
      chi(vdim(0)-1,ilat) = psi(vdim(0)-1,ilat)

      ; for all other levels the integral ifdp is used
      do ilev=0,vdim(0)-2
        chi(ilev,ilat) = ifdp(vb((vdim(0)-1):ilev,ilat),levels((vdim(0)-1):ilev)) + psi(ilev,ilat)
      end do

    end do

    ; v-component of the residual mean meridional circulation
    vtem(:,:) = vb(:,:) + dfdp(psi(:,:),levels,1)

    ; level-by-level calculation of further variables
    ; (this is due to the different dimensionality of the arrays involved in these equations)
    do ilev=0,vdim(0)-1

      ; w-component of the residual mean meridional circulation
      ; Calculate wtem with wap:
      wtem(ilev,:) = ob(ilev,:) - (dfdphi(cos(latrad)*psi(ilev,:),latrad) / A / cos(latrad))

      ; z-component of the Eliassen-Palm flux
      ; Version for if do have wap, i.e. with oub
      epfz(ilev,:) = (-psi(ilev,:)*((-(dfdphi(ub(ilev,:),latrad)-(ub(ilev,:)*tan(latrad)))/A)+f)-oub(ilev,:))*A*cos(latrad)

      ; vtem-contribution to du/dt
      utendvtem(ilev,:) = -vtem(ilev,:) * (((dfdphi(ub(ilev,:),latrad)-(tan(latrad)*ub(ilev,:)))/A)-f) * DAY

    end do

    ; wtem-contribution to du/dt
    utendwtem(:,:) = -wtem(:,:) * dfdp(ub(:,:),levels,0) * DAY

    ; 2D precalculation of further variables (see next lines)
    epfy_temp    = (-dfdp(ub(:,:),levels,0) * psi(:,:)) - vub(:,:)
    duepz_temp  = dfdp(epfz(:,:),levels,1) / A

    epfy(:,:) = epfy_temp(:,:) * A * cos(conform_dims(vdim(0:1),latrad,1))

    ; level-by-level calculation of further variables
    ; (this is necessary due to the different dimensionality of the arrays involved in these equations)
    do ilev=0,vdim(0)-1

      ; div(F)-y-contribution to du/dt
      duepy(ilev,:) = ((dfdphi(epfy(ilev,:),latrad) - (tan(latrad) * epfy(ilev,:))) / A) / (A*cos(latrad)) * DAY

      ; div(F)-z-contribution to du/dt
      duepz(ilev,:) = duepz_temp(ilev,:) / cos(latrad) * DAY

      ; total div(F)-contribution to du/dt
      utendepfd(ilev,:) = duepy(ilev,:) + duepz(ilev,:)

      ; conversion back to z-coordinates
      wtem(ilev,:)   = -(H/levels(ilev)) * wtem(ilev,:)
      epfy(ilev,:)  = epfy(ilev,:) * levels(ilev) / PS
      epfz(ilev,:)  = -epfz(ilev,:) * H / PS
      utendepfd(ilev,:) = utendepfd(ilev,:) 

      ; convert velocity stream functions to mass stream functions
      psi(ilev,:)  = 2 * PI * A * cos(latrad) / G * psi(ilev,:)
      chi(ilev,:)  = 2 * PI * A * cos(latrad) / G * chi(ilev,:)

      ; conversion to units requested by dynvar (m/s^2 instead of m/s/day)
      utendepfd(ilev,:) = utendepfd(ilev,:) / DAY
      utendvtem(ilev,:) = utendvtem(ilev,:) / DAY
      utendwtem(ilev,:) = utendwtem(ilev,:) / DAY

      ; basic state requested by dynvar
      ua(ilev,:) = ub(ilev,:)
      ta(ilev,:) = tb(ilev,:)

      ; extra output to evaluate icon
      va(ilev,:) = vb(ilev,:)
      wa(ilev,:) = -(H/levels(ilev)) * ob(ilev,:)
      utendepfdy(ilev,:) = duepy(ilev,:) / DAY
      utendepfdz(ilev,:) = duepz(ilev,:) / DAY

    end do

    ; delete temporary variables
    delete(epfy_temp)
    delete(duepz_temp)

    ; write variables to netCDF file

    out->va(t,:,:,0)      = make_atts(va,      "zonal mean meridional wind",   "m/s",   6)
    out->wa(t,:,:,0)      = make_atts(wa,      "zonal mean vertical wind",    "m/s",    7)
    out->utendepfdy(t,:,:,0) = make_atts(utendepfdy,  "du/dt by EP-flux y-div",    "m/s^2",    8)
    out->utendepfdz(t,:,:,0) = make_atts(utendepfdz,  "du/dt by EP-flux z-div",    "m/s^2",    9)

    out->ta(t,:,:,0)      = make_atts(ta,      "zonal mean temperature",           "K",    130)
    out->ua(t,:,:,0)      = make_atts(ua,      "zonal mean zonal wind",          "m/s",    131)
    out->vtem(t,:,:,0)      = make_atts(vtem,      "residual mean v-velocity",           "m/s",    132)
    out->wtem(t,:,:,0)      = make_atts(wtem,      "residual mean w-velocity",           "m/s",    135)
    out->psitem(t,:,:,0)    = make_atts(chi,       "residual mass-streamfunction",       "kg/s",   136)
    out->epfy(t,:,:,0)       = make_atts(epfy,       "Eliassen-Palm flux phi-component",   "m^3/s^2", 1  )
    out->epfz(t,:,:,0)       = make_atts(epfz,       "Eliassen-Palm flux z-component",     "m^3/s^2", 2  )
    out->utendvtem(t,:,:,0) = make_atts(utendvtem, "du/dt by vtem-advection",            "m/s^2",3  )
    out->utendwtem(t,:,:,0) = make_atts(utendwtem, "du/dt by wtem-advection",            "m/s^2",4  )
    out->utendepfd(t,:,:,0) = make_atts(utendepfd, "du/dt by EP-flux divergence",        "m/s^2",5  )

    ; delete all variables

    delete(va)
    delete(wa)
    delete(utendepfdy)
    delete(utendepfdz)

    delete(ta)
    delete(ua)
    delete(tb)
    delete(ub)
    delete(vb)
    delete(ob)
    delete(td)
    delete(ud)
    delete(vd)
    delete(od)
    delete(vub)
    delete(oub)
    delete(thb)
    delete(vthb)
    delete(othb)
    delete(psi)
    delete(chi)
    delete(vtem)
    delete(wtem)
    delete(epfy)
    delete(epfz)
    delete(utendvtem)
    delete(utendwtem)
    delete(duepy)
    delete(duepz)
    delete(utendepfd)

  end do

print ("Done!")

end
