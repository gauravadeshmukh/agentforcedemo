@isTest
public class ExceptionHandlerTest {
    
    @isTest
    static void testHandleWithSimpleException() {
        try {
            // Force a simple exception
            Integer x = 1/0;
        } catch (Exception e) {
            Test.startTest();
            ExceptionHandler.handle(e, 'testHandleWithSimpleException');
            Test.stopTest();
        }
        
        // Verify that no exception was thrown
        System.assert(true, 'ExceptionHandler should handle simple exceptions without throwing');
    }
    
    @isTest
    static void testHandleWithRethrow() {
        try {
            // Force a simple exception
            Integer x = 1/0;
        } catch (Exception e) {
            Test.startTest();
            ExceptionHandler.handle(e, 'testHandleWithRethrow', null, true);
            Test.stopTest();
        }
        
        // This should not be reached as an exception should be thrown
        System.assert(false, 'ExceptionHandler should have rethrown an exception when rethrow=true');
    }
    
    @isTest
    static void testBuildMessage() {
        Exception e = new CustomException('Test message');
        String message = ExceptionHandler.buildMessage(e, 'testContext');
        
        // Verify the message contains expected elements
        System.assert(message.contains('An unexpected error occurred'), 'Message should contain base error text');
        System.assert(message.contains('testContext'), 'Message should contain context');
        System.assert(message.contains('Test message'), 'Message should contain original exception message');
    }
    
    @isTest
    static void testBuildDetail() {
        Exception e = new CustomException('Test detail message');
        String detail = ExceptionHandler.buildDetail(e, 'testContext');
        
        // Verify the detail contains expected elements
        System.assert(detail.contains('EXC|'), 'Detail should start with EXC marker');
        System.assert(detail.contains('context=testContext'), 'Detail should contain context');
        System.assert(detail.contains('type=CustomException'), 'Detail should contain exception type');
        System.assert(detail.contains('message=Test detail message'), 'Detail should contain exception message');
    }
    
    @isTest
    static void testLog() {
        Exception e = new CustomException('Log test message');
        Test.startTest();
        ExceptionHandler.log(e, 'testLogContext');
        Test.stopTest();
        
        // Verify that no exception was thrown during logging
        System.assert(true, 'ExceptionHandler.log should not throw exceptions');
    }
    
    // Custom exception class for testing
    public class CustomException extends Exception {}
}
