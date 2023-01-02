# Package: rdyncall 
# File: demo/R_ShowMessage.R
# Description: Show R Dialog Message (dynbind demo)

dynbind("R","R_ShowMessage(Z)v;")
R_ShowMessage("hello")

