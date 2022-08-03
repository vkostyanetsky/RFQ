#Region EventHandlers

Function PingGET(Request)
	
	Try
		
		ResponseData = PingGETResponseData(Request);
			
	Except
		
		ErrorInfo = ErrorInfo();
		ErrorText = ErrorText(ErrorInfo);
		
		WriteLogEventForException("PingGET", ErrorText);
		
		ResponseData = ResponseDataForException(ErrorText);

	EndTry;
	
	Return Response(ResponseData);
	
EndFunction

Function DataGET(Request)
	
	Try
		
		ResponseData = DataGETResponseData(Request);
					
	Except

		ErrorInfo = ErrorInfo();
		ErrorText = ErrorText(ErrorInfo);
		
		WriteLogEventForException("DataGET", ErrorText);
		
		ResponseData = ResponseDataForException(ErrorText);
			
	EndTry;

	Return Response(ResponseData);
	
EndFunction

Function DataPOST(Request)
		
	Try
		
		ResponseData = DataPOSTResponseData(Request);
			
	Except
		
		ErrorInfo = ErrorInfo();
		ErrorText = ErrorText(ErrorInfo);
		
		WriteLogEventForException("DataPOST", ErrorText);
		
		ResponseData = ResponseDataForException(ErrorText);

	EndTry;

	Return Response(ResponseData);
	
EndFunction                                                                       

#EndRegion

#Region Private

#Region Ping

Function PingGETResponseData(Request)
	
	ResponseData = New Map;
	ResponseData.Insert("Result", True);
	
	Return ResponseData;
	
EndFunction

#EndRegion

#Region DataGET

Function DataGETResponseData(Request)
	
	RFQKey = Request.URLParameters["RFQKey"];
	
	Return RFQByKey(RFQKey);
	
EndFunction

