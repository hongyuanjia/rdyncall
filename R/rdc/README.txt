rdc package: dyncall R bindings
===============================
(C) 2007-2009 Daniel Adler


Requirement
- dyncall >=0.1 (url: http://dyncall.org)


Status
  unreleased

  
Building from source


  1. Check out source 
    
     > svn checkout https://dyncall.org/svn/dyncall/trunk/bindings/R/rdc rdc

     
  2. Bootstrap dyncall source
  
    * Method A: download zip file method: 
          
     > cd rdc
     > sh bootstrap
     > cd ..
     
    * Method B: checkout dyncall
    
     > svn checkout https://dyncall.org/svn/dyncall/trunk/dyncall rdc/src/dyncall
     
    * Method C: place dyncall source tree rooted at rdc/src/dyncall 

     > cp -R /tmp/dyncall-0.3 rdc/src/dyncall

     
  3. Build R package from source
  
     > R CMD INSTALL rdc

