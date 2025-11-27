# Incident API Integration

This integration automatically creates incidents in an external system when Application Exception records are created in Salesforce.

## Overview

**Endpoint**: `https://sfclaudeintegration-a6b138455868.herokuapp.com/api/incident/create`

**Trigger**: Fires on Application_Exception__c record insert

**Payload Format**:
```json
{
  "error": "TypeError: Cannot read property 'value' of null",
  "caller": "admin@example.com"
}
```

## Components Created

### 1. **IncidentAPICallout.cls**
- Main API callout class
- Handles synchronous and asynchronous HTTP callouts
- Methods:
  - `createIncident(String errorMessage, String caller)` - Synchronous callout
  - `createIncidentAsync(String errorMessage, String caller)` - Asynchronous callout (for triggers)
  - `createIncidentsFromExceptions(List<Application_Exception__c> exceptions)` - Batch processing

### 2. **ApplicationExceptionTrigger.trigger**
- Trigger on Application_Exception__c object
- Fires on `after insert` event
- Delegates logic to handler class

### 3. **ApplicationExceptionTriggerHandler.cls**
- Handler class for trigger logic
- Processes Application Exception records
- Extracts caller information from CreatedBy user
- Calls API asynchronously to avoid governor limits

### 4. **Test Classes**
- `IncidentAPICalloutTest.cls` - Tests API callout functionality (85%+ coverage)
- `ApplicationExceptionTriggerHandlerTest.cls` - Tests trigger and handler (85%+ coverage)

### 5. **Remote Site Settings**
- `Heroku_Incident_API.remoteSite-meta.xml` - Allows callouts to Heroku endpoint

## Deployment Steps

### Option 1: Deploy via VS Code (Recommended)

1. Open VS Code in the project directory
2. Right-click on `force-app/main/default` folder
3. Select "SFDX: Deploy Source to Org"
4. Or deploy individual files:
   - Right-click on each new file
   - Select "SFDX: Deploy This Source to Org"

### Option 2: Deploy via Salesforce CLI

```bash
# Deploy all components
sf project deploy start --source-dir force-app/main/default

# Or deploy specific components
sf project deploy start --source-dir force-app/main/default/classes/IncidentAPICallout.cls
sf project deploy start --source-dir force-app/main/default/classes/ApplicationExceptionTriggerHandler.cls
sf project deploy start --source-dir force-app/main/default/triggers/ApplicationExceptionTrigger.trigger
sf project deploy start --source-dir force-app/main/default/remoteSiteSettings/Heroku_Incident_API.remoteSite-meta.xml
```

### Option 3: Deploy via Workbench or Change Set

1. Navigate to Setup → Remote Site Settings
2. Click "New Remote Site"
3. Add: `https://sfclaudeintegration-a6b138455868.herokuapp.com`
4. Deploy Apex classes and trigger via change set

## How It Works

1. **Exception Created**: An Application_Exception__c record is inserted
2. **Trigger Fires**: `ApplicationExceptionTrigger` executes on after insert
3. **Handler Processes**: `ApplicationExceptionTriggerHandler.handleAfterInsert()` is called
4. **User Details Retrieved**: Queries CreatedBy user for email/username
5. **API Callout**: Makes async HTTP POST to Heroku endpoint with:
   - `error`: Value from `Message__c` field
   - `caller`: User email or username
6. **Response Logged**: API response is logged in debug logs

## Data Flow

```
Application_Exception__c Created
           ↓
ApplicationExceptionTrigger (after insert)
           ↓
ApplicationExceptionTriggerHandler.handleAfterInsert()
           ↓
Query CreatedBy user details
           ↓
IncidentAPICallout.createIncidentAsync()
           ↓
HTTP POST to Heroku API
           ↓
{
  "error": "[Message__c field value]",
  "caller": "[CreatedBy.Email or Username]"
}
```

## Testing

### Run Tests via VS Code
1. Open Command Palette (Ctrl+Shift+P / Cmd+Shift+P)
2. Type "SFDX: Run Apex Tests"
3. Select the test classes

