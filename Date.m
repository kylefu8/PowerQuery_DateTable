let

    CalendarType =  type function (
    
        optional CalendarYearStart as (type number meta [
            Documentation.FieldCaption = "开始年份，日期表从开始年份1月1日起。",
            Documentation.FieldDescription = "日期表从开始年份1月1日起",
            Documentation.SampleValues = { Date.Year( DateTime.LocalNow( ) ) - 1 } // Previous Year
        ]),
        
        optional CalendarYearEnd as (type number meta [
            Documentation.FieldCaption = "结束年份，日期表至结束年份12月31日止。",
            Documentation.FieldDescription = "日期表至结束年份12月31日止",
            Documentation.SampleValues = { Date.Year( DateTime.LocalNow( ) ) } // Current Year
        ]),

        optional CalendarFirstDayOfWeek as (type text meta [
            Documentation.FieldCaption = "定义一周开始日，从 Monday，Tuesday，Wednesday，Thursday，Friday，Saturday，Sunday中选择一个，缺省默认为Monday。",
            Documentation.FieldDescription = "从 Monday，Tuesday，Wednesday，Thursday，Friday，Saturday，Sunday中选择一个，缺省默认为Monday。",
            Documentation.SampleValues = { "Monday" }
        ]),

        optional StarOfFiscalYear as (type number meta [
            Documentation.FieldCaption = "定义财年开始月份，从 1 到 12 中选择一个，缺省默认为 7。（财年针对微软定制。只有用7时，半（财年）和季度（财年）值才准确，否则需要手动修改。）",
            Documentation.FieldDescription = "从 1 到 12 中选择一个，缺省默认为 7。（财年针对微软定制。只有用7时，半（财年）和季度（财年）值才准确，否则需要手动修改。）",
            Documentation.SampleValues = { 7 }
        ]),

        optional CalendarCulture as (type text meta [
            Documentation.FieldCaption = "指定日期表显示月以及星期几的名称是中文或英文，en 表示英文，zh 表示中文，缺省默认与系统一致。",
            Documentation.FieldDescription = " en 表示英文，zh 表示中文，缺省默认与系统一致。",
            Documentation.SampleValues = { "zh" }
        ])

    ) 
    as table meta [
        Documentation.Name = "构建日期表",
        Documentation.LongDescription = "创建指定年份之间的日期表。并可进行各种设置。",
        Documentation.Examples = {
        [
            Description = "返回当前年份日期表",
            Code = "CreateCalendar()",
            Result = "当前年份日期表。"
        ],
        [
            Description = "返回指定年份的日期表",
            Code = "CreateCalendar( 2017 )",
            Result = "返回2017/01/01至2017/12/31之间的日期表。"
        ],
        [
            Description = "返回起止年份之间的日期表",
            Code = "CreateCalendar( 2015 , 2017 )",
            Result = "返回2015/01/01至2017/12/31之间的日期表。"
        ],
        [
            Description = "返回起止年份之间的日期表，并指定周二为每周的第一天",
            Code = "CreateCalendar( 2015 , 2017 , ""Tuesday"" )",
            Result = "2015/01/01至2017/12/31之间的日期表，且周二是每周的第一天。"
        ],
        [
            Description = "返回起止年份之间的日期表，并指定周二为每周的第一天，指定财年开始月份为7 (七月)。",
            Code = "CreateCalendar( 2015 , 2017 , ""Tuesday"", 7 )",
            Result = "2015/01/01至2017/12/31之间的日期表，且周二是每周的第一天，并使用英文显示月名称及星期几的名称。"
        ],
        [
            Description = "返回起止年份之间的日期表，并指定周二为每周的第一天，指定财年开始月份为7 (七月)，并使用英文显示名称。",
            Code = "CreateCalendar( 2015 , 2017 , ""Tuesday"", 7 , ""en"" )",
            Result = "2015/01/01至2017/12/31之间的日期表，且周二是每周的第一天，并使用英文显示月名称及星期几的名称。"
        ]
        }
    ],
    
    
    CreateCalendar = ( optional CalendarYearStart as number, optional CalendarYearEnd as number, optional CalendarFirstDayOfWeek as text, optional StarOfFiscalYear as number, optional  CalendarCulture as text) => let
        begin_year = CalendarYearStart ,
        end_year = CalendarYearEnd ,
        first_day_of_week = if Text.Lower( CalendarFirstDayOfWeek ) = "monday" then Day.Monday
                            else if Text.Lower( CalendarFirstDayOfWeek ) = "tuesday" then Day.Tuesday
                            else if Text.Lower( CalendarFirstDayOfWeek ) = "wednesday" then Day.Wednesday
                            else if Text.Lower( CalendarFirstDayOfWeek ) = "thursday" then Day.Thursday
                            else if Text.Lower( CalendarFirstDayOfWeek ) = "friday" then Day.Friday
                            else if Text.Lower( CalendarFirstDayOfWeek ) = "saturday" then Day.Saturday
                            else if Text.Lower( CalendarFirstDayOfWeek ) = "sunday" then Day.Sunday
                            else if CalendarFirstDayOfWeek <> null then error "参数错误：参数CalendarFirstDayOfWeek必须是Monday，Tuesday，Wednesday，Thursday，Friday，Saturday，Sunday中的一个。"
                            else Day.Monday ,
        start_of_fiscal_year = StarOfFiscalYear,
        culture = if CalendarCulture <> null then CalendarCulture else "zh" , // "en" , "zh"
        y1 = if begin_year <> null then begin_year else if end_year <> null then end_year else Date.Year( DateTime.LocalNow() ) ,
        y2 = if end_year <> null then end_year else if begin_year <> null then begin_year else Date.Year( DateTime.LocalNow() ) ,
        startfiscalmonth = if start_of_fiscal_year <> null then start_of_fiscal_year else 7 ,
        calendar_list = { Number.From ( #date( Number.From( y1 ) , 1 , 1 ) ) .. Number.From( #date( Number.From( y2 ) , 12, 31 ) ) },
        calendar_list_table = Table.FromList(calendar_list, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        #"Changed Type" = Table.TransformColumnTypes(calendar_list_table,{{"Column1", type date}}),
        #"Renamed Columns" = Table.RenameColumns(#"Changed Type",{{"Column1", "Date"}}),
        #"Inserted Year" = Table.AddColumn(#"Renamed Columns", "Year", each Date.Year([Date]), Int64.Type),
        #"Inserted Short Year" = Table.AddColumn(#"Inserted Year", "ShortYear", each Date.Year([Date]) - 2000, Int64.Type),
        #"Inserted Quarter" = Table.AddColumn(#"Inserted Short Year", "Quarter", each Date.QuarterOfYear([Date]), Int64.Type),
        #"Inserted Month" = Table.AddColumn(#"Inserted Quarter", "Month", each Date.Month([Date]), Int64.Type),
        #"Inserted Week of Year" = Table.AddColumn(#"Inserted Month", "WeekOfYear", each Date.WeekOfYear( [Date] , first_day_of_week ), Int64.Type),
        #"Inserted Week of Month" = Table.AddColumn(#"Inserted Week of Year", "WeekOfMonth", each Date.WeekOfMonth( [Date] ), Int64.Type),
        #"Inserted Start of Week" = Table.AddColumn(#"Inserted Week of Month", "DateOfWeekStart", each Date.StartOfWeek([Date]), type date),
        #"Inserted End of Week" = Table.AddColumn(#"Inserted Start of Week", "DateOfWeekEnd", each Date.EndOfWeek([Date]), type date),
        #"Inserted Week Peroid" = Table.AddColumn(#"Inserted End of Week", "PeroidOfWeek", each Text.From( [DateOfWeekStart] ) & "~" & Text.From( [DateOfWeekEnd] ), type text),
        #"Inserted Day" = Table.AddColumn(#"Inserted Week Peroid", "DayOfMonth", each Date.Day([Date]), Int64.Type),
        #"Inserted Day of Week" = Table.AddColumn(#"Inserted Day", "DayOfWeek", each Date.DayOfWeek( [Date] , first_day_of_week ), Int64.Type),
        #"Inserted Day of Year" = Table.AddColumn(#"Inserted Day of Week", "DayOfYear", each Date.DayOfYear([Date]), Int64.Type),
        #"Inserted Day Name" = Table.AddColumn(#"Inserted Day of Year", "DayOfWeekName", each Date.DayOfWeekName( [Date] , culture ), type text),
        #"Inserted Fiscal Year Name" = Table.AddColumn(#"Inserted Day Name", "FiscalYearName", each if [Month] >= startfiscalmonth then "FY" & Text.From( [ShortYear] + 1 ) else "FY" & Text.From( [ShortYear] ) , type text ),
        #"Inserted Fiscal Semester Name" = Table.AddColumn(#"Inserted Fiscal Year Name", "FiscalSemesterName", each if [Month] >= startfiscalmonth then "H1" else "H2", type text ),
        #"Inserted Fiscal Quarter Name" = Table.AddColumn(#"Inserted Fiscal Semester Name", "FiscalQuarterName", each if [Quarter] >=3 then "Q" & Text.From( [Quarter] - 2 ) else "Q" & Text.From( [Quarter] + 2 ) , type text ),
        #"Inserted Fiscal Year Semester Name" = Table.AddColumn(#"Inserted Fiscal Quarter Name", "FiscalYearSemesterName", each [FiscalYearName] & [FiscalSemesterName], type text ),
        #"Inserted Fiscal Year Quarter Name" = Table.AddColumn(#"Inserted Fiscal Year Semester Name", "FiscalYearQuarterName", each [FiscalYearName] & [FiscalQuarterName], type text ),
        #"Inserted Fiscal Year Semester Quarter Name" = Table.AddColumn(#"Inserted Fiscal Year Quarter Name", "FiscalYearSemesterQuarterName", each [FiscalYearName] & [FiscalSemesterName] & [FiscalQuarterName], type text ),
        #"Inserted Year Name" = Table.AddColumn(#"Inserted Fiscal Year Semester Quarter Name", "YearName", each "Y" & Text.From( [Year] )  , type text  ),
        #"Inserted Quarter Name" = Table.AddColumn(#"Inserted Fiscal Year Semester Quarter Name", "QuarterName", each "Q" & Text.From( [Quarter] ) , type text ),
        #"Inserted Month Name" = Table.AddColumn(#"Inserted Quarter Name", "MonthName", each Date.MonthName( [Date] , culture ), type text),
        #"Inserted Week Name" = Table.AddColumn(#"Inserted Month Name", "WeekName", each "W" & Text.From( [WeekOfYear] ) , type text ),
        #"Inserted Year Quarter" = Table.AddColumn(#"Inserted Week Name", "YearQuarter", each [Year] * 100 + [Quarter] , Int64.Type ),
        #"Inserted Year Month" = Table.AddColumn(#"Inserted Year Quarter", "YearMonth", each [Year] * 100 + [Month] , Int64.Type ),
        #"Inserted Year Week" = Table.AddColumn(#"Inserted Year Month", "YearWeek", each [Year] * 100 + [WeekOfYear] , Int64.Type ),
        #"Inserted Date Code" = Table.AddColumn(#"Inserted Year Week", "DateCode", each [Year] * 10000 + [Month] * 100 + [DayOfMonth] , Int64.Type )
    in
        if culture = "zh"
        then Table.RenameColumns( #"Inserted Date Code" ,{{"Date", "日期"}, {"Year", "年"}, {"ShortYear", "年(缩写)"}, {"Quarter", "季"}, {"Month", "月"}, {"WeekOfYear", "周"}, {"WeekOfMonth", "月周"}, {"DayOfMonth", "月日"}, {"DateOfWeekStart", "周开始日期"}, {"DateOfWeekEnd", "周结束日期"}, {"PeroidOfWeek", "周起止日期"}, {"DayOfWeek", "周天"}, {"DayOfYear", "年日"}, {"DayOfWeekName", "星期几名称"}, {"FiscalYearName", "财年名称"}, {"FiscalSemesterName", "半（财年）名称"}, {"FiscalQuarterName", "季度（财年）名称"}, {"FiscalYearSemesterName", "年半（财年）名称"}, {"FiscalYearQuarterName", "年季度（财年）名称"}, {"FiscalYearSemesterQuarterName", "年半季度（财年）名称"}, {"YearName", "年份名称"}, {"QuarterName", "季度名称"}, {"MonthName", "月份名称"}, {"WeekName", "周名称"}, {"YearQuarter", "年季"}, {"YearMonth", "年月"}, {"YearWeek", "年周"}, {"DateCode", "日期码"}})
        else #"Inserted Date Code"

in
    Value.ReplaceType( CreateCalendar , CalendarType )