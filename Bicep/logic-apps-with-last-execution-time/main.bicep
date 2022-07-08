var demoName = 'demoblog'
var partitionKey = 'demoblog'
var rowKey = 'lastexecution'

resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: '${demoName}${uniqueString(deployment().name)}'
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

resource tableService 'Microsoft.Storage/storageAccounts/tableServices@2021-09-01' = {
  name: 'default'
  parent: storage
}

resource table 'Microsoft.Storage/storageAccounts/tableServices/tables@2021-09-01' = {
  name: 'config'
  parent: tableService
}

resource customIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: '${demoName}${uniqueString(deployment().name)}'
  location: resourceGroup().location
}

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: '${demoName}${uniqueString(deployment().name)}'
  location: resourceGroup().location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${customIdentity.id}': {}
    }
  }
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {
          }
          type: 'Object'
        }
      }
      triggers: {
        recurrence: {
          type: 'recurrence'
          recurrence: {
            interval: 1
            frequency: 'Day'
          }
        }
      }
      actions: {
        Get_Last_Time_Execution: {
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azuretables\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/v2/storageAccounts/@{encodeURIComponent(encodeURIComponent(\'${storage.name}\'))}/tables/@{encodeURIComponent(\'${table.name}\')}/entities(PartitionKey=\'@{encodeURIComponent(\'${partitionKey}\')}\',RowKey=\'@{encodeURIComponent(\'${rowKey}\')}\')'
          }
          runAfter: {
          }
          type: 'ApiConnection'
        }
        Update_Last_Time_Execution: {
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azuretables\'][\'connectionId\']'
              }
            }
            method: 'put'
            body: {
              Value: '@{utcNow() }'
            }
            path: '/v2/storageAccounts/@{encodeURIComponent(encodeURIComponent(\'${storage.name}\'))}/tables/@{encodeURIComponent(\'${table.name}\')}/entities(PartitionKey=\'@{encodeURIComponent(\'${partitionKey}\')}\',RowKey=\'@{encodeURIComponent(\'${rowKey}\')}\')'
          }
          runAfter: {
            Get_Last_Time_Execution: [
              'Succeeded'
              'Failed'
            ]
          }
          type: 'ApiConnection'
        }
      }
    }
    parameters: {
      '$connections': {
        value: {
          azuretables: {
            connectionId: azuretables.id
            connectionName: 'azuretables'
            connectionProperties: {
              authentication: {
                identity: customIdentity.id
                type: 'ManagedServiceIdentity'
              }
            }
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis',  resourceGroup().location,  'azuretables')
          }
        }
      }
    }
  }
}

resource roleAssignement 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  scope: storage
  name: guid('${demoName}${uniqueString(deployment().name)}')
  properties: {
    principalId: customIdentity.properties.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3')
    principalType: 'ServicePrincipal'
  }
}
resource azuretables 'Microsoft.Web/connections@2016-06-01' = {

  name: 'azuretables'
  location: resourceGroup().location
  properties: {
    displayName: 'storage'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', resourceGroup().location, 'azuretables')
    }
    customParameterValues: {
    }
    'parameterValueSet': {
      name: 'managedIdentityAuth'
      values: {
      }
    }
  }
}
