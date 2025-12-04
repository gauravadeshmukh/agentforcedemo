/**
 * @description Handles REST API callouts to create incidents in external system
 * @author Claude
 * @date 2025-11-27
 */
public with sharing class IncidentAPICallout {

    // API Endpoint
    // Read from Custom Metadata: Heroku_Configuration__mdt (record name: HerokuAppAnalyzeErrorAPI)
    // Ensure the field API_Endpoint__c exists on the CMDT. Adjust the field API name if different.
    private static final String API_ENDPOINT = String.valueOf(Heroku_Configuration__mdt.getInstance('HerokuAppAnalyzeErrorAPI').Value__c);
       /**
     * @description Creates an incident by calling external REST API
     * @param errorMessage The error message from Application Exception
     * @param caller The user who triggered the exception
     * @return HttpResponse The response from the API
     */
    public static HttpResponse createIncident(String errorMessage, string errorShortmsg, string errorType, String caller) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(API_ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000); // 120 seconds timeout

        // Build JSON payload
        Map<String, String> payload = new Map<String, String>{
            'Error' => errorMessage,
            'errorType' => errorType,
            'errorshortmsg' => errorShortmsg
        };
        
        system.debug('Payload: ' + JSON.serialize(payload));
        req.setBody(JSON.serialize(payload));

        Http http = new Http();
        HttpResponse res;

        try {
            res = http.send(req);

            // Log the response
            System.debug('API Response Status: ' + res.getStatusCode());
            System.debug('API Response Body: ' + res.getBody());

            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                System.debug('Incident created successfully');
            } else {
                System.debug(LoggingLevel.ERROR, 'Failed to create incident. Status: ' +
                           res.getStatusCode() + ', Body: ' + res.getBody());
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception during API callout: ' + e.getMessage());
            throw new IncidentAPIException('Failed to create incident: ' + e.getMessage(), e);
        }

        return res;
    }

    /**
     * @description Async method to create incident (use for trigger context)
     * @param errorMessage The error message from Application Exception
     * @param caller The user who triggered the exception
     */
    @future(callout=true)
    public static void createIncidentAsync(String errorMessage, string errorShortmsg, string errorType, String caller) {
        try {
            createIncident(errorMessage,errorShortmsg,errorType, caller);
        } catch (Exception e) {
            // Log error but don't fail the transaction
            System.debug(LoggingLevel.ERROR, 'Async incident creation failed: ' + e.getMessage());
        }
    }

    // /**
    //  * @description Batch process multiple Application Exceptions
    //  * @param exceptions List of Application Exception records
    //  */
    // public static void createIncidentsFromExceptions(List<Application_Exception__c> exceptions) {
    //     if (exceptions == null || exceptions.isEmpty()) {
    //         return;
    //     }

    //     for (Application_Exception__c appException : exceptions) {
    //         if (String.isNotBlank(appException.Message__c)) {
    //             String caller = getCaller(appException);

    //             // Use async callout to avoid governor limits
    //             createIncidentAsync(appException.Exception_Message__c, appException.Message__c,appException.Type__c,caller);
                
    //         }
    //     }
    // }

    // /**
    //  * @description Extracts caller information from Application Exception
    //  * @param appException The Application Exception record
    //  * @return String The caller email or username
    //  */
    // private static String getCaller(Application_Exception__c appException) {
    //     String caller = 'unknown@example.com';

    //     try {
    //         // Try to get CreatedBy user email
    //         if (appException.CreatedBy != null &&
    //             String.isNotBlank(appException.CreatedBy.Email)) {
    //             caller = appException.CreatedBy.Email;
    //         } else if (appException.CreatedBy != null &&
    //                   String.isNotBlank(appException.CreatedBy.Username)) {
    //             caller = appException.CreatedBy.Username;
    //         }
    //     } catch (Exception e) {
    //         System.debug('Could not retrieve caller info: ' + e.getMessage());
    //     }

    //     return caller;
    // }

    /**
     * @description Custom exception for API errors
     */
    public class IncidentAPIException extends Exception {}
}
