#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		
	RFQInterfaceURL = Constants.RFQInterfaceURL.Get();
	
	FillAdditionalColumnsOfSuppliers();
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FillAdditionalColumnsOfSuppliers();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSuppliers

&AtClient
Procedure SuppliersSelection(Item, SelectedRow, Field, StandardProcessing)
	
	If Field = Items.SuppliersRFQURL Then
		
		StandardProcessing = False;
		
		RFQURL = Items.Suppliers.CurrentData.RFQURL;
		
		If ValueIsFilled(RFQURL) Then	
			GotoURL(RFQURL);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillAdditionalColumnsOfSuppliers()
	
	For Each Line In Object.Suppliers Do
		
		IsAbleToFill = 
			ValueIsFilled(RFQInterfaceURL)
			And ValueIsFilled(Line.RFQKey);
		
		If IsAbleToFill Then
			Line.RFQURL = StrTemplate("%1/%2", RFQInterfaceURL, Line.RFQKey);
		Else
			Line.RFQURL = "";
		EndIf;
		
	EndDo;

EndProcedure

#EndRegion