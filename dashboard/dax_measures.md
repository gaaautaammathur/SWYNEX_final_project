# DAX measures: SWYNEX_Dashboard_v2.pbix

Tables in the model: **`orders`** (the data), **`Date`** (the calendar) and **`_measures`** (an empty table that holds the measures).

> The measure names below are the exact names used by the visuals in the dashboard. I could not read the formulas stored inside the `.pbix` file, so the formulas here are written to give the results in the check table at the bottom. If a card shows a different number, open **Model view**, click the measure, and compare its formula with the one here.

## 1. Date table

Modeling → New table:

```DAX
Date =
ADDCOLUMNS(
    CALENDAR(MIN(orders[order_date]), MAX(orders[order_date])),
    "Year", YEAR([Date]),
    "Month No", MONTH([Date]),
    "Month", FORMAT([Date], "MMM"),
    "Year-Month", FORMAT([Date], "yyyy-MM"),
    "Weekday No", WEEKDAY([Date], 2),
    "Weekday", FORMAT([Date], "ddd")
)
```

Then mark it as a date table, connect `Date[Date]` to `orders[order_date]`, and sort `Month` by `Month No` and `Weekday` by `Weekday No`.

## 2. Measures used on the dashboard

| Measure | Page | What it shows |
|---|---|---|
| `Revenue` | Executive Overview | Money kept: all orders except cancelled and returned |
| `Total order` | both pages | Number of orders |
| `Total sale` | Executive Overview | Value of all orders placed |
| `Avg order value` | both pages | Average value of an order that counts as a sale |
| `Lost(%)` | Executive Overview | Share of order value lost to cancelled and returned orders |
| `cancel rate` | Operations & Risk | Share of orders cancelled |
| `return rate` | Operations & Risk | Share of orders returned |
| `Outlier Orders` | Operations & Risk | Number of unusually large orders (IQR rule) |

```DAX
Total order = COUNTROWS(orders)

Total sale = SUM(orders[total_amount])

Revenue =
CALCULATE(
    [Total sale],
    orders[order_status] <> "Cancelled",
    orders[order_status] <> "Returned"
)

Avg order value =
DIVIDE(
    [Revenue],
    CALCULATE(
        COUNTROWS(orders),
        orders[order_status] <> "Cancelled",
        orders[order_status] <> "Returned"
    )
)

Lost(%) = DIVIDE([Total sale] - [Revenue], [Total sale])

cancel rate =
DIVIDE(CALCULATE(COUNTROWS(orders), orders[order_status] = "Cancelled"), [Total order])

return rate =
DIVIDE(CALCULATE(COUNTROWS(orders), orders[order_status] = "Returned"), [Total order])

Upper Limit =
VAR Q1 = CALCULATE(PERCENTILE.INC(orders[total_amount], 0.25), ALL(orders))
VAR Q3 = CALCULATE(PERCENTILE.INC(orders[total_amount], 0.75), ALL(orders))
RETURN Q3 + 1.5 * (Q3 - Q1)

Outlier Orders =
VAR Lim = [Upper Limit]
RETURN CALCULATE(COUNTROWS(orders), orders[total_amount] > Lim)
```

`Upper Limit` is a helper measure. It is not shown on a visual, but `Outlier Orders` needs it.

## 3. Recommended changes in the model

**Number formats** (select the measure, then Measure tools → Format):

| Measure | Format |
|---|---|
| `Revenue`, `Total sale`, `Avg order value` | Currency (₹), 0 decimals |
| `Total order`, `Outlier Orders` | Whole number |
| `Lost(%)`, `cancel rate`, `return rate` | Percentage, 1 decimal |

**Monthly trend:** the "Revenue by month" line chart uses only the Month level of the date hierarchy, which adds Jan 2025 and Jan 2026 together. Put `Date[Year-Month]` on the axis instead.

**Names:** if you rename measures (for example `Avg order value` to `Avg Order Value`), Power BI updates the visuals automatically. Keep one spelling everywhere.

## 4. Optional measures (not on the dashboard yet)

A calculated column on `orders`, needed for the delivery time:

```DAX
Delivery Days =
IF(
    NOT ISBLANK(orders[delivery_date]),
    DATEDIFF(orders[order_date], orders[delivery_date], DAY)
)
```

```DAX
Avg Delivery Days = AVERAGE(orders[Delivery Days])

Revenue Share % = DIVIDE([Revenue], CALCULATE([Revenue], ALL(orders)))

Revenue Prev Month = CALCULATE([Revenue], DATEADD('Date'[Date], -1, MONTH))

Revenue MoM % = DIVIDE([Revenue] - [Revenue Prev Month], [Revenue Prev Month])
```

## 5. Values to check against (no slicers selected)

| Measure | Expected |
|---|---|
| `Total order` | 252 |
| `Total sale` | ₹34.1 lakh (about 3,408,000) |
| `Revenue` | ₹18.8 lakh (about 1,877,000) |
| `Lost(%)` | 44.9% |
| `Avg order value` | ₹12,768 |
| `cancel rate` | 23.0% |
| `return rate` | 18.7% |
| `Outlier Orders` | 35 |
| `Avg Delivery Days` (optional) | 5.5 |
