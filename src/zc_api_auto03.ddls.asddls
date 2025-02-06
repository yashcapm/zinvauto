@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Basic view for Journal'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity zc_api_auto03 as select from zc_api_auto01
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