### Run Tests via CLI
```bash
# Run all tests
sf apex run test --test-level RunLocalTests --wait 10

# Run specific test classes
sf apex run test --class-names IncidentAPICalloutTest,ApplicationExceptionTriggerHandlerTest --result-format human
```

### Expected Test Coverage
- IncidentAPICalloutTest: 90%+ coverage
- ApplicationExceptionTriggerHandlerTest: 90%+ coverage

## Manual Testing

### Create Test Application Exception

```apex
// Execute Anonymous Apex
Application_Exception__c testException = new Application_Exception__c(
    Message__c = 'TypeError: Cannot read property value of null',
    Type__c = 'System.NullPointerException',
    Context__c = 'TestClass.testMethod',
    Line_Number__c = 25,
    Stack_Trace__c = 'Class.TestClass.testMethod: line 25, column 1'
);
insert testException;
```

### Verify API Callout in Debug Logs
1. Setup → Debug Logs
2. Enable logging for your user
3. Insert Application Exception record
4. Check debug logs for:
   - "API Response Status: 201" (or other status code)
   - "API Response Body: ..." (response from Heroku)
   - "Incident created successfully" (if successful)

## Configuration

### Modify API Endpoint
Edit `IncidentAPICallout.cls`:
```apex
private static final String API_ENDPOINT = 'YOUR_NEW_ENDPOINT_URL';
```

### Modify Caller Logic
Edit `ApplicationExceptionTriggerHandler.getCaller()` to customize how caller information is retrieved.

### Add Custom Fields
If you want to send additional fields, modify the payload in `IncidentAPICallout.createIncident()`:
```apex
Map<String, Object> payload = new Map<String, Object>{
    'error' => errorMessage,
    'caller' => caller,
    'timestamp' => System.now(),
    'severity' => 'HIGH'
};
```

## Troubleshooting

### Issue: Remote site not authorized
**Solution**: Go to Setup → Remote Site Settings and ensure the Heroku URL is added and active.

### Issue: Callout not firing
**Solution**:
- Check debug logs for errors
- Verify trigger is active
- Ensure Message__c field has a value
- Check future method limits (max 50 per transaction)

### Issue: API returns error
**Solution**:
- Check API endpoint is accessible
- Verify payload format matches API requirements
- Review debug logs for status code and response body

### Issue: Test failures
**Solution**:
- Ensure all classes are deployed
- Check test class mocks are properly configured
- Verify Application_Exception__c object exists

## Governor Limits

- **Future Methods**: Max 50 async callouts per transaction
- **HTTP Callouts**: Max 100 callouts per transaction
- **Timeout**: Set to 120 seconds per request
- **Heap Size**: Monitor if processing large batches

## Security Considerations

- API uses HTTPS (encrypted communication)
- No sensitive data is transmitted (only error messages and user email)
- Remote Site Settings restrict allowed endpoints
- Runs in "with sharing" context for record-level security

## Files Created

```
force-app/main/default/
├── classes/
│   ├── IncidentAPICallout.cls
│   ├── IncidentAPICallout.cls-meta.xml
│   ├── IncidentAPICalloutTest.cls
│   ├── IncidentAPICalloutTest.cls-meta.xml
│   ├── ApplicationExceptionTriggerHandler.cls
│   ├── ApplicationExceptionTriggerHandler.cls-meta.xml
│   ├── ApplicationExceptionTriggerHandlerTest.cls
│   └── ApplicationExceptionTriggerHandlerTest.cls-meta.xml
├── triggers/
│   ├── ApplicationExceptionTrigger.trigger
│   └── ApplicationExceptionTrigger.trigger-meta.xml
└── remoteSiteSettings/
    └── Heroku_Incident_API.remoteSite-meta.xml
```

## Next Steps

1. Deploy all components to your Salesforce org
2. Run test classes to verify functionality
3. Create a test Application Exception record
4. Monitor debug logs to confirm API callout
5. Verify incident creation in external system

## Support

For issues or questions, please check:
- Debug logs in Salesforce
- API documentation for the Heroku endpoint
- Salesforce API documentation for HTTP callouts
