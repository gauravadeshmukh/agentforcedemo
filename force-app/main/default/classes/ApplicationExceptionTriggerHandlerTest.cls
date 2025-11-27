/**
 * @description Test class for ApplicationExceptionTriggerHandler
 * @author Claude
 * @date 2025-11-27
 */
@isTest
private class ApplicationExceptionTriggerHandlerTest {

    /**
     * @description Mock HTTP callout for testing
     */
    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true, "incidentId": "INC-12345"}');
            res.setStatusCode(201);
            return res;
        }
    }

    /**
     * @description Test trigger fires on Application Exception insert
     */
    @isTest
    static void testTriggerOnInsert() {
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        // Create Application Exception - this should trigger the callout
        Application_Exception__c appException = new Application_Exception__c(
            Message__c = 'TypeError: Cannot read property value of null',
            Type__c = 'System.NullPointerException',
            Context__c = 'TestClass.testMethod',
            Line_Number__c = 25,
            Stack_Trace__c = 'Class.TestClass.testMethod: line 25, column 1'
        );
        insert appException;
        Test.stopTest();

        // Verify the record was created
        Application_Exception__c insertedRecord = [
            SELECT Id, Message__c, Type__c, Context__c
            FROM Application_Exception__c
            WHERE Id = :appException.Id
        ];

        System.assertNotEquals(null, insertedRecord,
            'Application Exception should be inserted');
        System.assertEquals('TypeError: Cannot read property value of null',
            insertedRecord.Message__c, 'Message should match');
    }

    /**
     * @description Test bulk insert of Application Exceptions
     */
    @isTest
    static void testBulkInsert() {
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        // Create multiple Application Exception records
        List<Application_Exception__c> exceptions = new List<Application_Exception__c>();
        for (Integer i = 0; i < 5; i++) {
            exceptions.add(new Application_Exception__c(
                Message__c = 'Error message ' + i,
                Type__c = 'System.Exception',
                Context__c = 'BulkTest.method' + i
            ));
        }

        Test.startTest();
        insert exceptions;
        Test.stopTest();

        // Verify all records were created
        List<Application_Exception__c> insertedRecords = [
            SELECT Id, Message__c
            FROM Application_Exception__c
            WHERE Id IN :exceptions
        ];

        System.assertEquals(5, insertedRecords.size(),
            'All 5 Application Exceptions should be inserted');
    }

    /**
     * @description Test with Application Exception that has no message
     */
    @isTest
    static void testInsertWithNoMessage() {
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        // Create Application Exception without message
        Application_Exception__c appException = new Application_Exception__c(
            Type__c = 'System.NullPointerException',
            Context__c = 'TestClass.testMethod'
        );
        insert appException;
        Test.stopTest();

        // Verify the record was created (but no API call should be made)
        Application_Exception__c insertedRecord = [
            SELECT Id, Message__c
            FROM Application_Exception__c
            WHERE Id = :appException.Id
        ];

        System.assertNotEquals(null, insertedRecord,
            'Application Exception should be inserted');
        System.assertEquals(null, insertedRecord.Message__c,
            'Message should be null');
    }

    /**
     * @description Test handler with null list
     */
    @isTest
    static void testHandlerWithNullList() {
        Test.startTest();
        ApplicationExceptionTriggerHandler.handleAfterInsert(null);
        Test.stopTest();

        // Should complete without errors
        System.assert(true, 'Null list handled gracefully');
    }

    /**
     * @description Test handler with empty list
     */
    @isTest
    static void testHandlerWithEmptyList() {
        Test.startTest();
        ApplicationExceptionTriggerHandler.handleAfterInsert(
            new List<Application_Exception__c>()
        );
        Test.stopTest();

        // Should complete without errors
        System.assert(true, 'Empty list handled gracefully');
    }

    /**
     * @description Test integration - trigger to handler to API callout
     */
    @isTest
    static void testFullIntegration() {
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        // Create realistic Application Exception
        Application_Exception__c appException = new Application_Exception__c(
            Message__c = 'System.NullPointerException: Attempt to de-reference a null object',
            Type__c = 'System.NullPointerException',
            Context__c = 'AccountTriggerHandler.handleTrigger',
            Line_Number__c = 16,
            Stack_Trace__c = 'Class.AccountTriggerHandler.handleTrigger: line 16, column 1\nTrigger.AccountTrigger: line 2, column 1',
            Cause_Type__c = 'System.NullPointerException',
            Cause_Message__c = 'Attempt to de-reference a null object'
        );
        insert appException;
        Test.stopTest();

        // Verify complete flow executed without errors
        Application_Exception__c result = [
            SELECT Id, Message__c, Type__c, Context__c, Line_Number__c
            FROM Application_Exception__c
            WHERE Id = :appException.Id
        ];

        System.assertNotEquals(null, result, 'Record should exist');
        System.assertEquals(16, result.Line_Number__c, 'Line number should match');
    }
}
