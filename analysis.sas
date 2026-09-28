/*==============================================================
  E-Commerce Sales Regression Analysis
  Author: Abdullah Naushab
  Goal:   Find which factors (price, discount, marketing spend,
          customer segment, product category) predict Units Sold
  Data:   Ecommerce_Sales.csv (1,000 rows)
==============================================================*/

/* Part 1: Import data */
PROC IMPORT DATAFILE="Ecommerce_Sales.csv" OUT=ecommerce DBMS=CSV REPLACE;
    GETNAMES=YES;
RUN;

TITLE "Complete E-Commerce Dataset";
PROC PRINT DATA=ecommerce;
RUN;


/* Part 2: Dummy variables */
DATA ecommerce;
    SET ecommerce;

    /* Customer segment (baseline: Occasional) */
    D_Premium = (Customer_Segment = "Premium");
    D_Regular = (Customer_Segment = "Regular");

    /* Product category (baseline: Electronics) */
    D_Sports    = (Product_Category = "Sports");
    D_Toys      = (Product_Category = "Toys");
    D_Fashion   = (Product_Category = "Fashion");
    D_HomeDecor = (Product_Category = "Home Decor");
RUN;

TITLE "Dataset with Dummy Variables";
PROC PRINT DATA=ecommerce;
RUN;


/* Part 3: Exploratory analysis */
TITLE "Summary Statistics";
PROC MEANS DATA=ecommerce N MEAN STD MIN MAX;
    VAR Price Discount Marketing_Spend Units_Sold
        D_Premium D_Regular D_Sports D_Toys D_Fashion D_HomeDecor;
RUN;

TITLE "Distribution of Units Sold";
PROC UNIVARIATE DATA=ecommerce NORMAL;
    VAR Units_Sold;
    HISTOGRAM Units_Sold / NORMAL;
RUN;

TITLE "Boxplot of Units Sold by Product Category";
PROC SORT DATA=ecommerce;
    BY Product_Category;
RUN;
PROC BOXPLOT DATA=ecommerce;
    PLOT Units_Sold*Product_Category;
RUN;

TITLE "Boxplot of Units Sold by Customer Segment";
PROC SORT DATA=ecommerce;
    BY Customer_Segment;
RUN;
PROC BOXPLOT DATA=ecommerce;
    PLOT Units_Sold*Customer_Segment;
RUN;

TITLE "Correlation of Units Sold with All Predictors";
PROC CORR DATA=ecommerce;
    VAR Units_Sold Price Discount Marketing_Spend
        D_Premium D_Regular D_Sports D_Toys D_Fashion D_HomeDecor;
RUN;

TITLE "Scatterplot Matrix";
PROC SGSCATTER DATA=ecommerce;
    MATRIX Units_Sold Price Discount Marketing_Spend
           D_Premium D_Regular D_Sports D_Toys D_Fashion D_HomeDecor;
RUN;

TITLE "Units Sold vs Each Predictor";
PROC GPLOT DATA=ecommerce;
    PLOT Units_Sold * (Price Discount Marketing_Spend
                       D_Premium D_Regular D_Sports D_Toys D_Fashion D_HomeDecor);
RUN;
QUIT;


/* Part 4: Full model + diagnostics */
TITLE "Full Multiple Regression Model with VIF";
PROC REG DATA=ecommerce;
    MODEL Units_Sold = Price Discount Marketing_Spend
                       D_Premium D_Regular D_Sports D_Toys D_Fashion D_HomeDecor
                       / VIF;
RUN;
QUIT;

TITLE "Outliers and Influential Points";
PROC REG DATA=ecommerce;
    MODEL Units_Sold = Price Discount Marketing_Spend
                       D_Premium D_Regular D_Sports D_Toys D_Fashion D_HomeDecor
                       / R INFLUENCE;
RUN;
QUIT;

TITLE "Assumption Checks";
PROC REG DATA=ecommerce;
    MODEL Units_Sold = Price Discount Marketing_Spend
                       D_Premium D_Regular D_Sports D_Toys D_Fashion D_HomeDecor;
    PLOT student.*(Price Discount Marketing_Spend
                   D_Premium D_Regular D_Sports D_Toys D_Fashion D_HomeDecor);
    PLOT student.*predicted.;
    PLOT npp.*student.;
RUN;
QUIT;


/* Part 5: Remove outliers and influential points
   Note: row numbers refer to the dataset AFTER the last PROC SORT
   (sorted by Customer_Segment), so run this script top to bottom. */
DATA ecommerce_clean;
    SET ecommerce;
    IF _N_ IN (17, 36, 76, 92, 103, 110, 111, 120, 156, 186, 193, 229, 231,
               235, 236, 265, 270, 297, 303, 310, 360, 364, 421, 429, 462,
               463, 472, 578, 720, 735, 740, 745, 772, 819, 832, 845, 849,
               863, 870, 884, 930, 942, 956, 968, 974) THEN DELETE;
RUN;

TITLE "Model After Removing Outliers";
PROC REG DATA=ecommerce_clean;
    MODEL Units_Sold = Price Discount Marketing_Spend
                       D_Premium D_Regular D_Sports D_Toys D_Fashion D_HomeDecor
                       / INFLUENCE R;
    PLOT student.*predicted.;
    PLOT npp.*student.;
RUN;
QUIT;


/* Part 6: Train/test split (75/25) */
TITLE "Train/Test Split";
PROC SURVEYSELECT DATA=ecommerce_clean OUT=xv_all
    SEED=495857 SAMPRATE=0.75 OUTALL;
RUN;

/* new_Y holds Units_Sold only for training rows */
DATA xv_all;
    SET xv_all;
    IF Selected THEN new_Y = Units_Sold;
RUN;


/* Part 7: Backward selection on the training set */
TITLE "Backward Selection";
PROC REG DATA=xv_all;
    MODEL new_Y = Price Discount Marketing_Spend
                  D_Premium D_Regular D_Sports D_Toys D_Fashion D_HomeDecor
                  / SELECTION=BACKWARD;
RUN;
QUIT;


/* Part 8: Final model, predict on the test set */
TITLE "Final Model (D_Premium)";
PROC REG DATA=xv_all;
    MODEL new_Y = D_Premium;
    OUTPUT OUT=out_final (WHERE=(new_Y=.)) P=Predicted_Units_Sold;
RUN;
QUIT;

DATA out_final_sum;
    SET out_final;
    d    = Units_Sold - Predicted_Units_Sold;
    absd = ABS(d);
RUN;

TITLE "Test Set: Actual vs Predicted";
PROC PRINT DATA=out_final_sum;
    VAR Units_Sold Predicted_Units_Sold d absd;
RUN;

PROC SUMMARY DATA=out_final_sum;
    VAR d absd;
    OUTPUT OUT=out_final_stats STD(d)=RMSE MEAN(absd)=MAE;
RUN;

TITLE "Test Set RMSE and MAE";
PROC PRINT DATA=out_final_stats;
RUN;

TITLE "Correlation Between Actual and Predicted (Test Set)";
PROC CORR DATA=out_final;
    VAR Units_Sold Predicted_Units_Sold;
RUN;
