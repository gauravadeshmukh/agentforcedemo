# Exception Handler Deployment Instructions

## Files Created

1. **ExceptionHandler.cls** - Main exception handler class
2. **ExceptionHandler.cls-meta.xml** - Metadata for ExceptionHandler
3. **ExceptionHandlerTest.cls** - Unit tests for exception handler
4. **ExceptionHandlerTest.cls-meta.xml** - Metadata for ExceptionHandlerTest

## Deployment Steps

To deploy these components to your Salesforce org, run the following command:

```bash
sf project deploy start --source-dir force-app/main/default/classes/ExceptionHandler.cls,force-app/main/default/classes/ExceptionHandler.cls-meta.xml,force-app/main/default/classes/ExceptionHandlerTest.cls,force-app/main/default/classes/ExceptionHandlerTest.cls-meta.xml
```

Alternatively, you can deploy using a manifest file:

```bash
sf project deploy start --manifest manifest/package.xml
```

## Testing

After deployment, you can run the tests using:

```bash
sf project test run --class-names ExceptionHandlerTest
```

## Key Features

- **Centralized Exception Handling**: Provides a single point for handling exceptions
- **Logging and Persistence**: Logs exceptions to the Application_Exception__c custom object
- **Structured Error Messages**: Creates detailed technical payloads for debugging
- **Flexible Rethrowing**: Can optionally rethrow exceptions as AppHandledException
- **Extra Context Support**: Allows passing additional context when logging exceptions

## Notes

- The test compilation issue has been resolved by modifying the test class to avoid direct Exception instantiation in test methods
- All components have been properly structured according to Salesforce best practices
- The exception handler provides centralized logging and persistence to the Application_Exception__c custom object
