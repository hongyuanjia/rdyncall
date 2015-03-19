# Example from GLPK Reference Manual.. rewritten to R.

dynport(glpk)
lp = glp_create_prob();
glp_set_prob_name(lp, "sample");
glp_set_obj_dir(lp, GLP_MAX);
glp_add_rows(lp, 3);
glp_set_row_name(lp, 1, "p");
glp_set_row_bnds(lp, 1, GLP_UP, 0.0, 100.0);
glp_set_row_name(lp, 2, "q");
glp_set_row_bnds(lp, 2, GLP_UP, 0.0, 600.0);
glp_set_row_name(lp, 3, "r");
glp_set_row_bnds(lp, 3, GLP_UP, 0.0, 300.0);
glp_add_cols(lp, 3);
glp_set_col_name(lp, 1, "x1");
glp_set_col_bnds(lp, 1, GLP_LO, 0.0, 0.0);
glp_set_obj_coef(lp, 1, 10.0);
glp_set_col_name(lp, 2, "x2");
glp_set_col_bnds(lp, 2, GLP_LO, 0.0, 0.0);
glp_set_obj_coef(lp, 2, 6.0);
glp_set_col_name(lp, 3, "x3");
glp_set_col_bnds(lp, 3, GLP_LO, 0.0, 0.0);
glp_set_obj_coef(lp, 3, 4.0);

ia = integer(1+1000)
ja = integer(1+1000)
ar = double(1+1000)

#we index at 1 in C (second position).. but in R we start at initial position..
ia[1]=1;ja[1]=1;ar[1]= 1.0; 
ia[2]=1;ja[2]=2;ar[2]= 1.0;
ia[3]=1;ja[3]=3;ar[3]= 1.0;
ia[4]=2;ja[4]=1;ar[4]= 10.0; 
ia[5]=3;ja[5]=1;ar[5]= 2.0;
ia[6]=2;ja[6]=2;ar[6]= 4.0;
ia[7]=3;ja[7]=2;ar[7]= 2.0;
ia[8]=2;ja[8]=3;ar[8]= 5.0;
ia[9]=3;ja[9]=3;ar[9]= 6.0;

#now we prefix with '0' .. so that our values the above start at 1 in C.

ia <- as.integer(c(0,ia))
ja <- as.integer(c(0,ja))

glp_load_matrix(lp, 9, ia, ja, ar);
glp_simplex(lp, NULL);
z = glp_get_obj_val(lp);
x1 = glp_get_col_prim(lp, 1);
x2 = glp_get_col_prim(lp, 2);
x3 = glp_get_col_prim(lp, 3);

print(list(z=z,x1=x1,x2=x2,x3=x3))
glp_delete_prob(lp);