Function RFQByKey(Key)
	
	Query = New Query(
	"SELECT
	|   RFQKeys.Document                            AS Document,
	|   RFQKeys.Document.Number                     AS Number,
	|   RFQKeys.Document.Date                       AS Date,
	|   RFQKeys.Company                             AS Company,
	|
	|   ISNULL(ResponseToRFQ.Ref, VALUE(Document.ResponseToRFQ.EmptyRef))
	|                                               AS Response,
	|
	|   CASE
	|       WHEN ResponseToRFQ.Posted IS NULL
	|           THEN FALSE
	|       ELSE ResponseToRFQ.Posted
	|   END
	|                                               AS Posted
	|
	|INTO Attributes
	|
	|FROM
	|   InformationRegister.RFQKeys AS RFQKeys
	|
	|       LEFT JOIN Document.ResponseToRFQ AS ResponseToRFQ
	|       ON
	|           ResponseToRFQ.DocumentBasis = RFQKeys.Document
	|           AND ResponseToRFQ.Company   = RFQKeys.Company
	|           AND ResponseToRFQ.Contract  = RFQKeys.Contract
	|           AND NOT ResponseToRFQ.DeletionMark
	|
	|WHERE
	|   RFQKeys.RFQKey = &Key
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|   Attributes.Number                           AS Number,
	|   Attributes.Date                             AS Date,
	|   Attributes.Posted                           AS Posted
	|
	|FROM
	|   Attributes AS Attributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|   Inventory.LineNumber                        AS LineNumber,
	|   REFPRESENTATION(Inventory.Item)             AS Item,
	|   REFPRESENTATION(Inventory.UnitOfMeasure)    AS UnitOfMeasure,
	|   Inventory.Quantity                          AS Quantity,
	|   """"                                        AS Price
	|
	|FROM
	|   Attributes AS Attributes
	|
	|       INNER JOIN Document.ProcurementRequisition.Inventory AS Inventory
	|       ON
	|           Attributes.Document     = Inventory.Ref
	|           AND Attributes.Response = VALUE(Document.ResponseToRFQ.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|   Inventory.LineNumber                        AS LineNumber,
	|   REFPRESENTATION(Inventory.Item)             AS Item,
	|   REFPRESENTATION(Inventory.UnitOfMeasure)    AS UnitOfMeasure,
	|   Inventory.Quantity                          AS Quantity,
	|
	|   CASE
	|       WHEN Inventory.Price > 0
	|           THEN Inventory.Price
	|       ELSE """"
	|   END 
	|                                               AS Price
	|
	|FROM
	|   Attributes AS Attributes
	|
	|       INNER JOIN Document.ResponseToRFQ.Inventory AS Inventory
	|       ON
	|           Attributes.Response = Inventory.Ref
	|
	|ORDER BY
	|   LineNumber  
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|   Questions.LineNumber                        AS LineNumber,
	|   REFPRESENTATION(Questions.Question)         AS Question,
	|   """"                                        AS Answer
	|
	|FROM
	|   Attributes AS Attributes
	|
	|       INNER JOIN Document.ProcurementRequisition.Questions AS Questions
	|       ON
	|           Attributes.Document     = Questions.Ref
	|           AND Attributes.Response = VALUE(Document.ResponseToRFQ.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|   Questions.LineNumber                        AS LineNumber,
	|   REFPRESENTATION(Questions.Question)         AS Question,
	|   Questions.Answer                            AS Answer
	|
	|FROM
	|   Attributes AS Attributes
	|
	|       INNER JOIN Document.ResponseToRFQ.Questions AS Questions
	|       ON
	|           Attributes.Response = Questions.Ref
	|
	|ORDER BY
	|   LineNumber");
	
	Query.SetParameter("Key", Key);

	QueryResults = Query.ExecuteBatch();
	
	Selection = QueryResults[0].Select();
	Selection.Next();
	
	If Selection.Count = 1 Then

		Result = New Map;
		
		Result.Insert("Number",			"");
		Result.Insert("Date",			"");
		
		Result.Insert("Inventory",		New Array);
		Result.Insert("Questions",		New Array);
		
		Result.Insert("Posted",			False);
		
		FillRFQFromQueryResult(Result, QueryResults[1]);
		
		FillRFQTabularSectionFromQueryResult(Result["Inventory"], QueryResults[2]);
		FillRFQTabularSectionFromQueryResult(Result["Questions"], QueryResults[3]);
						
	ElsIf Selection.Count = 0 Then
		
		ErrorCode = 101;
		ErrorText = "Request for Quotation with key specified is not found.";
		
		Result = ResponseDataWithErrorCodeAndErrorText(ErrorCode, ErrorText);		
		
	Else
		
		ErrorCode = 103;
		ErrorText = "There are more than one Request for Quotation with key specified.";
		
		Result = ResponseDataWithErrorCodeAndErrorText(ErrorCode, ErrorText);		
		
	EndIf;
		
	Return Result;
	
EndFunction

Procedure FillRFQFromQueryResult(RFQ, QueryResult)

	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
			
	Selection = QueryResult.Select();
	Selection.Next();
	
	For Each Column In QueryResult.Columns Do
		RFQ[Column.Name] = Selection[Column.Name];
	EndDo;				
	
	RFQ["Date"] = Format(Selection.Date, "L=en; DLF=DD");
		
EndProcedure

Procedure FillRFQTabularSectionFromQueryResult(TabularSection, QueryResult)
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do

		Row = New Map;
		
		For Each Column In QueryResult.Columns Do
			
			ColumnValue = Selection[Column.Name];							
			Row.Insert(Column.Name, ColumnValue);
			
		EndDo;			
		
		TabularSection.Add(Row);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region DataPOST

Function DataPOSTResponseData(Request)
	
	RFQKey = Request.URLParameters["RFQKey"];

	Query = New Query(
	"SELECT
	|   RFQKeys.Document                    AS DocumentBasis,
	|   RFQKeys.Company                     AS Company,
	|   RFQKeys.Contract                    AS Contract,
	|
	|   ISNULL(RFQResponse.Posted, FALSE)       
	|                                       AS Posted,
	|
	|   ISNULL(RFQResponse.Ref, VALUE(Document.ResponseToRFQ.EmptyRef))
	|                                       AS Ref
	|
	|INTO Attributes
	|
	|FROM
	|   InformationRegister.RFQKeys AS RFQKeys
	|
	|       LEFT JOIN Document.ResponseToRFQ AS RFQResponse
	|       ON
	|           RFQResponse.DocumentBasis   = RFQKeys.Document
	|           AND RFQResponse.Company     = RFQKeys.Company
	|           AND RFQResponse.Contract    = RFQKeys.Contract
	|           AND NOT RFQResponse.DeletionMark
	|
	|WHERE
	|   RFQKeys.RFQKey = &Key
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|   Attributes.DocumentBasis            AS DocumentBasis,
	|   Attributes.Company                  AS Company,
	|   Attributes.Contract                 AS Contract,    
	|   Attributes.Posted                   AS Posted,
	|   Attributes.Ref                      AS Ref  
	|
	|FROM
	|   Attributes AS Attributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|   Inventory.Item                      AS Item,
	|   Inventory.UnitOfMeasure             AS UnitOfMeasure,
	|   Inventory.Quantity                  AS Quantity
	|
	|FROM
	|   Document.ProcurementRequisition.Inventory AS Inventory
	|
	|       INNER JOIN Attributes AS Attributes
	|       ON Attributes.DocumentBasis = Inventory.Ref
	|
	|ORDER BY
	|   Inventory.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|   Questions.Question                  AS Question
	|
	|FROM
	|   Document.ProcurementRequisition.Questions AS Questions
	|       
	|       INNER JOIN Attributes AS Attributes
	|       ON Attributes.DocumentBasis = Questions.Ref
	|
	|ORDER BY
	|   Questions.LineNumber");
	
	Query.SetParameter("Key", RFQKey);
		
	QueryResults = Query.ExecuteBatch();
	
	Selection = QueryResults[0].Select();
	Selection.Next();
	
	If Selection.Count = 1 Then
		
		AttributesQueryResult	= QueryResults[1];
		InventoryQueryResult	= QueryResults[2];
		QuestionsQueryResult	= QueryResults[3];		
		
		DocumentObject = ResponseToRFQDocumentObject(AttributesQueryResult, InventoryQueryResult, QuestionsQueryResult);
		
		If Not DocumentObject.Posted Then			
			
			RequestBody = RequestBody(Request);			
									
			UpdateRFQInventory(DocumentObject.Inventory, RequestBody.Get("Inventory"));
			UpdateRFQQuestions(DocumentObject.Questions, RequestBody.Get("Questions"));			
			
			WriteMode = ? (RequestBody.Get("SaveAsDraft"), DocumentWriteMode.Write, DocumentWriteMode.Posting);
			
			DocumentObject.Write(WriteMode);
			
			ResponseData = RFQByKey(RFQKey);
				
		Else
			
			ErrorCode = 102;
			ErrorText = "Request for Quotation with key specified is already posted.";
			
			ResponseData = ResponseDataWithErrorCodeAndErrorText(ErrorCode, ErrorText);			
			
		EndIf;		
		
	ElsIf Selection.Count = 0 Then

		ErrorCode = 101;
		ErrorText = "Request for Quotation with key specified is not found.";
		
		ResponseData = ResponseDataWithErrorCodeAndErrorText(ErrorCode, ErrorText);				
		
	Else

		ErrorCode = 103;
		ErrorText = "There are more than one Request for Quotation with key specified.";
		
		ResponseData = ResponseDataWithErrorCodeAndErrorText(ErrorCode, ErrorText);								
		
	EndIf;
				
	Return ResponseData;
	
EndFunction

Function ResponseToRFQDocumentObject(AttributesQueryResult, InventoryQueryResult, QuestionsQueryResult)
		
	Selection = AttributesQueryResult.Select();
	Selection.Next();
	
	If ValueIsFilled(Selection.Ref) Then
		
		DocumentObject = Selection.Ref.GetObject();
		DocumentObject.Lock();
		
	Else

		DocumentObject = Documents.ResponseToRFQ.CreateDocument();
		
		DocumentObject.Date = CurrentSessionDate();
		
		FillPropertyValues(DocumentObject, Selection, "Company, Contract, DocumentBasis");
		
		If Not InventoryQueryResult.IsEmpty() Then
		
			InventorySelection = InventoryQueryResult.Select();
			
			While InventorySelection.Next() Do
				NewRow = DocumentObject.Inventory.Add();
				FillPropertyValues(NewRow, InventorySelection);
			EndDo;
			
		EndIf;
				
		If Not QuestionsQueryResult.IsEmpty() Then
		
			QuestionsSelection = QuestionsQueryResult.Select();
			
			While QuestionsSelection.Next() Do
				NewRow = DocumentObject.Questions.Add();
				FillPropertyValues(NewRow, QuestionsSelection);
			EndDo;
			
		EndIf;
		
	EndIf;
		
	Return DocumentObject;
	
EndFunction

Procedure UpdateRFQInventory(Inventory, SourceData)
	
	For Each SourceDataItem In SourceData Do
		
		LineNumber = Int(SourceDataItem.Key);
		
		FieldValue = TrimAll(SourceDataItem.Value);
		FieldValue = StrSplit(FieldValue, ".");

		If FieldValue.Count() = 1 Then			
			FieldValue = FieldValue[0];
		Else
			FieldValue = StrTemplate("%1.%2", FieldValue[0], FieldValue[1]);
		EndIf;
				
		Inventory[LineNumber - 1].Price = ? (ValueIsFilled(FieldValue), Number(FieldValue), 0);;
		
	EndDo;
	
EndProcedure

Procedure UpdateRFQQuestions(Questions, SourceData)
	
	For Each SourceDataItem In SourceData Do
		
		LineNumber = Int(SourceDataItem.Key);
		FieldValue = TrimAll(SourceDataItem.Value);
		
		Questions[LineNumber - 1].Answer = FieldValue;
		
	EndDo;
	
EndProcedure

#EndRegion

Procedure WriteLogEventForException(MethodName, ErrorText)
	
	EventName = EventName(MethodName);
	ErrorInfo = ErrorInfo();
	
	WriteLogEvent(
		EventName,
		EventLogLevel.Error,
		Metadata.HTTPServices.RFQ,
		,
		ErrorText
	);
	
EndProcedure

Function ResponseDataWithErrorCodeAndErrorText(ErrorCode, ErrorText)
	
	ResponseData = New Map;	
	
	ResponseData.Insert("ErrorCode", ErrorCode);
	ResponseData.Insert("ErrorText", ErrorText);
	
	Return ResponseData;
	
EndFunction

Function ResponseDataForException(ErrorText)
						
	Return ResponseDataWithErrorCodeAndErrorText(100, ErrorText);	
	
EndFunction

Function Response(ResponseData = Undefined)

	If ResponseData = Undefined Then
		ResponseData = New Map;
	EndIf;
	
	BodyString = ResponseDataToJSON(ResponseData);	
	
	Response = New HTTPServiceResponse(200);
	Response.SetBodyFromString(BodyString);	
	
	Response.Headers.Insert("Content-Type", "application/json");	
	
	Return Response;	
		
EndFunction

Function ResponseDataToJSON(ResponseData)
	
	JSONWriterSettings = New JSONWriterSettings(JSONLineBreak.None);
	
	JSONWriter = New JSONWriter();	
	JSONWriter.SetString(JSONWriterSettings);
	
	WriteJSON(JSONWriter, ResponseData);
	
	Return JSONWriter.Close();
	
EndFunction

Function RequestBodyFromJSON(RequestBody)
	
	JSONReader = New JSONReader;
	JSONReader.SetString(RequestBody);
	
	Return ReadJSON(JSONReader, True);
	
EndFunction

Function RequestBody(Request)
	
	RequestBody = Request.GetBodyAsString();
	
	Return RequestBodyFromJSON(RequestBody);	
	
EndFunction

Function EventName(MethodName)
	
	Return StrTemplate("RFQ.%1", MethodName);
	
EndFunction

Function ErrorText(ErrorInfo)

	ErrorProcessingManager = New ErrorProcessingManager;
		
	Return ErrorProcessingManager.DetailErrorDescription(ErrorInfo);	
	
EndFunction

#EndRegion