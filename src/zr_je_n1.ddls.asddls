@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Root View For Journal Entry'
define root view entity ZR_JE_N1 as select from zc_api_auto03

{
key SalesOrder,
//key SalesOrderItem,
CreationDate,
//PurchaseRequisition,
//PurchaseRequisitionItem,
/* Associations */
_SalesOrder
//_ScheduleLine
}
