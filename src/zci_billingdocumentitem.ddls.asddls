@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Billing Document View'
//@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZCI_BillingDocumentItem
  as select from I_BillingDocumentItem
  association [0..1] to I_Customer as _Customer on $projection.SoldToParty = _Customer.Customer
  association [0..1] to ZC_INVNEW  as _Invnew   on $projection.SoldToParty = _Invnew.Kunnr
  association [0..1] to I_SalesOrderItem as _Soitem on  $projection.SalesDocument = _Soitem.SalesOrder
                                                    and $projection.SalesDocumentItem = _Soitem.SalesOrderItem
  association [0..1] to I_SalesOrder as _Soheader on $projection.SalesDocument = _Soheader.SalesOrder                                                
{
  key BillingDocument,
  key BillingDocumentItem,
      SalesDocument,
      SalesDocumentItem,
      CreatedByUser,
      CreationDate,
      @EndUserText.label: 'Customer'
      @Consumption.valueHelpDefinition: [{
       entity.name: 'I_Customer',
       entity.element: 'Customer'
       }]
      SoldToParty,
      @EndUserText.label: 'Customer Name'
      _Customer.CustomerName,
      @EndUserText.label: 'Billing Cycle'
      _Invnew.Billcycle,
      @EndUserText.label: 'Billing Status'
      _Invnew.Billfre,
      @EndUserText.label: 'Dose ID'
      _Soitem.MaterialByCustomer,
      @EndUserText.label: 'Study ID'
      _Soheader.YY1_StudyID_SDH as PurchaseOrderByShipToParty,
      

      _Customer,
      _Invnew


}
