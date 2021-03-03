;************************************************************************
  ; =======================================================
  ; INSTRUCTIONS:
  ;
  ; To use this code,
  ; Replace load paths with own locations of ncl libraries
  ;   ~ lines 10-12
  ;
  ; Rosie - I've changed dfdphi slightly because the orginal script said
  ; "latitudinal grid is expected to start at (or near) the north pole"
  ; where as my model grids start at the south pole.
  ; =======================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"

; Author: Felix Bunzel
;         Max-Planck-Instutute for meteorology, March 2010

; History:
;   Mar 2011: due to the introduction of file output after
;             each time step, the make_atts-function was
;             adapted, FB

; This file contains the four ncl-routines dfdp, dfdphi,
; ifdp and make_atts, which are used by the TEM analysis
; code tem.ncl.


; ########### START: dfdp ############

; undefine dfdp
undef("dfdp")

; The function dfdp calculates the level-derivative of a 2D input
; function ff(lev,lat). The given function ftcurvd of the FITGRID
; package is used for the derivation process. It calculates the
; derivatives of an interpolatory spline under tension.
; For the sake of accuracy, coordinate transformation and scaling
; is applied.

; This function expects three parameters:

; 1st: input 2D array (lev,lat), type: double
; 2nd: associated array of levels, type: double
; 3rd: scaling factor, type: double

function dfdp(ff:double,lev:double,alpha:double)

begin

  ; coordinate transformation to z = -ln(p)
  x = -log(lev)

  ; create arrays
  dydx   = new (dimsizes(ff), double)
  result = new (dimsizes(ff), double)

  ; latitude-by-latitude calculation of the derivative
  do ilat=0,dimsizes(ff(0,:))-1

    ; scaling
    y = ff(:,ilat)/(lev^alpha)

    ; derivation
    dydx(:,ilat)   = ftcurvd(x,y,x)

    ; coordinate transformation back to the p-system
    dydx(:,ilat)   = -dydx(:,ilat)/lev

    ; inverse scaling
    result(:,ilat) = (lev^alpha) * (dydx(:,ilat) + (alpha*y/lev))

  end do

  return (result)

end


; ########## START: dfdphi ###########

; undefine dfdphi
undef("dfdphi")

; The function dfdphi calculates the latitude-derivative of an
; n-dimensional input function ff(...,lat), where the rightmost
; is the latitude. The given function ftcurvd of the FITGRID
; package is used for the derivation process. It calculates the
; derivatives of an interpolatory spline under tension.
; The input latitude-grid starts at the north pole. This is why
; a coordinate transformation from to -lat is applied, and reversed
; after the derivation.

; This function expects two parameters:

; 1st: input nD array (...,lat), type: double
; 2nd: associated array of latitudinal grid points, type: double

function dfdphi(ff:double,lat:double)

begin

  ; coordinate transformation to -lat 
  ; Rosie: I don't think I need this if grid starts at south pole? so changed to x = lat
  ;x = -lat
  x = lat

  ; create arrays
  dydx   = new (dimsizes(ff), double)

  ; derivation
  y      = ff
  dydx   = ftcurvd(x,y,x)

  ; reverse coordinate transformation (don't need this if grid starts at south pole as for CNRM?)
  ; Rosie: I don't think I need this as I used x = lat (not x = -lat)
  ;dydx   = -dydx

  return (dydx)

end


; ########### START: ifdp ############

; undefine ifdp
undef("ifdp")

; The function ifdp calculates the level-integral of an
; n-dimensional input function ff(...,lat), where the rightmost
; is the latitude. The given function ftcurvi of the FITGRID
; package is used for the integration process. It calculates
; integrals of an interpolatory spline under tension between
; user-specified limits.

; This function expects two parameters:

; 1st: input 1D array (lev), type: double
; 2nd: associated array of all relevant levels, type: double

function ifdp(ff:double,lev:double)

begin

  ; integration
  x = lev
  y = ff
  result = ftcurvi(min(x),max(x),x,y)

  return(result)

end


; ######### START: make_atts #########

; undefine make_atts
undef("make_atts")

; The function make_atts creates variable-extensions for a quantity,
; which is supposed to be written to a netCDF-file.

; This function expects seven parameters:

; 1st: input 3D array (time,lev,lat), type: double
; 2nd: long name of the variable, type: string
; 3rd: unit of the variable, type: string
; 4th: code of the variable, type: integer

function make_atts(ff:double,name:string,unit:string,code:integer)

begin

  ; write and name coordinate variables
  ff!0                 = "lev"
  ff!1                 = "lat"

  ; write long name
  ff@long_name         = name

  ; write unit
  ff@units             = unit

  ; write code
  ff@code              = code

  ; write grid type
  ff@grid_type         = "gaussian"

  return(ff)

end
