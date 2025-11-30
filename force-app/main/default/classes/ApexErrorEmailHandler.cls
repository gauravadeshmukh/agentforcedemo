/**
 * Inbound Email Handler for parsing Apex error notification emails
 * and storing them as Application_Exception__c records.
 *
 * This class parses incoming error emails and extracts:
 * - Email Subject -> Message__c
 * - Email Body -> exception_message__c
 * - Extracted error details -> Type__c, Line_Number__c, Stack_Trace__c, etc.
 */
public class ApexErrorEmailHandler implements Messaging.InboundEmailHandler {

    /**
     * Main handler method for processing inbound emails
     */
    public Messaging.InboundEmailResult handleInboundEmail(
        Messaging.InboundEmail email,
        Messaging.InboundEnvelope envelope
    ) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        try {
            // Create Application Exception record from email
            Application_Exception__c appException = parseEmailToException(email, envelope);

            // Insert the exception record
            insert appException;

            result.success = true;
            result.message = 'Successfully created Application Exception: ' + appException.Name;

        } catch (Exception e) {
            result.success = false;
            result.message = 'Failed to process email: ' + e.getMessage();

            // Log the error
            System.debug(LoggingLevel.ERROR, 'ApexErrorEmailHandler failed: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
        }

        return result;
    }

    /**
     * Parse email content into Application_Exception__c record
     */
    private Application_Exception__c parseEmailToException(
        Messaging.InboundEmail email,
        Messaging.InboundEnvelope envelope
    ) {
        Application_Exception__c appException = new Application_Exception__c();

        // Basic email mapping
        appException.Message__c = truncateText(email.subject, 255); // Subject -> Message__c
        appException.exception_message__c = email.plainTextBody; // Body -> exception_message__c
        appException.Occurred_At__c = System.now();
        appException.Context__c = 'Email from: ' + envelope.fromAddress;

        // Parse error details from email body
        String emailBody = email.plainTextBody != null ? email.plainTextBody : '';

        // Extract Exception Type
        appException.Type__c = extractExceptionType(email.subject, emailBody);

        // Extract Line Number
        Integer lineNumber = extractLineNumber(emailBody);
        if (lineNumber != null) {
            appException.Line_Number__c = lineNumber;
        }

        // Extract Stack Trace
        String stackTrace = extractStackTrace(emailBody);
        if (String.isNotBlank(stackTrace)) {
            appException.Stack_Trace__c = truncateText(stackTrace, 131072);
        }

        // Extract Cause information if present
        Map<String, String> causeInfo = extractCauseInfo(emailBody);
        if (causeInfo.containsKey('type')) {
            appException.Cause_Type__c = truncateText(causeInfo.get('type'), 255);
        }
        if (causeInfo.containsKey('message')) {
            appException.Cause_Message__c = truncateText(causeInfo.get('message'), 255);
        }

        return appException;
    }

    /**
     * Extract exception type from subject or body
     * Looks for patterns like: "ExceptionType:", "Type: ExceptionType", etc.
     */
    private String extractExceptionType(String subject, String body) {
        String exceptionType = 'Unknown';

        // Common Apex exception types to look for
        List<String> commonExceptions = new List<String>{
            'DmlException', 'NullPointerException', 'QueryException',
            'LimitException', 'CalloutException', 'JSONException',
            'TypeException', 'MathException', 'StringException',
            'ListException', 'InvalidParameterValueException'
        };

        // Check subject first
        for (String exType : commonExceptions) {
            if (subject != null && subject.containsIgnoreCase(exType)) {
                return exType;
            }
        }

        // Check body
        for (String exType : commonExceptions) {
            if (body.containsIgnoreCase(exType)) {
                return exType;
            }
        }

        // Try to extract from pattern "Exception Type: XYZ" or "Type: XYZ"
        Pattern typePattern = Pattern.compile('(?i)(?:Exception\\s+)?Type\\s*:\\s*([\\w\\.]+)');
        Matcher typeMatcher = typePattern.matcher(body);
        if (typeMatcher.find()) {
            return typeMatcher.group(1);
        }

        // Try to find any word ending with "Exception"
        Pattern exceptionPattern = Pattern.compile('([A-Z][a-zA-Z]*Exception)');
        Matcher exceptionMatcher = exceptionPattern.matcher(body);
        if (exceptionMatcher.find()) {
            return exceptionMatcher.group(1);
        }

        return exceptionType;
    }

    /**
     * Extract line number from email body
     * Looks for patterns like: "line 123", "Line Number: 123", etc.
     */
    private Integer extractLineNumber(String body) {
        if (String.isBlank(body)) return null;

        // Pattern for "line XXX" or "Line Number: XXX"
        Pattern linePattern = Pattern.compile('(?i)line\\s+(?:number\\s*:\\s*)?([0-9]+)');
        Matcher lineMatcher = linePattern.matcher(body);

        if (lineMatcher.find()) {
            try {
                return Integer.valueOf(lineMatcher.group(1));
            } catch (Exception e) {
                return null;
            }
        }

        return null;
    }

    /**
     * Extract stack trace from email body
     * Looks for text between "Stack Trace:" and the next section or end
     */
    private String extractStackTrace(String body) {
        if (String.isBlank(body)) return null;

        // Look for "Stack Trace:" followed by content
        Pattern stackPattern = Pattern.compile(
            '(?i)stack\\s+trace\\s*:?\\s*([\\s\\S]*?)(?=\\n\\n|$)'
        );
        Matcher stackMatcher = stackPattern.matcher(body);

        if (stackMatcher.find()) {
            return stackMatcher.group(1).trim();
        }

        // Alternative: Look for content that looks like a stack trace
        // (lines starting with "at " or "Class." or containing line numbers)
        Pattern altStackPattern = Pattern.compile(
            '((?:^|\\n)(?:at\\s|Class\\.|Trigger\\.).+?line\\s+\\d+[\\s\\S]*?)(?:\\n\\n|$)'
        );
        Matcher altStackMatcher = altStackPattern.matcher(body);

        if (altStackMatcher.find()) {
            return altStackMatcher.group(1).trim();
        }

        return null;
    }

    /**
     * Extract cause exception information from email body
     */
    private Map<String, String> extractCauseInfo(String body) {
        Map<String, String> causeInfo = new Map<String, String>();

        if (String.isBlank(body)) return causeInfo;

        // Look for "Caused by:" pattern
        Pattern causePattern = Pattern.compile(
            '(?i)caused\\s+by\\s*:\\s*([\\w\\.]+)\\s*:?\\s*([^\\n]*)'
        );
        Matcher causeMatcher = causePattern.matcher(body);

        if (causeMatcher.find()) {
            causeInfo.put('type', causeMatcher.group(1));
            if (String.isNotBlank(causeMatcher.group(2))) {
                causeInfo.put('message', causeMatcher.group(2).trim());
            }
        }

        return causeInfo;
    }

    /**
     * Utility method to truncate text to specified length
     */
    private String truncateText(String text, Integer maxLength) {
        if (String.isBlank(text)) return text;
        return text.length() > maxLength ? text.substring(0, maxLength) : text;
    }
}
