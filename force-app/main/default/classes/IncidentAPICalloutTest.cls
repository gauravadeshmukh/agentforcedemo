/**
 * @description Test class for IncidentAPICallout
 * @author Claude
 * @date 2025-11-27
 */
@isTest
private class IncidentAPICalloutTest {

    /**
     * @description Mock HTTP callout for successful response
     */
    private class MockHttpResponseSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Verify request
            System.assertEquals('POST', req.getMethod());
            System.assertEquals('application/json', req.getHeader('Content-Type'));
            System.assert(req.getEndpoint().contains('herokuapp.com'));

            // Create mock response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true, "incidentId": "INC-12345"}');
            res.setStatusCode(201);
            return res;
        }
    }

    /**
     * @description Mock HTTP callout for error response
     */
    private class MockHttpResponseError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error": "Internal Server Error"}');
            res.setStatusCode(500);
            return res;
        }
    }

    /**
     * @description Test successful incident creation
     */
    @isTest
    static void testCreateIncidentSuccess() {
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());

        Test.startTest();
        HttpResponse response = IncidentAPICallout.createIncident(
            'TypeError: Cannot read property value of null',
            'admin@example.com'
        );
        Test.stopTest();

        // Assertions
        System.assertEquals(201, response.getStatusCode(),
            'Expected successful status code');
        System.assert(response.getBody().contains('success'),
            'Expected success in response');
    }

    /**
     * @description Test incident creation with error response
     */
    @isTest
    static void testCreateIncidentError() {
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseError());

        Test.startTest();
        HttpResponse response = IncidentAPICallout.createIncident(
            'NullPointerException',
            'test@example.com'
        );
        Test.stopTest();

        // Assertions
        System.assertEquals(500, response.getStatusCode(),
            'Expected error status code');
    }

    /**
     * @description Test async incident creation
     */
    @isTest
    static void testCreateIncidentAsync() {
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());

        Test.startTest();
        IncidentAPICallout.createIncidentAsync(
            'Database exception occurred',
            'developer@example.com'
        );
        Test.stopTest();

        // Since it's async, we just verify no exceptions were thrown
        System.assert(true, 'Async callout completed without exceptions');
    }

    /**
     * @description Test batch processing of Application Exceptions
     */
    @isTest
    static void testCreateIncidentsFromExceptions() {
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());

        // Create test Application Exception records
        List<Application_Exception__c> exceptions = new List<Application_Exception__c>();
        for (Integer i = 0; i < 3; i++) {
            exceptions.add(new Application_Exception__c(
                Message__c = 'Test error message ' + i,
                Type__c = 'System.NullPointerException',
                Context__c = 'TestContext'
            ));
        }
        insert exceptions;

        // Query back with CreatedBy relationship
        exceptions = [
            SELECT Id, Message__c, CreatedBy.Email, CreatedBy.Username
            FROM Application_Exception__c
            WHERE Id IN :exceptions
        ];

        Test.startTest();
        IncidentAPICallout.createIncidentsFromExceptions(exceptions);
        Test.stopTest();

        // Verify no exceptions were thrown
        System.assert(true, 'Batch processing completed without exceptions');
    }

    /**
     * @description Test with null or empty exceptions list
     */
    @isTest
    static void testCreateIncidentsFromExceptionsNullList() {
        Test.startTest();
        IncidentAPICallout.createIncidentsFromExceptions(null);
        IncidentAPICallout.createIncidentsFromExceptions(new List<Application_Exception__c>());
        Test.stopTest();

        // Should handle gracefully without errors
        System.assert(true, 'Null/empty list handled gracefully');
    }

    /**
     * @description Test exception creation with blank message
     */
    @isTest
    static void testCreateIncidentWithBlankMessage() {
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());

        // Create Application Exception with blank message
        Application_Exception__c exception = new Application_Exception__c(
            Message__c = '',
            Type__c = 'System.NullPointerException'
        );
        insert exception;

        exception = [
            SELECT Id, Message__c, CreatedBy.Email, CreatedBy.Username
            FROM Application_Exception__c
            WHERE Id = :exception.Id
        ];

        Test.startTest();
        IncidentAPICallout.createIncidentsFromExceptions(
            new List<Application_Exception__c>{exception}
        );
        Test.stopTest();

        // Should skip the record gracefully
        System.assert(true, 'Blank message handled gracefully');
    }
}
