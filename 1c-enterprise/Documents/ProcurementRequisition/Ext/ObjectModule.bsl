#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	For Each SupplierRow In Suppliers Do
		SupplierRow.RFQKey = Undefined;
	EndDo;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)

	For Each Supplier In Suppliers Do
		
		If Not ValueIsFilled(Supplier.RFQKey) Then
			Supplier.RFQKey = String(New UUID);
		EndIf;
		
	EndDo;	

EndProcedure

Procedure Posting(Cancel, Mode)

	RegisterRecords.RFQKeys.Write = True;
	
	For Each Supplier In Suppliers Do
		
		Record = RegisterRecords.RFQKeys.Add();
		
		Record.RFQKey 	= Supplier.RFQKey;		
		Record.Document	= Ref;
		Record.Company	= Supplier.Company;
		Record.Contract	= Supplier.Contract;
	
	EndDo;

EndProcedure

#EndRegion