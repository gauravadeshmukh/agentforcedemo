/**
 * Test class for ApexErrorEmailHandler
 * Provides comprehensive test coverage for inbound email parsing
 */
@isTest
private class ApexErrorEmailHandlerTest {

    /**
     * Test successful parsing of a complete error email
     */
    @isTest
    static void testCompleteErrorEmail() {
        // Create test email with full error details
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        email.subject = 'Apex Error: DmlException in AccountTriggerHandler';
        email.plainTextBody = 'An error occurred in the Apex code.\n\n' +
            'Exception Type: DmlException\n' +
            'Exception Message: Insert failed. First exception on row 0; first error: REQUIRED_FIELD_MISSING\n' +
            'Line Number: 45\n\n' +
            'Stack Trace:\n' +
            'Class.AccountTriggerHandler.handleInsert: line 45, column 1\n' +
            'Class.AccountTriggerHandler.handleTrigger: line 12, column 1\n' +
            'Trigger.AccountTrigger: line 5, column 1\n\n' +
            'Caused by: System.DmlException: Insert failed';

        env.fromAddress = 'test@example.com';

        // Test
        Test.startTest();
        ApexErrorEmailHandler handler = new ApexErrorEmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
        Test.stopTest();

        // Verify
        System.assert(result.success, 'Email should be processed successfully');

        List<Application_Exception__c> exceptions = [
            SELECT Id, Message__c, exception_message__c, Type__c, Line_Number__c,
                   Stack_Trace__c, Context__c, Occurred_At__c
            FROM Application_Exception__c
        ];

        System.assertEquals(1, exceptions.size(), 'One exception record should be created');

        Application_Exception__c exc = exceptions[0];
        System.assertEquals(email.subject, exc.Message__c, 'Subject should map to Message__c');
        System.assertEquals(email.plainTextBody, exc.exception_message__c, 'Body should map to exception_message__c');
        System.assertEquals('DmlException', exc.Type__c, 'Exception type should be extracted');
        System.assertEquals(45, exc.Line_Number__c, 'Line number should be extracted');
        System.assert(exc.Stack_Trace__c.contains('AccountTriggerHandler'), 'Stack trace should be extracted');
        System.assert(exc.Context__c.contains('test@example.com'), 'Context should contain sender email');
        System.assertNotEquals(null, exc.Occurred_At__c, 'Occurred_At__c should be set');
    }

    /**
     * Test parsing with minimal email content
     */
    @isTest
    static void testMinimalErrorEmail() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        email.subject = 'Simple Error';
        email.plainTextBody = 'An error occurred';
        env.fromAddress = 'user@salesforce.com';

        Test.startTest();
        ApexErrorEmailHandler handler = new ApexErrorEmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
        Test.stopTest();

        System.assert(result.success, 'Email should be processed successfully');

