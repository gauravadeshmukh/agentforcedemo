/**
 * @description Handler class for Application Exception trigger
 * @author Claude
 * @date 2025-11-27
 */
public with sharing class ApplicationExceptionTriggerHandler {

    /**
     * @description Handles after insert trigger event
     * @param newExceptions List of newly inserted Application Exception records
     */
    public static void handleAfterInsert(List<Application_Exception__c> newExceptions) {
        if (newExceptions == null || newExceptions.isEmpty()) {
            return;
        }

        // Query to get CreatedBy user details for caller information
        Set<Id> exceptionIds = new Set<Id>();
        for (Application_Exception__c ex : newExceptions) {
            exceptionIds.add(ex.Id);
        }

        // Query with CreatedBy relationship
        List<Application_Exception__c> exceptionsWithUser = [
            SELECT Id, Message__c, CreatedBy.Email, CreatedBy.Username
            FROM Application_Exception__c
            WHERE Id IN :exceptionIds
        ];

        // Process each exception and make API callout
        processExceptions(exceptionsWithUser);
    }

    /**
     * @description Process exceptions and trigger API callout
     * @param exceptions List of Application Exception records
     */
    private static void processExceptions(List<Application_Exception__c> exceptions) {
        for (Application_Exception__c appException : exceptions) {
            // Validate that Message field has a value
            if (String.isNotBlank(appException.Message__c)) {
                String caller = getCaller(appException);

                // Make async API callout
                IncidentAPICallout.createIncidentAsync(appException.Message__c, caller);
            } else {
                System.debug(LoggingLevel.WARN,
                    'Application Exception ' + appException.Id + ' has no message. Skipping API callout.');
            }
        }
    }

    /**
     * @description Extracts caller information from Application Exception
     * @param appException The Application Exception record
     * @return String The caller email or username
     */
    private static String getCaller(Application_Exception__c appException) {
        String caller = 'unknown@example.com';

        try {
            // Try to get CreatedBy user email
            if (appException.CreatedBy != null &&
                String.isNotBlank(appException.CreatedBy.Email)) {
                caller = appException.CreatedBy.Email;
            } else if (appException.CreatedBy != null &&
                      String.isNotBlank(appException.CreatedBy.Username)) {
                caller = appException.CreatedBy.Username;
            }
        } catch (Exception e) {
            System.debug('Could not retrieve caller info: ' + e.getMessage());
        }

        return caller;
    }
}
