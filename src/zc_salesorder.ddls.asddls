//@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'SalesOrder'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZC_SALESORDER as select from I_BillingDocument as _invheader
{
    key _invheader.BillingDocument as salesorder,
    _invheader.SDDocumentCategory,
    _invheader.BillingDocumentCategory,
    _invheader.BillingDocumentType,
    _invheader.CreatedByUser,
    _invheader.CreationDate
    
   }
