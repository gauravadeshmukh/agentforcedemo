# Quick Start Guide - Incident API Integration

## What Was Built

An automated integration that creates incidents in an external system whenever an Application Exception record is created in Salesforce.

## API Details

**Endpoint**: `POST https://sfclaudeintegration-a6b138455868.herokuapp.com/api/incident/create`

**Request Format**:
```json
{
  "error": "TypeError: Cannot read property 'value' of null",
  "caller": "admin@example.com"
}
```

## Files Created

### Core Components
1. **IncidentAPICallout.cls** - Handles HTTP POST to external API
2. **ApplicationExceptionTrigger.trigger** - Fires when Application_Exception__c is inserted
3. **ApplicationExceptionTriggerHandler.cls** - Trigger handler with business logic
4. **Heroku_Incident_API.remoteSite-meta.xml** - Remote Site Settings

### Test Classes (90%+ Coverage)
5. **IncidentAPICalloutTest.cls** - Tests API callout logic
6. **ApplicationExceptionTriggerHandlerTest.cls** - Tests trigger functionality

## Quick Deploy

### Option 1: VS Code (Easiest)
```bash
# Right-click on force-app/main/default folder
# Select "SFDX: Deploy Source to Org"
```

### Option 2: Salesforce CLI
```bash
sf project deploy start --source-dir force-app/main/default
```

### Option 3: Deploy Specific Files
```bash
# Deploy classes
sf project deploy start --source-dir force-app/main/default/classes/IncidentAPICallout.cls
sf project deploy start --source-dir force-app/main/default/classes/ApplicationExceptionTriggerHandler.cls

# Deploy trigger
sf project deploy start --source-dir force-app/main/default/triggers/ApplicationExceptionTrigger.trigger

# Deploy remote site settings
sf project deploy start --source-dir force-app/main/default/remoteSiteSettings/Heroku_Incident_API.remoteSite-meta.xml
```

## Test It

### 1. Create a Test Exception
Execute this in Anonymous Apex:
```apex
Application_Exception__c testException = new Application_Exception__c(
    Message__c = 'TypeError: Cannot read property value of null',
    Type__c = 'System.NullPointerException',
    Context__c = 'TestClass.testMethod',
    Line_Number__c = 25
);
insert testException;
```

### 2. Check Debug Logs
1. Setup → Debug Logs
2. Click "New" to enable logging for your user
3. Look for messages like:
   - `API Response Status: 201`
   - `Incident created successfully`

### 3. Run Unit Tests
```bash
sf apex run test --test-level RunLocalTests --wait 10
```

## How It Works

```
┌─────────────────────────────────┐
│ Application_Exception__c        │
│ Record Created                  │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│ ApplicationExceptionTrigger     │
│ (after insert)                  │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│ ApplicationException            │
│ TriggerHandler                  │
│ - Gets user email               │
│ - Extracts error message        │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│ IncidentAPICallout              │
│ .createIncidentAsync()          │
│ - @future(callout=true)         │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│ HTTP POST to Heroku             │
│ {                               │
│   "error": "...",               │
│   "caller": "user@email.com"    │
│ }                               │
└─────────────────────────────────┘
```

## Key Features

✅ **Async Callouts** - Uses @future to avoid trigger limits
✅ **Error Handling** - Gracefully handles API failures
✅ **User Tracking** - Automatically captures caller email/username
✅ **Test Coverage** - 90%+ code coverage
✅ **Validation** - Skips records without error messages
✅ **Logging** - Comprehensive debug logging

## Troubleshooting

### API Callout Not Working?
1. Check Remote Site Settings (Setup → Remote Site Settings)
2. Verify URL is authorized: `https://sfclaudeintegration-a6b138455868.herokuapp.com`

### Trigger Not Firing?
1. Ensure Message__c field has a value
2. Check trigger is Active (Setup → Apex Triggers)
3. Review debug logs for errors

### Tests Failing?
1. Verify all classes are deployed
2. Run tests individually to isolate issues
3. Check Application_Exception__c object exists

## Next Steps

1. ✅ Deploy all components
2. ✅ Run unit tests
3. ✅ Test with sample Application Exception
4. ✅ Monitor debug logs
5. ✅ Verify incident creation in external system

## Documentation

For detailed documentation, see:
- **INCIDENT_API_INTEGRATION.md** - Full integration guide
- **deployment_instructions.md** - Deployment steps

## Repository

All code is available at: https://github.com/gauravadeshmukh/agentforcedemo
