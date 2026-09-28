# E-Commerce Sales Regression Analysis (SAS)

What actually drives how many units an online store sells? This project uses multiple linear regression in SAS to test whether price, discount, marketing spend, customer segment, or product category can predict **Units Sold** across 1,000 products.

## Key Findings

- **Most factors had almost no effect on sales.** Price, discount, and marketing spend all had correlations with Units Sold close to zero (|r| < 0.04).
- **Premium customers were the one real signal.** Backward selection removed every predictor except the Premium customer segment, which was statistically significant (p = 0.028).
- **The model explains very little variation.** The final model's R² was 0.0067, so customer segment alone explains under 1% of the differences in sales.
- **Takeaway:** Units Sold in this dataset is mostly driven by factors that aren't in the data. That's a real and useful result, since it tells a business that discounting or spending more on marketing wouldn't reliably move sales here.

## Methods

1. **Data prep:** imported the CSV and created dummy variables for customer segment (baseline: Occasional) and product category (baseline: Electronics)
2. **Exploratory analysis:** summary stats, histogram and normality test for Units Sold, boxplots by category and segment, correlation matrix, and scatterplots
3. **Full regression model** with all 9 predictors
4. **Diagnostics:** multicollinearity (all VIFs under 1.8), outliers and influential points (studentized residuals, Cook's D), and assumption checks (residual plots, normal Q-Q plot)
5. **Cleaning:** removed 45 outliers and influential points (1,000 → 955 rows), which lowered Root MSE from 7.27 to 6.98
6. **Model selection:** 75/25 train/test split, then backward selection on the training set
7. **Validation:** predicted Units Sold on the held-out test set and measured RMSE, MAE, and the correlation between actual and predicted values

## Files

| File | Description |
|---|---|
| `analysis.sas` | Full SAS code, from import to validation |
| `presentation.pdf` | Slides with the output tables, charts, and my interpretation |

## Run It

Put `Ecommerce_Sales.csv` in the same folder as `analysis.sas` and run the script top to bottom in SAS or SAS OnDemand for Academics. Run it in order, since the outlier-removal step depends on the row order from the earlier sorts.

## Tools

SAS (PROC REG, PROC CORR, PROC UNIVARIATE, PROC SURVEYSELECT, PROC SGSCATTER)
