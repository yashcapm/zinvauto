@EndUserText.label: 'Projection view for Salesorder'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_SALESORDER01
provider contract transactional_query
 as projection on ZC_SALESORDER
{
  key SalesOrder
  
}