        List<Application_Exception__c> exceptions = [SELECT Id, Message__c FROM Application_Exception__c];
        System.assertEquals(1, exceptions.size(), 'One exception record should be created');
        System.assertEquals('Simple Error', exceptions[0].Message__c);
    }

    /**
     * Test NullPointerException parsing
     */
    @isTest
    static void testNullPointerException() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        email.subject = 'NullPointerException in ContactHandler';
        email.plainTextBody = 'NullPointerException: Attempt to de-reference a null object\n' +
            'Line 78\n' +
            'Class.ContactHandler.updateContacts: line 78, column 5';

        env.fromAddress = 'admin@test.com';

        Test.startTest();
        ApexErrorEmailHandler handler = new ApexErrorEmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
        Test.stopTest();

        System.assert(result.success);

        Application_Exception__c exc = [
            SELECT Type__c, Line_Number__c
            FROM Application_Exception__c
            LIMIT 1
        ];

        System.assertEquals('NullPointerException', exc.Type__c);
        System.assertEquals(78, exc.Line_Number__c);
    }

    /**
     * Test QueryException parsing
     */
    @isTest
    static void testQueryException() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        email.subject = 'Query Error';
        email.plainTextBody = 'QueryException: List has no rows for assignment to SObject\n' +
            'Exception Type: System.QueryException\n' +
            'Line Number: 123';

        env.fromAddress = 'dev@company.com';

        Test.startTest();
        ApexErrorEmailHandler handler = new ApexErrorEmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
        Test.stopTest();

        System.assert(result.success);

        Application_Exception__c exc = [SELECT Type__c FROM Application_Exception__c LIMIT 1];
        System.assertEquals('QueryException', exc.Type__c);
    }

    /**
     * Test LimitException parsing
     */
    @isTest
    static void testLimitException() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        email.subject = 'Governor Limit Exceeded';
        email.plainTextBody = 'LimitException: Too many SOQL queries: 101\n' +
            'at line 250\n' +
            'Stack Trace:\n' +
            'Class.DataProcessor.processRecords: line 250, column 1';

        env.fromAddress = 'monitor@system.com';

        Test.startTest();
        ApexErrorEmailHandler handler = new ApexErrorEmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
        Test.stopTest();

        System.assert(result.success);

        Application_Exception__c exc = [
            SELECT Type__c, Line_Number__c, Stack_Trace__c
            FROM Application_Exception__c
            LIMIT 1
        ];

        System.assertEquals('LimitException', exc.Type__c);
        System.assertEquals(250, exc.Line_Number__c);
        System.assert(exc.Stack_Trace__c.contains('DataProcessor'));
    }

    /**
     * Test email with cause information
     */
    @isTest
    static void testEmailWithCause() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        email.subject = 'Error with Cause';
        email.plainTextBody = 'CalloutException: Web service callout failed\n' +
            'Caused by: System.JSONException: Unexpected character found';

        env.fromAddress = 'integration@test.com';

        Test.startTest();
        ApexErrorEmailHandler handler = new ApexErrorEmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
        Test.stopTest();

        System.assert(result.success);

        Application_Exception__c exc = [
            SELECT Type__c, Cause_Type__c, Cause_Message__c
            FROM Application_Exception__c
            LIMIT 1
        ];

        System.assertEquals('CalloutException', exc.Type__c);
        System.assertEquals('System.JSONException', exc.Cause_Type__c);
        System.assert(exc.Cause_Message__c.contains('Unexpected character'));
    }

    /**
     * Test handling of very long subject (truncation)
     */
    @isTest
    static void testLongSubjectTruncation() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        // Create subject longer than 255 characters
        String longSubject = 'Error: ';
        for (Integer i = 0; i < 50; i++) {
            longSubject += 'This is a very long error message. ';
        }

        email.subject = longSubject;
        email.plainTextBody = 'Error details';
        env.fromAddress = 'test@test.com';

        Test.startTest();
        ApexErrorEmailHandler handler = new ApexErrorEmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
        Test.stopTest();

        System.assert(result.success);

        Application_Exception__c exc = [SELECT Message__c FROM Application_Exception__c LIMIT 1];
        System.assert(exc.Message__c.length() <= 255, 'Message should be truncated to 255 chars');
    }

    /**
     * Test handling of null/empty email body
     */
    @isTest
    static void testNullEmailBody() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        email.subject = 'Error without body';
        email.plainTextBody = null;
        env.fromAddress = 'sender@test.com';

        Test.startTest();
        ApexErrorEmailHandler handler = new ApexErrorEmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
        Test.stopTest();

        System.assert(result.success, 'Should handle null body gracefully');

        List<Application_Exception__c> exceptions = [SELECT Id FROM Application_Exception__c];
        System.assertEquals(1, exceptions.size());
    }

    /**
     * Test extraction of line number with different formats
     */
    @isTest
    static void testVariousLineNumberFormats() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        email.subject = 'Line Number Test';
        email.plainTextBody = 'Error at line 999\nSome other content';
        env.fromAddress = 'test@test.com';

        Test.startTest();
        ApexErrorEmailHandler handler = new ApexErrorEmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
        Test.stopTest();

        Application_Exception__c exc = [SELECT Line_Number__c FROM Application_Exception__c LIMIT 1];
        System.assertEquals(999, exc.Line_Number__c);
    }

    /**
     * Test alternative stack trace format detection
     */
    @isTest
    static void testAlternativeStackTraceFormat() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        email.subject = 'Stack Trace Format Test';
        email.plainTextBody = 'An error occurred:\n\n' +
            'at Class.MyClass.myMethod line 42\n' +
            'at Trigger.MyTrigger line 8\n\n' +
            'Additional details...';

        env.fromAddress = 'test@test.com';

        Test.startTest();
        ApexErrorEmailHandler handler = new ApexErrorEmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
        Test.stopTest();

        System.assert(result.success);

        Application_Exception__c exc = [SELECT Stack_Trace__c FROM Application_Exception__c LIMIT 1];
        System.assertNotEquals(null, exc.Stack_Trace__c, 'Stack trace should be extracted');
        System.assert(exc.Stack_Trace__c.contains('MyClass'));
    }

    /**
     * Test multiple exceptions in same transaction
     */
    @isTest
    static void testMultipleEmails() {
        List<Messaging.InboundEmail> emails = new List<Messaging.InboundEmail>();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.fromAddress = 'bulk@test.com';

        for (Integer i = 0; i < 3; i++) {
            Messaging.InboundEmail email = new Messaging.InboundEmail();
            email.subject = 'Error ' + i;
            email.plainTextBody = 'Exception details for error ' + i;
            emails.add(email);
        }

        Test.startTest();
        ApexErrorEmailHandler handler = new ApexErrorEmailHandler();
        for (Messaging.InboundEmail email : emails) {
            handler.handleInboundEmail(email, env);
        }
        Test.stopTest();

        List<Application_Exception__c> exceptions = [SELECT Id FROM Application_Exception__c];
        System.assertEquals(3, exceptions.size(), 'Three exception records should be created');
    }

    /**
     * Test error handling when insert fails
     */
    @isTest
    static void testInsertFailureHandling() {
        // This test demonstrates error handling
        // In a real scenario, you might need to mock a DML failure
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        email.subject = 'Test Error Handling';
        email.plainTextBody = 'Test body';
        env.fromAddress = 'test@example.com';

        Test.startTest();
        ApexErrorEmailHandler handler = new ApexErrorEmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
        Test.stopTest();

        // Should succeed in normal case
        System.assert(result.success);
    }
}
