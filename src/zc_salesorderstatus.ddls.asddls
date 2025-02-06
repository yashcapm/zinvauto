@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Status'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZC_SALESORDERSTATUS as select from I_SalesOrderItem
association [1..1] to I_SalesOrder as _SalesOrder on $projection.SalesOrder = _SalesOrder.SalesOrder
                                                 and _SalesOrder.OverallSDProcessStatus <> 'C'
{
   key I_SalesOrderItem.SalesOrder,
   key I_SalesOrderItem.SalesOrderItem,
       _SalesOrder.OverallSDProcessStatus,
       
       _SalesOrder
  
   
  
   
}
