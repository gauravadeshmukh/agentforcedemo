public with sharing class ExceptionHandler {
    public class AppHandledException extends Exception {}

    // Primary handler: capture, log and optionally rethrow as AppHandledException
    public static void handle(Exception e, String context) {
        handle(e, context, null, false);
    }
    public static void handle(Exception e, String context, Boolean rethrow) {
        log(e, context, null);
    }
    public static void handle(Exception e, String context, Map<String, Object> extra) {
        log(e, context, extra);
    }
    public static void handle(Exception e, String context, Map<String, Object> extra, Boolean rethrow) {
        // Build structured detail and log it
    
          log(e, context, extra);
      
    }



    public static void log(Exception e, String context, Map<String, Object> extra) {
        // Persist a structured record
        try {
            Integer lineNumber;
            try { lineNumber = e == null ? null : e.getLineNumber(); } catch (Exception x) { lineNumber = null; }
            Exception cause;
            try { cause = e == null ? null : e.getCause(); } catch (Exception x) { cause = null; }

            Application_Exception__c rec = new Application_Exception__c();
            rec.Occurred_At__c = System.now();
            rec.Context__c = context;
            rec.Type__c = e == null ? 'NULL' : e.getTypeName();
            rec.Message__c = e == null ? '' : e.getMessage();
            if (lineNumber != null) rec.Line_Number__c = lineNumber;
            rec.Cause_Type__c = cause == null ? '' : cause.getTypeName();
            rec.Cause_Message__c = cause == null ? '' : cause.getMessage();
            rec.Stack_Trace__c = e == null ? '' : e.getStackTraceString();
            rec.exception_message__c = formatExceptionForAI(e);
           
            try { rec.User__c = UserInfo.getUserId(); } catch (Exception x) {}

            insert rec;
        } catch (Exception ignore) {
            System.debug(LoggingLevel.ERROR, '[ExceptionHandler] Failed to persist exception to Application_Exception__c: ' + ignore.getMessage());
        }
    }


    /**
     * Captures and formats all relevant details of an Apex exception into a single string.
     * This string can be used as the input for an AI analysis prompt.
     *
     * @param e The exception object caught in a try-catch block.
     * @return A formatted string containing the error details.
     */
    public static String formatExceptionForAI(Exception e) {
        String exceptionDetails = '### Input Data:\n';
        
        // 1. Get the primary message (e.g., specific DML error details)
        exceptionDetails += '*   **Exception Message: ' + e.getMessage() + '\n';
        
        // 2. Get the specific line number where the error occurred
        exceptionDetails += '*   **Line Number: ' + e.getLineNumber() + '\n';
        
        // 3. Get the type of exception (e.g., DmlException, LimitException)
        exceptionDetails += '*   **Exception Type: `' + e.getTypeName() + '\n';

        // 4. Get the full stack trace (essential for debugging the execution path)
        // This often includes internal Salesforce method calls but helps pinpoint the origin.
        String stackTrace = e.getStackTraceString();
        if (stackTrace != null && stackTrace != '') {
            // Escape any backticks that might exist in the stack trace itself if necessary for markdown formatting
            stackTrace = stackTrace.replace('`', '\\`'); 
            exceptionDetails += '*   **Stack Trace:\n \n' + stackTrace + '\n \n';
        } else {
            exceptionDetails += '*   **Stack Trace:** `Not available`\n';
        }
        
        // Note: You would need to manually insert the 'Relevant Apex Code Snippet' into the prompt 
        // as Apex cannot read its own source code dynamically.

        return exceptionDetails;
    }


}