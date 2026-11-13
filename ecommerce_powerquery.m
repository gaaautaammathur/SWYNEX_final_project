// Power Query (M) script: loads ecommerce_orders_powerbi_ready.csv with the right data types.
// How to use: Power BI Desktop -> Home -> Get data -> Blank Query -> Advanced Editor -> delete everything -> paste this -> Done.
// Change the file path on the line that starts with "Source" to where YOU saved the CSV.
let
    Source = Csv.Document(
        File.Contents("C:\Users\YourName\Downloads\ecommerce_orders_powerbi_ready.csv"),
        [Delimiter = ",", Columns = 18, Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    Headers = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),

    // Text and number columns
    Typed = Table.TransformColumnTypes(
        Headers,
        {
            {"order_id", type text}, {"customer_id", type text}, {"customer_name", type text},
            {"email", type text}, {"phone", type text}, {"product_name", type text},
            {"category", type text}, {"quantity", Int64.Type}, {"unit_price", type number},
            {"discount_pct", Int64.Type}, {"total_amount", type number},
            {"payment_method", type text}, {"order_status", type text},
            {"city", type text}, {"state", type text}, {"country", type text}
        },
        "en-US"
    ),

    // Date columns: a real date stays a date, anything else (blank, text) becomes null instead of an error
    Dates = Table.TransformColumns(
        Typed,
        {
            {"order_date",    each try Date.From(_) otherwise null, type nullable date},
            {"delivery_date", each try Date.From(_) otherwise null, type nullable date}
        }
    ),

    // Product names: "levi's jeans" -> "Levi's Jeans", "iphone 13" -> "iPhone 13"
    Proper = Table.TransformColumns(Dates, {{"product_name", Text.Proper, type text}}),
    FixLevis = Table.ReplaceValue(Proper, "Levi'S", "Levi's", Replacer.ReplaceText, {"product_name"}),
    FixIphone = Table.ReplaceValue(FixLevis, "Iphone", "iPhone", Replacer.ReplaceText, {"product_name"})
in
    FixIphone
