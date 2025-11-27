public with sharing class ExceptionHandler {
    public class AppHandledException extends Exception {}

    // Primary handler: capture, log and optionally rethrow as AppHandledException
    public static void handle(Exception e, String context) {
        handle(e, context, null, false);
    }
    public static void handle(Exception e, String context, Boolean rethrow) {
        handle(e, context, null, rethrow);
    }
    public static void handle(Exception e, String context, Map<String, Object> extra) {
        handle(e, context, extra, false);
    }
    public static void handle(Exception e, String context, Map<String, Object> extra, Boolean rethrow) {
        // Build structured detail and log it
        String detail = buildDetail(e, context, extra);
        log(detail);

        // Optionally rethrow a sanitized, consistent exception type
        if (rethrow == true) {
            String message = buildMessage(e, context);
            AppHandledException ex = new AppHandledException(message);
            // Preserve original stack trace reference in debug for traceability
            System.debug(LoggingLevel.ERROR, 'EXC_ORIGINAL_STACK=' + e.getStackTraceString());
            throw ex;
        }
    }

    // Returns a concise user-facing message that can be surfaced in UI or flows
    public static String buildMessage(Exception e, String context) {
        String base = 'An unexpected error occurred';
        String ctx = String.isBlank(context) ? '' : ' while ' + context;
        // Prefer e.getMessage(), fall back to type name
        String msg = e != null && !String.isBlank(e.getMessage()) ? e.getMessage() : (e == null ? 'Unknown exception' : e.getTypeName());
        return base + ctx + '. ' + 'Details: ' + msg;
    }

    // Returns a detailed technical payload (safe for logs, not for end users)
    public static String buildDetail(Exception e, String context) {
        return buildDetail(e, context, null);
    }
    public static String buildDetail(Exception e, String context, Map<String, Object> extra) {
        if (e == null) {
            return 'EXC| ts=' + DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') +
                   ' | context=' + safe(context) +
                   ' | type=NULL | message=NULL | line=NULL | cause=NULL | stack=NULL' +
                   buildExtra(extra);
        }
        Integer lineNumber;
        try {
            lineNumber = e.getLineNumber();
        } catch (Exception ignore) {
            lineNumber = null;
        }
        Exception cause;
        try {
            cause = e.getCause();
        } catch (Exception ignore) {
            cause = null;
        }
        String typeName = safe(e.getTypeName());
        String message = safe(e.getMessage());
        String stack = safe(e.getStackTraceString());
        String causeType = cause == null ? '' : safe(cause.getTypeName());
        String causeMsg = cause == null ? '' : safe(cause.getMessage());

        String ts = DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        String ctx = safe(context);

        return 'EXC| ts=' + ts +
               ' | context=' + ctx +
               ' | type=' + typeName +
               ' | message=' + message +
               ' | line=' + (lineNumber == null ? '' : String.valueOf(lineNumber)) +
               ' | causeType=' + causeType +
               ' | causeMsg=' + causeMsg +
               ' | stack=' + stack +
               buildExtra(extra);
    }

    // Centralized logging: debug + persist to Application_Exception__c custom object
    public static void log(String detail) {
        System.debug(LoggingLevel.ERROR, '[ExceptionHandler] ' + detail);
        // Best-effort persistence when called inside a transaction
        try {
            Application_Exception__c rec = new Application_Exception__c();
            rec.Occurred_At__c = System.now();
            rec.Message__c = detail; // store the whole detail payload for quick visibility
            // Extra parsing is handled in the overload that has Exception/context/extra to populate discrete fields
            insert rec;
        } catch (Exception ignore) {
            // Avoid recursive failures; log only
            System.debug(LoggingLevel.ERROR, '[ExceptionHandler] Failed to persist detail to Application_Exception__c: ' + ignore.getMessage());
        }
    }
    public static void log(Exception e, String context) {
        log(e, context, null);
    }
    public static void log(Exception e, String context, Map<String, Object> extra) {
        System.debug(LoggingLevel.ERROR, '[ExceptionHandler] ' + buildDetail(e, context, extra));
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

            // Flatten extra map into string
            if (extra != null && !extra.isEmpty()) {
                List<String> kvs = new List<String>();
                for (String k : extra.keySet()) {
                    kvs.add(k + '=' + safe(extra.get(k)));
                }
                rec.Extra__c = String.join(kvs, ',');
            }
            try { rec.User__c = UserInfo.getUserId(); } catch (Exception x) {}

            insert rec;
        } catch (Exception ignore) {
            System.debug(LoggingLevel.ERROR, '[ExceptionHandler] Failed to persist exception to Application_Exception__c: ' + ignore.getMessage());
        }
    }

    // Helper to append extra context map
    private static String buildExtra(Map<String, Object> extra) {
        if (extra == null || extra.isEmpty()) {
            return '';
        }
        List<String> kvs = new List<String>();
        for (String k : extra.keySet()) {
            Object v = extra.get(k);
            kvs.add(k + '=' + safe(v));
        }
        return ' | extra={' + String.join(kvs, ',') + '}';
    }

    // Null-safe stringify and basic trimming for logs
    private static String safe(Object o) {
        if (o == null) return '';
        String s = String.valueOf(o);
        // Avoid gigantic log lines; trim to a reasonable length
        Integer max = 10000;
        if (s.length() > max) {
            return s.substring(0, max) + '...TRUNCATED(' + (s.length() - max) + ')';
        }
        return s;
        }
}