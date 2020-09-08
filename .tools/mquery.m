let
    Params = Excel.CurrentWorkbook(){[Name="ParametersTable"]}[Content],
    ParamsText = Table.TransformColumnTypes(Params,{{"Cono", type text}, {"AcceptDate", type text}}),
    ConoValue = ParamsText{0}[Cono],
    AcceptDateValue = ParamsText{0}[AcceptDate],
    Source = Sql.Database("also-ecom.database.windows.net", "RMA", [Query="exec reports.ReturnsSelect '"&ConoValue&"', '"&AcceptDateValue&"'", MultiSubnetFailover=true])
in
    Source
