-- Portfolio project by Ngoc Do with dataset available on: https://www.kaggle.com/ukveteran/adventure-works

-- TASK: CALCULATE PROFIT FOR EACH PRODUCT, FIND THE PRODUCT WITH HIGHEST/LOWEST PROFIT



-- CALCULATE QUANTITIES OF PRODUCTS SOLD AND RETURNED

Select Sales.ProductKey, Sum(Sales.OrderQuantity) as TotalSold
From (
	Select *
	From Portfolio_project.dbo.Sales_2015
	Union
	Select *
	From Portfolio_project.dbo.Sales_2016
	Union
	Select *
	From Portfolio_project.dbo.Sales_2017
	) as Sales
Group by Sales.ProductKey
Order by 1


Select ProductKey, Sum(ReturnQuantity) as TotalReturned
From Portfolio_project.dbo.Returns
Group by ProductKey

-- JOIN 2 TABLES ABOVE TOGETHER THEN CALCULATE THE ACTUAL QUANTITIES OF PRODUCTS SOLD

Select Sold.*,
	(Case When Re.TotalReturned > 0 Then Re.TotalReturned
		Else 0
		End) as Returned, -- Replace NULL values by 0
	(Case When Re.TotalReturned > 0 Then (Sold.TotalSold - Re.TotalReturned)
		Else Sold.TotalSold
		End) as ActualSold
From
	(Select Sales.ProductKey, Sum(Sales.OrderQuantity) as TotalSold
	From 
		(
		Select *
		From Portfolio_project.dbo.Sales_2015
		Union
		Select *
		From Portfolio_project.dbo.Sales_2016
		Union
		Select *
		From Portfolio_project.dbo.Sales_2017
		) as Sales
		Group by Sales.ProductKey
	) as Sold

Left Join 
(Select ProductKey, Sum(ReturnQuantity) as TotalReturned
From Portfolio_project.dbo.Returns
Group by ProductKey
) as Re
	On Sold.ProductKey = Re.ProductKey

Order by 1

-- CREATE TEMP TABLE FOR FURTHER CALCULATIONS

DROP TABLE IF EXISTS #Temp_ActualQuantSold
CREATE TABLE #Temp_ActualQuantSold
	(
	ProductKey int,
	TotalSold int,
	Returned int,
	ActualSold int
	)

INSERT INTO #Temp_ActualQuantSold
Select Sold.*,
	(Case When Re.TotalReturned > 0 Then Re.TotalReturned
		Else 0
		End) as Returned, -- Replace NULL values by 0
	(Case When Re.TotalReturned > 0 Then (Sold.TotalSold - Re.TotalReturned)
		Else Sold.TotalSold
		End) as ActualSold
From
	(Select Sales.ProductKey, Sum(Sales.OrderQuantity) as TotalSold
	From 
		(
		Select *
		From Portfolio_project.dbo.Sales_2015
		Union
		Select *
		From Portfolio_project.dbo.Sales_2016
		Union
		Select *
		From Portfolio_project.dbo.Sales_2017
		) as Sales
		Group by Sales.ProductKey
	) as Sold

Left Join 
(Select ProductKey, Sum(ReturnQuantity) as TotalReturned
From Portfolio_project.dbo.Returns
Group by ProductKey
) as Re
	On Sold.ProductKey = Re.ProductKey

Order by 1

-- CALCULATE PROFIT ON EACH PRODUCT KEY, FIND THE PRODUCT WITH HIGHEST/LOWEST PROFIT

-- Highest
Select Top 1 prd.ProductName, temp.*, prd.ProductCost, prd.ProductPrice, ((prd.ProductPrice - prd.ProductCost)*temp.ActualSold) as Profit
From #Temp_ActualQuantSold temp
Left Join Portfolio_project.dbo.Products prd
	On temp.ProductKey = prd.ProductKey
Order by 8 desc

-- Lowest
Select Top 1 prd.ProductName, temp.*, prd.ProductCost, prd.ProductPrice, ((prd.ProductPrice - prd.ProductCost)*temp.ActualSold) as Profit
From #Temp_ActualQuantSold temp
Left Join Portfolio_project.dbo.Products prd
	On temp.ProductKey = prd.ProductKey
Order by 8