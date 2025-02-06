@EndUserText.label: 'Projection View For Journal Entry'
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity ZI_JE_N1 
provider contract transactional_query
as projection on ZR_JE_N1
{
    key SalesOrder,
//    key SalesOrderItem,
    CreationDate,
//    PurchaseRequisition,
//    PurchaseRequisitionItem,
    /* Associations */
    _SalesOrder
//    _ScheduleLine
}
